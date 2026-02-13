#!/usr/bin/env bash
# get-git-repos-for.sh - clone or update all GitHub repos for a given user
#
# Minimal dependencies: bash, git, curl, jq

VERSION="0.1.0"

usage() {
  cat <<USAGE
Usage: $(basename "$0") [options] <github-username>

Run $(basename "$0") --help for full details
USAGE
}

help() {
  cat <<USAGE
Usage: $(basename "$0") [options] <github-username>

Options:
  -h, --help             Show help and exit
  --version              Print version and exit
  -v                     Increase verbosity (can be used multiple times)
  --use-https            Use HTTPS clone URLs instead of SSH
  -d DIR, --dest DIR,
  --dest-dir DIR         Destination base directory for all repositories (default: current directory)

Environment:
  GITHUB_TOKEN           Optional GitHub token to increase rate limits and access private repos

Examples:
  $(basename "$0") octocat
  $(basename "$0") --use-https -v octocat
USAGE
}

VERBOSE=0
USE_HTTPS=0
DEST_DIR="."

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
      help
      exit 0
      ;;
    --version)
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
    --dest|--dest-dir)
      shift
      if [[ -z "$1" || "${1:0:1}" == "-" ]]; then
        echo "Error: --dest requires a directory argument" >&2
        usage
        exit 2
      fi
      DEST_DIR="$1"
      shift
      ;;
    --dest=*|--dest-dir=*)
      DEST_DIR="${1#*=}"
      shift
      ;;
    --use-https)
      USE_HTTPS=1
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

if ! mkdir -p "$DEST_DIR/$USERNAME"; then
  echo "Failed to create destination directory: $DEST_DIR/$USERNAME" >&2
  exit 8
fi
logv "Destination base directory: $DEST_DIR"

tmpfile=""
tmpfile=$(mktemp) || { echo "failed to create temp file" >&2; exit 4; }
trap 'rm -f "$tmpfile"' EXIT

auth_header=()
if [[ -n "${GITHUB_TOKEN:-}" ]]; then
  auth_header=( -H "Authorization: token ${GITHUB_TOKEN}" )
  logv "Using GITHUB_TOKEN for authenticated API requests"
fi

# Fetch repositories, paginated
while :; do
  url="$API/users/$USERNAME/repos?per_page=$PER_PAGE&page=$page"
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

  repo_dir="$DEST_DIR/$USERNAME/$name"
  if [[ "$USE_HTTPS" -eq 1 ]]; then
    url="$clone_url"
  else
    url="$ssh_url"
  fi

  log "Processing: $name"
  if [[ ! -d "$repo_dir" ]]; then
    logv "Cloning $name into $repo_dir"
    if git clone "$url" "$repo_dir"; then
      log "Cloned $name"
      # Handle submodules. When using HTTPS, rewrite submodule URLs that use SSH (git@) or git://
      if [[ -f "$repo_dir/.gitmodules" ]]; then
        logv "Repository has submodules; initializing"
        if [[ "$USE_HTTPS" -eq 1 ]]; then
          logv "Converting submodule URLs to HTTPS where necessary"
          # Iterate submodule.url keys from the .gitmodules file
          while IFS= read -r cfg; do
            key=$(printf '%s' "$cfg" | awk '{print $1}')
            val=$(printf '%s' "$cfg" | awk '{print $2}')
            # Convert common SSH/git URL forms to HTTPS
            newval=$(printf '%s' "$val" | sed -E 's#^git@github.com:(.+)$#https://github.com/\1#; s#^git://github.com/(.+)$#https://github.com/\1#')
            if [[ "$newval" != "$val" ]]; then
              logv "Updating submodule URL: $val -> $newval"
              git -C "$repo_dir" config -f "$repo_dir/.gitmodules" "$key" "$newval" || true
            fi
          done < <(git -C "$repo_dir" config -f "$repo_dir/.gitmodules" --get-regexp '^submodule\..*\.url$' 2>/dev/null || true)
          # Synchronize and update submodules
          git -C "$repo_dir" submodule sync --recursive || true
        fi
        if ! git -C "$repo_dir" submodule update --init --recursive; then
          echo "Warning: submodule update failed for $name; some submodules may not have been cloned." >&2
        fi
      fi
    else
      echo "Failed to clone $name ($url), skipping." >&2
      continue
    fi
  else
    # Update existing repository
    if git -C "$repo_dir" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
      logv "Fetching updates for $name"
      if ! git -C "$repo_dir" fetch --prune --tags; then
        echo "Failed to fetch for $name, continuing." >&2
        continue
      fi

      # Only attempt pull if working tree is clean and we're on a branch
      if [[ -z "$(git -C "$repo_dir" status --porcelain)" ]]; then
        branch=$(git -C "$repo_dir" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")
        if [[ -n "$branch" && "$branch" != "HEAD" ]]; then
          if git -C "$repo_dir" pull --ff-only; then
            log "Updated $name (branch: $branch)"
          else
            logv "Could not fast-forward $name (branch: $branch); manual intervention may be required."
          fi
        else
          logv "$name is in detached HEAD or has no branch; skipping pull."
        fi
      else
        logv "Local changes present in $name; skipping pull to avoid overwriting local work."
      fi
    else
      echo "Path $repo_dir exists but is not a git repository; skipping." >&2
      continue
    fi
  fi
done < "$tmpfile"

exit 0
