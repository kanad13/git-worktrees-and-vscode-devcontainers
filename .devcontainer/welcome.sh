#!/usr/bin/env bash

set -euo pipefail

workspace_dir="$(pwd)"

add_safe_directory() {
	local path="$1"

	[[ -n "$path" ]] || return 0
	[[ -e "$path" ]] || return 0

	if git config --global --get-all safe.directory 2>/dev/null | grep -Fxq "$path"; then
		return 0
	fi

	git config --global --add safe.directory "$path"
}

detect_main_repo_dir() {
	local gitfile="$workspace_dir/.git"
	local gitdir_path=""
	local gitdir_abs=""

	[[ -f "$gitfile" ]] || return 0

	gitdir_path="$(sed -n 's/^gitdir: //p' "$gitfile" | head -n 1)"
	[[ -n "$gitdir_path" ]] || return 0

	if [[ "$gitdir_path" == /* ]]; then
		gitdir_abs="$gitdir_path"
	else
		gitdir_abs="$workspace_dir/$gitdir_path"
	fi

	if [[ "$gitdir_abs" == */.git/worktrees/* ]]; then
		printf '%s\n' "${gitdir_abs%/.git/worktrees/*}"
	fi
}

echo "Configuring Git for a worktree-ready dev container..."

add_safe_directory "$workspace_dir"

main_repo_dir="$(detect_main_repo_dir || true)"
if [[ -n "$main_repo_dir" ]]; then
	add_safe_directory "$main_repo_dir"
fi

while IFS= read -r remote_path; do
	[[ "$remote_path" == /* ]] || continue
	add_safe_directory "$remote_path"
done < <(git remote -v 2>/dev/null | awk '{print $2}' | sort -u)

echo
echo "Validation:"
if git status --short --branch >/dev/null 2>&1 && git worktree list >/dev/null 2>&1; then
	echo "- Git works in this container."
	echo "- Linked worktree metadata is reachable."
else
	echo "- Git still cannot fully read the linked worktree metadata."
	echo "- Edit .devcontainer/devcontainer.json so the mounts cover both this worktree and the main repo."
fi

local_path_remotes="$(git remote -v 2>/dev/null | awk '{print $2}' | sort -u | awk '/^\// {print}' || true)"
if [[ -n "$local_path_remotes" ]]; then
	echo "- Local filesystem remotes detected:"
	while IFS= read -r remote_path; do
		[[ -n "$remote_path" ]] || continue
		if [[ -e "$remote_path" ]]; then
			echo "  - $remote_path"
		else
			echo "  - $remote_path (not mounted inside container)"
		fi
	done <<< "$local_path_remotes"
fi

echo
echo "Next checks:"
echo "- git status"
echo "- git worktree list"
echo "- git remote -v"
