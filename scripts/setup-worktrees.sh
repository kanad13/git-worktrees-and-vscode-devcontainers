#!/usr/bin/env bash

# Host-side setup helper for the managed sibling layout used by this repository.
#
# Run this script from inside the repository on the host machine:
#   ./scripts/setup-worktrees.sh
#   ./scripts/setup-worktrees.sh --managed-parent /Users/me/my-project-worktrees --branches agent-1,agent-2
#
# It can:
# - choose or create a managed parent directory for the repository
# - move the main repository into that parent when needed
# - create one or more linked Git worktrees from a chosen base branch/ref
# - optionally open each worktree in VS Code or Code Insiders
#
# The slightly unusual implementation detail is that the script re-execs itself
# from a temporary copy before it mutates paths. That lets it keep running even
# if it moves the repository directory that originally contained this script.

set -euo pipefail
shopt -s extglob

SCRIPT_NAME="${SETUP_WORKTREES_SCRIPT_NAME:-$(basename "$0")}"
DEFAULT_BRANCH_NAMES="agent-1, agent-2"

# Minimal output and failure helpers used throughout the script.
say() {
	printf '%s\n' "$*"
}

warn() {
	printf 'warning: %s\n' "$*" >&2
}

die() {
	printf 'error: %s\n' "$*" >&2
	exit 1
}

command_exists() {
	command -v "$1" >/dev/null 2>&1
}

# Prefer the stable VS Code CLI when both are installed, but support Insiders.
detect_vscode_cli() {
	if command_exists code; then
		printf '%s' "code"
	elif command_exists code-insiders; then
		printf '%s' "code-insiders"
	else
		return 1
	fi
}

trim() {
	local value="$1"
	value="${value##+([[:space:]])}"
	value="${value%%+([[:space:]])}"
	printf '%s' "$value"
}

# Help text doubles as the quick reference for people opening the script directly.
usage() {
	cat <<EOF
Usage: $SCRIPT_NAME [options]

Create a managed parent directory for this repository, optionally move the
repository into it, and create Git worktrees for one or more branches.

Options:
  --managed-parent PATH   Parent directory that should contain the main repo and all worktrees
  --base-branch REF       Branch or commit to create new worktrees from (default: current branch or main)
  --branches LIST         Comma-separated branch names (default: ${DEFAULT_BRANCH_NAMES})
	--open-code             Open each new worktree in a new VS Code window (prefers code, then code-insiders)
  --no-open-code          Do not open VS Code automatically
  --yes                   Accept defaults and skip confirmation prompts
  --dry-run               Print planned actions without making changes
  --help                  Show this help text

Examples:
	./scripts/$SCRIPT_NAME
	./scripts/$SCRIPT_NAME --managed-parent /Users/me/my-project-worktrees --branches agent-1,agent-2
	./scripts/$SCRIPT_NAME --base-branch main --branches bugfix/login,refactor/api --open-code
EOF
}

prompt() {
	local __var_name="$1"
	local text="$2"
	local default_value="${3-}"
	local response=""

	if [[ "$ASSUME_YES" == "1" ]]; then
		response="$default_value"
		say "$text [$default_value]: $response"
		printf -v "$__var_name" '%s' "$response"
		return
	fi

	if [[ -n "$default_value" ]]; then
		read -r -p "$text [$default_value]: " response
		response="${response:-$default_value}"
	else
		read -r -p "$text: " response
	fi

	printf -v "$__var_name" '%s' "$response"
}

# Shared yes/no prompt helper with sensible defaults for interactive use.
confirm() {
	local text="$1"
	local default_answer="${2:-Y}"
	local response=""
	local prompt_suffix="[Y/n]"

	if [[ "$default_answer" == "N" ]]; then
		prompt_suffix="[y/N]"
	fi

	if [[ "$ASSUME_YES" == "1" ]]; then
		say "$text $prompt_suffix yes"
		return 0
	fi

	read -r -p "$text $prompt_suffix " response
	response="$(trim "${response:-$default_answer}")"

	case "$response" in
		Y|y|yes|YES|Yes)
			return 0
			;;
		N|n|no|NO|No)
			return 1
			;;
		*)
			[[ "$default_answer" == "Y" ]]
			;;
	esac
}

# Use Python for path normalization instead of relying on GNU-only `realpath`.
make_absolute_dir() {
	local input_path="$1"
	python3 - <<'PY' "$input_path"
import os
import sys

print(os.path.abspath(os.path.expanduser(sys.argv[1])))
PY
}

# Re-exec from a temporary copy so moving the repository does not invalidate the
# path of the currently running script.
ensure_temp_runner() {
	if [[ "${SETUP_WORKTREES_SHIM:-0}" == "1" ]]; then
		if [[ -n "${SETUP_WORKTREES_TMP:-}" ]]; then
			trap 'rm -f "$SETUP_WORKTREES_TMP"' EXIT
		fi
		return
	fi

	local source_script="${BASH_SOURCE[0]}"
	local temp_script
	local temp_dir="${TMPDIR:-/tmp}"
	temp_dir="${temp_dir%/}"
	temp_script="$(mktemp "$temp_dir/setup-worktrees.XXXXXX")"
	cp "$source_script" "$temp_script"
	chmod +x "$temp_script"
	SETUP_WORKTREES_SHIM=1 SETUP_WORKTREES_TMP="$temp_script" SETUP_WORKTREES_SCRIPT_NAME="$SCRIPT_NAME" exec bash "$temp_script" "$@"
}

# Defaults stay interactive unless the caller opts into non-interactive mode.
ASSUME_YES="0"
DRY_RUN="0"
MANAGED_PARENT=""
BASE_BRANCH=""
BRANCH_INPUT=""
OPEN_CODE="ask"
VSCODE_CLI=""

ensure_temp_runner "$@"

while [[ $# -gt 0 ]]; do
	case "$1" in
		--managed-parent)
			[[ $# -ge 2 ]] || die "--managed-parent requires a path"
			MANAGED_PARENT="$2"
			shift 2
			;;
		--base-branch)
			[[ $# -ge 2 ]] || die "--base-branch requires a ref"
			BASE_BRANCH="$2"
			shift 2
			;;
		--branches)
			[[ $# -ge 2 ]] || die "--branches requires a comma-separated list"
			BRANCH_INPUT="$2"
			shift 2
			;;
		--open-code)
			OPEN_CODE="yes"
			shift
			;;
		--no-open-code)
			OPEN_CODE="no"
			shift
			;;
		--yes)
			ASSUME_YES="1"
			shift
			;;
		--dry-run)
			DRY_RUN="1"
			shift
			;;
		--help|-h)
			usage
			exit 0
			;;
		*)
			die "Unknown option: $1"
			;;
	esac
done

# This helper is meant for the host because it may move the repository and is
# designed around host paths that the devcontainer mirrors.
if [[ -f /.dockerenv || -n "${DEVCONTAINER:-}" || -n "${REMOTE_CONTAINERS:-}" ]]; then
	die "Run this script on the host machine, not inside a container."
fi

command_exists git || die "git is required"
command_exists python3 || die "python3 is required"

# Resolve the preferred editor CLI once so dry-run and real execution report the
# same launcher choice.
VSCODE_CLI="$(detect_vscode_cli || true)"

repo_root="$(git rev-parse --show-toplevel 2>/dev/null || true)"
[[ -n "$repo_root" ]] || die "Run this script from inside a Git repository."

repo_root="$(make_absolute_dir "$repo_root")"
repo_name="$(basename "$repo_root")"
current_parent="$(dirname "$repo_root")"
# Remember the last managed parent in local Git config so reruns can default to
# the same sibling layout.
saved_parent="$(git config --local --get worktree.devcontainerManagedParent 2>/dev/null || true)"
saved_parent="$(trim "$saved_parent")"

if [[ -z "$MANAGED_PARENT" ]]; then
	if [[ -n "$saved_parent" && "$repo_root" == "$saved_parent/$repo_name" ]]; then
		MANAGED_PARENT="$saved_parent"
	elif [[ "$(basename "$current_parent")" == "${repo_name}-worktrees" && "$repo_root" == "$current_parent/$repo_name" ]]; then
		MANAGED_PARENT="$current_parent"
	else
		MANAGED_PARENT="$current_parent/${repo_name}-worktrees"
	fi
fi

MANAGED_PARENT="$(make_absolute_dir "$MANAGED_PARENT")"
target_repo_root="$MANAGED_PARENT/$repo_name"

current_branch="$(git branch --show-current 2>/dev/null || true)"
default_base_branch="${current_branch:-main}"

if [[ -z "$BASE_BRANCH" ]]; then
	prompt BASE_BRANCH "Base branch or ref for new worktrees" "$default_base_branch"
fi

BASE_BRANCH="$(trim "$BASE_BRANCH")"
[[ -n "$BASE_BRANCH" ]] || die "Base branch cannot be empty"
git rev-parse --verify "${BASE_BRANCH}^{commit}" >/dev/null 2>&1 || die "Base branch or ref '$BASE_BRANCH' does not exist"

if [[ -z "$BRANCH_INPUT" ]]; then
	prompt BRANCH_INPUT "Branch names to create as worktrees (comma-separated)" "$DEFAULT_BRANCH_NAMES"
fi

BRANCH_INPUT="$(trim "$BRANCH_INPUT")"
[[ -n "$BRANCH_INPUT" ]] || die "At least one branch name is required"

if [[ "$OPEN_CODE" == "ask" ]]; then
	# Only ask about opening editor windows when we actually found a supported CLI.
	if [[ -n "$VSCODE_CLI" ]]; then
		if confirm "Open each new worktree in a new VS Code window when setup completes?" N; then
			OPEN_CODE="yes"
		else
			OPEN_CODE="no"
		fi
	else
		OPEN_CODE="no"
	fi
fi

declare -a BRANCHES=()

# Normalize and validate branch names up front so the script fails before any
# filesystem or Git mutations happen.
IFS=',' read -r -a raw_branches <<< "$BRANCH_INPUT"
for raw_branch in "${raw_branches[@]}"; do
	branch_name="$(trim "$raw_branch")"
	[[ -n "$branch_name" ]] || continue
	git check-ref-format --branch "$branch_name" >/dev/null 2>&1 || die "Invalid branch name: $branch_name"
	for seen_branch in "${BRANCHES[@]-}"; do
		if [[ "$seen_branch" == "$branch_name" ]]; then
			die "Branch '$branch_name' was listed more than once"
		fi
	done
	BRANCHES+=("$branch_name")
done

[[ ${#BRANCHES[@]} -gt 0 ]] || die "At least one valid branch name is required"

worktree_count="$(git worktree list --porcelain | grep -c '^worktree ' || true)"
move_repo="0"

# Decide whether the main repository must be moved into the managed parent
# before any worktrees are created.
if [[ "$repo_root" != "$target_repo_root" ]]; then
	say ""
	say "Recommended layout"
	say "  parent directory: $MANAGED_PARENT"
	say "  main repository : $target_repo_root"
	say "  worktrees       : $MANAGED_PARENT/<branch-name>"
	say ""
	say "The main repository and every worktree must share the same parent directory for this Dev Container setup to work reliably."
	if ! confirm "Move the current repository into the managed parent now?" Y; then
		die "Aborted. Re-run the script with a managed parent that already contains this repository, or allow the move."
	fi
	move_repo="1"
	if [[ "$worktree_count" -gt 1 ]]; then
		die "This repository already has linked worktrees. Move the main repository manually and run 'git worktree repair' before re-running this script."
	fi
fi

declare -a WORKTREE_PATHS=()
for branch_name in "${BRANCHES[@]}"; do
	worktree_path="$MANAGED_PARENT/$branch_name"
	if [[ "$worktree_path" == "$target_repo_root" ]]; then
		die "Branch '$branch_name' would collide with the main repository path"
	fi
	if [[ -e "$worktree_path" ]]; then
		die "Worktree path already exists: $worktree_path"
	fi
	WORKTREE_PATHS+=("$worktree_path")
done

# Show the full plan before making any changes. This keeps the script easier to
# audit and makes --dry-run output match the real execution path closely.
say ""
say "Setup summary"
say "  current repository : $repo_root"
say "  managed parent     : $MANAGED_PARENT"
say "  target repository  : $target_repo_root"
say "  base branch/ref    : $BASE_BRANCH"
say "  worktrees to make  : ${BRANCHES[*]}"
if [[ "$OPEN_CODE" == "yes" && -n "$VSCODE_CLI" ]]; then
	say "  open in VS Code    : $OPEN_CODE ($VSCODE_CLI)"
else
	say "  open in VS Code    : $OPEN_CODE"
fi
say "  dry run            : $DRY_RUN"
say ""

if ! confirm "Proceed with these changes?" Y; then
	die "Aborted. No changes were made."
fi

# Dry-run mode prints the exact operations without mutating the filesystem.
if [[ "$DRY_RUN" == "1" ]]; then
	if [[ "$move_repo" == "1" ]]; then
		say "[dry-run] mkdir -p '$MANAGED_PARENT'"
		say "[dry-run] mv '$repo_root' '$target_repo_root'"
	fi
	for i in "${!BRANCHES[@]}"; do
		branch_name="${BRANCHES[$i]}"
		worktree_path="${WORKTREE_PATHS[$i]}"
		if git show-ref --verify --quiet "refs/heads/$branch_name"; then
			say "[dry-run] git worktree add '$worktree_path' '$branch_name'"
		else
			say "[dry-run] git worktree add -b '$branch_name' '$worktree_path' '$BASE_BRANCH'"
		fi
		done
	if [[ "$OPEN_CODE" == "yes" ]]; then
		if [[ -n "$VSCODE_CLI" ]]; then
			for worktree_path in "${WORKTREE_PATHS[@]}"; do
				say "[dry-run] $VSCODE_CLI -n '$worktree_path'"
			done
		else
			say "[dry-run] warning: neither 'code' nor 'code-insiders' is available, so worktrees would not be opened automatically."
		fi
	fi
	exit 0
fi

# From this point on, the script is performing real filesystem and Git changes.
mkdir -p "$MANAGED_PARENT"

if [[ "$move_repo" == "1" ]]; then
	[[ ! -e "$target_repo_root" ]] || die "Target repository path already exists: $target_repo_root"
	old_repo_root="$repo_root"
	say "Moving repository to $target_repo_root"
	cd /
	mv "$old_repo_root" "$target_repo_root"
	repo_root="$target_repo_root"
	cd "$repo_root"
	# Persist the chosen managed parent so later runs can default to it.
	git config --local worktree.devcontainerManagedParent "$MANAGED_PARENT"
else
	cd "$repo_root"
	git config --local worktree.devcontainerManagedParent "$MANAGED_PARENT"
fi

declare -a CREATED_WORKTREES=()

for i in "${!BRANCHES[@]}"; do
	branch_name="${BRANCHES[$i]}"
	worktree_path="${WORKTREE_PATHS[$i]}"
	if git show-ref --verify --quiet "refs/heads/$branch_name"; then
		say "Creating worktree for existing local branch '$branch_name' at $worktree_path"
		git worktree add "$worktree_path" "$branch_name"
	else
		say "Creating worktree for new branch '$branch_name' from '$BASE_BRANCH' at $worktree_path"
		git worktree add -b "$branch_name" "$worktree_path" "$BASE_BRANCH"
	fi
	CREATED_WORKTREES+=("$worktree_path")
done

# Launch editor windows only after worktree creation succeeds.
if [[ "$OPEN_CODE" == "yes" ]]; then
	if [[ -n "$VSCODE_CLI" ]]; then
		for worktree_path in "${CREATED_WORKTREES[@]}"; do
			say "Opening $worktree_path in VS Code using '$VSCODE_CLI'"
			"$VSCODE_CLI" -n "$worktree_path" >/dev/null 2>&1 || warn "Could not open $worktree_path in VS Code using '$VSCODE_CLI'"
		done
	else
		warn "Neither the 'code' nor 'code-insiders' CLI is available, so worktrees were not opened automatically."
	fi
fi

say ""
say "Done. Recommended paths:"
say "  main repository : $repo_root"
for worktree_path in "${CREATED_WORKTREES[@]}"; do
	say "  worktree        : $worktree_path"
done

say ""
say "Current worktree list:"
git worktree list
