#!/usr/bin/env bash
# sync-github-repos.sh - clone or update all GitHub repos for a given user
#
# Minimal dependencies: bash, git, curl, jq

set -euo pipefail

VERSION="3.0.3"

SCRIPT_NAME="$(basename "$0")"

# ---------------------------------------------------------------------------
# Usage / help
# ---------------------------------------------------------------------------

usage() {
	echo "Usage: $SCRIPT_NAME [-d DIR] [--use-https] [-v] <github-username>"
	echo "Run $SCRIPT_NAME --help for full details"
}

help() {
	cat <<EOF
Usage: $SCRIPT_NAME [options] <github-username>

Options:
  -h, --help             Show help and exit
  -V, --version          Print version and exit
  -v                     Increase verbosity (can be used multiple times)
  --use-https            Use HTTPS clone URLs instead of SSH
  --submodules, -s       Enable submodule initialization/updates (default: OFF)
  -d DIR, --dest DIR     Destination base directory (default: current directory)

Environment:
  GITHUB_TOKEN           Optional token to increase rate limits and access private repos

Examples:
  $SCRIPT_NAME octocat
  $SCRIPT_NAME --use-https -v octocat
  $SCRIPT_NAME --submodules -v octocat
EOF
}

# ---------------------------------------------------------------------------
# Defaults
# ---------------------------------------------------------------------------

VERBOSE=0
USE_HTTPS=0
NO_SUBMODULES=1
DEST_DIR="."

# ---------------------------------------------------------------------------
# Argument parsing
# ---------------------------------------------------------------------------

while [[ $# -gt 0 ]]; do
	case "$1" in
	-h | --help)
		help
		exit 0
		;;
	-V | --version)
		echo "$SCRIPT_NAME $VERSION"
		exit 0
		;;
	-v)
		((VERBOSE++)) || true
		shift
		;;
	-d | --dest)
		shift
		if [[ -z "${1:-}" || "${1:0:1}" == "-" ]]; then
			echo "Error: -d/--dest requires a directory argument" >&2
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
	--submodules | -s)
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

# ---------------------------------------------------------------------------
# Dependency check
# ---------------------------------------------------------------------------

missing=()
for cmd in git curl jq mktemp; do
	command -v "$cmd" >/dev/null 2>&1 || missing+=("$cmd")
done
if ((${#missing[@]})); then
	echo "Missing required commands: ${missing[*]}. Please install them and retry." >&2
	exit 3
fi

# ---------------------------------------------------------------------------
# Logging helpers
# ---------------------------------------------------------------------------

log() { echo "$*"; }
logv() { ((VERBOSE > 0)) && echo "$*" || true; }
logvv() { ((VERBOSE > 1)) && echo "$*" || true; }

# ---------------------------------------------------------------------------
# Destination directory setup
# ---------------------------------------------------------------------------

if ! mkdir -p "$DEST_DIR"; then
	echo "Failed to create destination directory: $DEST_DIR" >&2
	exit 8
fi

# Normalize to an absolute path (expand ~ and resolve symlinks where possible)
if [[ "$DEST_DIR" == ~* ]]; then
	DEST_DIR="${DEST_DIR/#\~/$HOME}"
fi
if command -v realpath >/dev/null 2>&1; then
	DEST_DIR="$(realpath "$DEST_DIR")"
else
	DEST_DIR="$(cd "$DEST_DIR" && pwd)"
fi
logv "Destination base directory: $DEST_DIR"

# ---------------------------------------------------------------------------
# Temporary file (cleaned up on exit)
# ---------------------------------------------------------------------------

tmpfile="$(mktemp)" || {
	echo "Failed to create temp file" >&2
	exit 4
}
trap 'rm -f "$tmpfile"' EXIT

# ---------------------------------------------------------------------------
# Counters
# ---------------------------------------------------------------------------

TOTAL=0
CLONED=0
UPDATED=0
SKIPPED_LOCAL=0
FAILED=0
SUBMODULE_WARN=0
FAILED_LIST=()

# ---------------------------------------------------------------------------
# Authentication
# ---------------------------------------------------------------------------

auth_header=()
if [[ -n "${GITHUB_TOKEN:-}" ]]; then
	auth_header=(-H "Authorization: token ${GITHUB_TOKEN}")
	logv "Using GITHUB_TOKEN for authenticated API requests"
fi

# Build git command prefix.
# For HTTPS + token, inject an Authorization: Basic header so credentials are
# never embedded in remote URLs.
git_cmd=(git)
if [[ "$USE_HTTPS" -eq 1 && -n "${GITHUB_TOKEN:-}" ]]; then
	auth_b64=""
	if command -v base64 >/dev/null 2>&1; then
		auth_b64="$(printf 'x-access-token:%s' "$GITHUB_TOKEN" | base64 | tr -d '\n')"
	elif command -v python3 >/dev/null 2>&1; then
		auth_b64="$(python3 -c \
			"import base64,sys; print(base64.b64encode(b'x-access-token:'+sys.argv[1].encode()).decode())" \
			"$GITHUB_TOKEN")"
	elif command -v openssl >/dev/null 2>&1; then
		auth_b64="$(printf 'x-access-token:%s' "$GITHUB_TOKEN" | openssl base64 -A)"
	else
		echo "Warning: cannot encode auth header (no base64/python3/openssl found); HTTPS auth unavailable" >&2
	fi

	if [[ -n "$auth_b64" ]]; then
		git_cmd=(git -c "http.extraHeader=Authorization: Basic $auth_b64")
		logv "git will include HTTP Basic Authorization header for HTTPS operations"
	else
		logv "git will run without extra HTTP Authorization header"
	fi
fi

# ---------------------------------------------------------------------------
# API endpoint selection
# ---------------------------------------------------------------------------

API="https://api.github.com"
PER_PAGE=100

api_url="$API/users/$USERNAME/repos"
if [[ -n "${GITHUB_TOKEN:-}" ]]; then
	me="$(curl -sS -H "Authorization: token ${GITHUB_TOKEN}" "$API/user" |
		jq -r '.login // empty' 2>/dev/null || true)"
	if [[ "$me" == "$USERNAME" ]]; then
		api_url="$API/user/repos?visibility=all&affiliation=owner,collaborator,organization_member"
		logv "Authenticated as $USERNAME; using /user/repos endpoint"
	fi
fi

# ---------------------------------------------------------------------------
# Fetch repository list (paginated)
# ---------------------------------------------------------------------------

page=1
while :; do
	if [[ "$api_url" == *\?* ]]; then
		url="$api_url&per_page=$PER_PAGE&page=$page"
	else
		url="$api_url?per_page=$PER_PAGE&page=$page"
	fi
	logv "Fetching $url"

	resp="$(curl -sS "${auth_header[@]}" "$url")" ||
		{
			echo "Failed to fetch $url" >&2
			exit 5
		}

	len="$(jq -r 'if type=="array" then length else -1 end' <<<"$resp" 2>/dev/null || echo -1)"
	if [[ -z "$len" || "$len" -lt 0 ]]; then
		msg="$(jq -r '.message // empty' <<<"$resp" 2>/dev/null || true)"
		[[ -n "$msg" ]] && {
			echo "GitHub API error: $msg" >&2
			exit 6
		}
		echo "Unexpected response from GitHub API" >&2
		exit 7
	fi

	if [[ "$len" -eq 0 ]]; then
		logv "No more repositories (page $page)."
		break
	fi

	jq -c '.[] | {name: .name, ssh_url: .ssh_url, clone_url: .clone_url, private: .private}' \
		<<<"$resp" >>"$tmpfile"
	((page++)) || true
done

# ---------------------------------------------------------------------------
# Process each repository
# ---------------------------------------------------------------------------

process_submodules() {
	local repo_dir="$1" name="$2"

	[[ -f "$repo_dir/.gitmodules" ]] || return 0

	logv "Repository has submodules; initializing"

	if [[ "$USE_HTTPS" -eq 1 ]]; then
		logv "Converting submodule URLs to HTTPS where necessary"
		if grep -qE 'git@github\.com:|git://github\.com/' "$repo_dir/.gitmodules" 2>/dev/null; then
			cp "$repo_dir/.gitmodules" "$repo_dir/.gitmodules.bak" 2>/dev/null || true
			sed -E -i \
				's#git@github\.com:([^[:space:]]+)#https://github.com/\1#g
         s#git://github\.com/([^[:space:]]+)#https://github.com/\1#g' \
				"$repo_dir/.gitmodules" || true
			logv "Rewrote $repo_dir/.gitmodules to use HTTPS (backup: .gitmodules.bak)"
			"${git_cmd[@]}" -C "$repo_dir" submodule sync --recursive || true
			while read -r key value; do
				[[ -n "$key" && -n "$value" ]] &&
					"${git_cmd[@]}" -C "$repo_dir" config "$key" "$value" || true
			done < <(
				"${git_cmd[@]}" -C "$repo_dir" config -f .gitmodules \
					--get-regexp '^submodule\..*\.url$' 2>/dev/null | awk '{print $1" "$2}'
			)
		else
			logv "No SSH/git:// submodule URLs detected in .gitmodules"
		fi
	fi

	if ! "${git_cmd[@]}" -C "$repo_dir" submodule update --init --recursive; then
		echo "Warning: submodule update failed for $name; some submodules may not have been cloned." >&2
		((SUBMODULE_WARN++)) || true
		FAILED_LIST+=("$name: submodule update failed")
	fi
}

while IFS= read -r line || [[ -n "$line" ]]; do
	name="$(jq -r '.name' <<<"$line")"
	ssh_url="$(jq -r '.ssh_url' <<<"$line")"
	clone_url="$(jq -r '.clone_url' <<<"$line")"
	repo_dir="$DEST_DIR/$name"
	url="$([[ "$USE_HTTPS" -eq 1 ]] && echo "$clone_url" || echo "$ssh_url")"

	((TOTAL++)) || true
	log "Processing: $name"

	if [[ ! -d "$repo_dir" ]]; then
		logv "Cloning $name into $repo_dir"
		if "${git_cmd[@]}" clone "$url" "$repo_dir"; then
			log "Cloned $name"
			((CLONED++)) || true
			((NO_SUBMODULES == 0)) && process_submodules "$repo_dir" "$name"
		else
			echo "Failed to clone $name ($url), skipping." >&2
			((FAILED++)) || true
			FAILED_LIST+=("$name: clone failed ($url)")
		fi
	else
		if ! git -C "$repo_dir" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
			echo "Path $repo_dir exists but is not a git repository; skipping." >&2
			((FAILED++)) || true
			FAILED_LIST+=("$name: path exists but not a git repository")
			continue
		fi

		logv "Fetching updates for $name"
		if ! "${git_cmd[@]}" -C "$repo_dir" fetch --prune --tags; then
			echo "Failed to fetch for $name, continuing." >&2
			((FAILED++)) || true
			FAILED_LIST+=("$name: fetch failed")
			continue
		fi

		if [[ -n "$(git -C "$repo_dir" status --porcelain)" ]]; then
			logv "Local changes present in $name; skipping pull to avoid overwriting local work."
			((SKIPPED_LOCAL++)) || true
			continue
		fi

		branch="$(git -C "$repo_dir" rev-parse --abbrev-ref HEAD 2>/dev/null || true)"
		if [[ -z "$branch" || "$branch" == "HEAD" ]]; then
			logv "$name is in detached HEAD or has no branch; skipping pull."
			continue
		fi

		if "${git_cmd[@]}" -C "$repo_dir" pull --ff-only; then
			log "Updated $name (branch: $branch)"
			((UPDATED++)) || true
		else
			logv "Could not fast-forward $name (branch: $branch); manual intervention may be required."
		fi
	fi
done <"$tmpfile"

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------

echo
echo "Summary for $USERNAME -> $DEST_DIR"
echo "  Total repositories discovered : $TOTAL"
echo "  Cloned                        : $CLONED"
echo "  Updated (fast-forward)        : $UPDATED"
echo "  Skipped (local changes)       : $SKIPPED_LOCAL"
echo "  Submodule warnings            : $SUBMODULE_WARN"
echo "  Failed operations             : $FAILED"

if ((${#FAILED_LIST[@]} > 0)); then
	echo
	echo "Failures / warnings:" >&2
	for f in "${FAILED_LIST[@]}"; do
		echo "  - $f" >&2
	done
fi

exit 0
