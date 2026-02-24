#!/usr/bin/env bash
# sync-github-repos.sh - clone or update all GitHub repos for a given user
#
# Minimal dependencies: bash, git, curl, jq

VERSION="3.0.0"

usage() {
  cat <<USAGE
Usage: $(basename "$0") [-d DIR] [--use-https] [-v] <github-username>

Run $(basename "$0") --help for full details
USAGE
}

help() {
  cat <<USAGE
  Usage: $(basename "$0") [options] <github-username>

Options:
  -h, --help             Show help and exit
  -V, --version          Print version and exit
  -v                     Increase verbosity (can be used multiple times)
  --use-https            Use HTTPS clone URLs instead of SSH
  --submodules, -s       Enable submodule initialization/updates (default: OFF)
  -d DIR, --dest DIR     Destination base directory for all repositories (default: current directory)

Environment:
  GITHUB_TOKEN           Optional GitHub token to increase rate limits and access private repos

Examples:
  $(basename "$0") octocat
  $(basename "$0") --use-https -v octocat
  $(basename "$0") --submodules -v octocat
USAGE
}

VERBOSE=0
USE_HTTPS=0
NO_SUBMODULES=1
DEST_DIR="."

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
      help
      exit 0
      ;;
    -V|--version)
      echo "$(basename "$0") $VERSION"
      exit 0
      ;;
    -v)
      VERBOSE=$((VERBOSE+1))
      shift
      ;;
    -d)
      shift
      if [[ -z "$1" || "${1:0:1}" == "-" ]]; then
        echo "Error: -d requires a directory argument" >&2
        usage
        exit 2
      fi
      DEST_DIR="$1"
      shift
      ;;
    --dest)
      shift
      if [[ -z "$1" || "${1:0:1}" == "-" ]]; then
        echo "Error: --dest requires a directory argument" >&2
        usage
        exit 2
      fi
      DEST_DIR="$1"
      shift
      ;;
    --dest=*)
      DEST_DIR="${1#*=}"
      shift
      ;;
    --use-https)
      USE_HTTPS=1
      shift
      ;;
    --submodules|-s)
      NO_SUBMODULES=0
      shift
      ;;
    --)
      shift
      break
      ;;
    -*)
      echo "Unknown option: $1" >&2
      usage
      exit 2
      ;;
    *)
      break
      ;;
  esac
done

if [[ $# -lt 1 ]]; then
  echo "Error: missing GitHub username" >&2
  usage
  exit 2
fi

USERNAME="$1"

# Check dependencies
missing=()
for cmd in git curl jq mktemp; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    missing+=("$cmd")
  fi
done
if (( ${#missing[@]} )); then
  echo "Missing required commands: ${missing[*]}. Please install them and retry." >&2
  exit 3
fi

log() { echo "$*"; }
logv() { if (( VERBOSE > 0 )); then echo "$*"; fi }
logvv() { if (( VERBOSE > 1 )); then echo "$*"; fi }

API="https://api.github.com"
PER_PAGE=100
page=1

if ! mkdir -p "$DEST_DIR"; then
  echo "Failed to create destination directory: $DEST_DIR" >&2
  exit 8
fi
# Normalize destination path (expand ~ and make absolute)
if [[ "$DEST_DIR" == ~* ]]; then
  DEST_DIR="${DEST_DIR/#\~/$HOME}"
fi
if command -v realpath >/dev/null 2>&1; then
  DEST_DIR=$(realpath "$DEST_DIR")
else
  # fallback: change directory and print pwd
  DEST_DIR=$(cd "$DEST_DIR" && pwd)
fi
logv "Destination base directory: $DEST_DIR"

tmpfile=""
tmpfile=$(mktemp) || { echo "failed to create temp file" >&2; exit 4; }
trap 'rm -f "$tmpfile"' EXIT

# Counters for summary reporting
TOTAL=0
CLONED=0
UPDATED=0
SKIPPED_LOCAL=0
FAILED=0
SUBMODULE_WARN=0
declare -a FAILED_LIST

auth_header=()
if [[ -n "${GITHUB_TOKEN:-}" ]]; then
  auth_header=( -H "Authorization: token ${GITHUB_TOKEN}" )
  logv "Using GITHUB_TOKEN for authenticated API requests"
fi

# Build git command prefix. When using HTTPS and a GITHUB_TOKEN is present,
# pass the token to git via `-c http.extraHeader=Authorization: token ...`
# This allows authenticated HTTPS clones/fetches without embedding the token
# in remote URLs.
git_cmd=(git)
if [[ "$USE_HTTPS" -eq 1 && -n "${GITHUB_TOKEN:-}" ]]; then
  # Prefer Basic auth for git over HTTPS: Authorization: Basic <base64(x-access-token:TOKEN)>
  if command -v base64 >/dev/null 2>&1; then
    auth_b64=$(printf 'x-access-token:%s' "$GITHUB_TOKEN" | base64 | tr -d '\n')
  elif command -v python3 >/dev/null 2>&1; then
    auth_b64=$(python3 -c "import base64,sys;print(base64.b64encode(b'x-access-token:'+sys.argv[1].encode()).decode())" "$GITHUB_TOKEN")
  elif command -v openssl >/dev/null 2>&1; then
    auth_b64=$(printf 'x-access-token:%s' "$GITHUB_TOKEN" | openssl base64 -A)
  else
    echo "Warning: cannot encode auth header (no base64/python3/openssl found); HTTPS auth will not be available" >&2
    auth_b64=""
  fi
  if [[ -n "$auth_b64" ]]; then
    git_cmd=(git -c "http.extraHeader=Authorization: Basic $auth_b64")
    logv "git commands will include HTTP Basic Authorization header for HTTPS operations"
  else
    logv "git commands will run without extra HTTP Authorization header"
  fi
fi

# Determine API endpoint. When authenticated and the token belongs to the same
# username we can use /user/repos to include private repositories and org repos
# by adding visibility and affiliation parameters. Ensure query parameters are
# appended using & when needed.
api_url="$API/users/$USERNAME/repos"
if [[ -n "${GITHUB_TOKEN:-}" ]]; then
  # discover authenticated username
  me=$(curl -sS -H "Authorization: token ${GITHUB_TOKEN}" "$API/user" | jq -r '.login // empty' 2>/dev/null || true)
  if [[ "$me" == "$USERNAME" ]]; then
    api_url="$API/user/repos?visibility=all&affiliation=owner,collaborator,organization_member"
  fi
fi

# Fetch repositories, paginated
while :; do
  # Append pagination params correctly depending on whether api_url already has ?
  if [[ "$api_url" == *\?* ]]; then
    url="$api_url&per_page=$PER_PAGE&page=$page"
  else
    url="$api_url?per_page=$PER_PAGE&page=$page"
  fi
  logv "Fetching $url"
  if ! resp=$(curl -sS "${auth_header[@]}" "$url"); then
    echo "Failed to fetch $url" >&2
    exit 5
  fi

  # Ensure response is an array
  len=$(printf '%s' "$resp" | jq -r 'if type=="array" then length else -1 end' 2>/dev/null || echo -1)
  if [[ -z "$len" || "$len" -lt 0 ]]; then
    msg=$(printf '%s' "$resp" | jq -r '.message // empty' 2>/dev/null || true)
    if [[ -n "$msg" ]]; then
      echo "GitHub API error: $msg" >&2
      exit 6
    fi
    echo "Unexpected response from GitHub API" >&2
    exit 7
  fi

  if [[ "$len" -eq 0 ]]; then
    logv "No more repositories (page $page)."
    break
  fi

  # Save repo summaries to tempfile (one JSON object per line)
  printf '%s' "$resp" | jq -c '.[] | {name: .name, ssh_url: .ssh_url, clone_url: .clone_url, private: .private}' >> "$tmpfile"
  page=$((page+1))
done

# Process each repository
while IFS= read -r line || [[ -n "$line" ]]; do
  name=$(printf '%s' "$line" | jq -r '.name')
  ssh_url=$(printf '%s' "$line" | jq -r '.ssh_url')
  clone_url=$(printf '%s' "$line" | jq -r '.clone_url')

  repo_dir="$DEST_DIR/$name"
  if [[ "$USE_HTTPS" -eq 1 ]]; then
    url="$clone_url"
  else
    url="$ssh_url"
  fi

  TOTAL=$((TOTAL+1))
  log "Processing: $name"
  if [[ ! -d "$repo_dir" ]]; then
    logv "Cloning $name into $repo_dir"
    if "${git_cmd[@]}" clone "$url" "$repo_dir"; then
      log "Cloned $name"
      CLONED=$((CLONED+1))
      # Handle submodules. When using HTTPS, rewrite submodule URLs that use SSH (git@) or git://
  if [[ $NO_SUBMODULES -eq 0 && -f "$repo_dir/.gitmodules" ]]; then
        logv "Repository has submodules; initializing"
        if [[ "$USE_HTTPS" -eq 1 ]]; then
          logv "Converting submodule URLs to HTTPS where necessary"
          if grep -qE 'git@github.com:|git://github.com/' "$repo_dir/.gitmodules" 2>/dev/null; then
            cp "$repo_dir/.gitmodules" "$repo_dir/.gitmodules.bak" 2>/dev/null || true
            sed -E -i 's#git@github.com:([^[:space:]]+)#https://github.com/\1#g; s#git://github.com/([^[:space:]]+)#https://github.com/\1#g' "$repo_dir/.gitmodules" || true
            logv "Rewrote $repo_dir/.gitmodules to use HTTPS (backup at .gitmodules.bak)"
            # Sync .git/config submodule entries so subsequent operations use rewritten URLs
            "${git_cmd[@]}" -C "$repo_dir" submodule sync --recursive || true
            # Also update .git/config entries from .gitmodules where possible
            if command -v git >/dev/null 2>&1; then
              while read -r key value; do
                # key is like "submodule.<name>.url"
                if [[ -n "$key" && -n "$value" ]]; then
                  # set the config to the new URL
                  "${git_cmd[@]}" -C "$repo_dir" config "$key" "$value" || true
                fi
              done < <("git" -C "$repo_dir" config -f .gitmodules --get-regexp '^submodule\..*\.url$' 2>/dev/null | awk '{print $1" "$2}')
            fi
          else
            logv "No SSH/git:// submodule URLs detected in .gitmodules"
          fi
        fi
        if ! "${git_cmd[@]}" -C "$repo_dir" submodule update --init --recursive; then
          echo "Warning: submodule update failed for $name; some submodules may not have been cloned." >&2
          SUBMODULE_WARN=$((SUBMODULE_WARN+1))
          FAILED_LIST+=("$name: submodule update failed")
        fi
      fi
    else
      echo "Failed to clone $name ($url), skipping." >&2
      FAILED=$((FAILED+1))
      FAILED_LIST+=("$name: clone failed ($url)")
      continue
    fi
  else
    # Update existing repository
    if git -C "$repo_dir" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
      logv "Fetching updates for $name"
      if ! "${git_cmd[@]}" -C "$repo_dir" fetch --prune --tags; then
        echo "Failed to fetch for $name, continuing." >&2
        FAILED=$((FAILED+1))
        FAILED_LIST+=("$name: fetch failed")
        continue
      fi

      # Only attempt pull if working tree is clean and we're on a branch
      if [[ -z "$(git -C "$repo_dir" status --porcelain)" ]]; then
        branch=$(git -C "$repo_dir" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")
        if [[ -n "$branch" && "$branch" != "HEAD" ]]; then
            if "${git_cmd[@]}" -C "$repo_dir" pull --ff-only; then
              log "Updated $name (branch: $branch)"
              UPDATED=$((UPDATED+1))
            else
              logv "Could not fast-forward $name (branch: $branch); manual intervention may be required."
            fi
        else
          logv "$name is in detached HEAD or has no branch; skipping pull."
        fi
        else
        logv "Local changes present in $name; skipping pull to avoid overwriting local work."
        SKIPPED_LOCAL=$((SKIPPED_LOCAL+1))
      fi
      else
        echo "Path $repo_dir exists but is not a git repository; skipping." >&2
        FAILED=$((FAILED+1))
        FAILED_LIST+=("$name: path exists but not a git repository")
        continue
      fi
  fi
done < "$tmpfile"

# Print summary
echo
echo "Summary for $USERNAME -> $DEST_DIR"
echo "  Total repositories discovered: $TOTAL"
echo "  Cloned: $CLONED"
echo "  Updated (fast-forward): $UPDATED"
echo "  Skipped (local changes): $SKIPPED_LOCAL"
echo "  Submodule warnings: $SUBMODULE_WARN"
echo "  Failed operations: $FAILED"
if (( ${#FAILED_LIST[@]} > 0 )); then
  echo
  echo "Failures / warnings:" >&2
  for f in "${FAILED_LIST[@]}"; do
    echo "  - $f" >&2
  done
fi

exit 0
