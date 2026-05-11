#!/usr/bin/env bash
set -Eeuo pipefail

log() {
	printf '[smoke-test] %s\n' "$*"
}

fail() {
	printf '[smoke-test] ERROR: %s\n' "$*" >&2
	exit 1
}

require_cmd() {
	command -v "$1" >/dev/null 2>&1 || fail "Missing required command: $1"
}

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
test_root=""
parent_dir=""
main_repo=""
worktree_dir=""
container_id=""

cleanup() {
	local exit_code=$?
	trap - EXIT

	if command -v docker >/dev/null 2>&1 && [[ -n "$worktree_dir" ]]; then
		local discovered_ids=""
		discovered_ids="$(docker ps -aq \
			--filter "label=devcontainer.local_folder=${worktree_dir}" \
			--filter "label=devcontainer.config_file=${worktree_dir}/.devcontainer/devcontainer.json" || true)"

		if [[ -n "$container_id" ]]; then
			log "Removing test container ${container_id:0:12}"
			docker rm -f "$container_id" >/dev/null 2>&1 || true
		elif [[ -n "$discovered_ids" ]]; then
			while IFS= read -r id; do
				[[ -n "$id" ]] || continue
				log "Removing discovered test container ${id:0:12}"
				docker rm -f "$id" >/dev/null 2>&1 || true
			done <<< "$discovered_ids"
		fi
	fi

	if [[ -n "$test_root" && -d "$test_root" ]]; then
		if [[ "$exit_code" -ne 0 ]]; then
			log "Smoke test failed; keeping temp artifacts at $test_root"
		elif [[ "${KEEP_SMOKE_TEST_ARTIFACTS:-0}" == "1" ]]; then
			log "Keeping temp artifacts at $test_root"
		else
			rm -rf "$test_root"
		fi
	fi

	exit "$exit_code"
}

trap cleanup EXIT

require_cmd git
require_cmd docker
require_cmd devcontainer

log "Creating temporary test workspace"
test_root="$(cd "$(mktemp -d "${TMPDIR:-/tmp}/git-worktrees-devcontainer-smoke.XXXXXX")" && pwd -P)"
parent_dir="${test_root}/parent"
main_repo="${parent_dir}/sample-repo"
worktree_dir="${parent_dir}/branch-1"
mkdir -p "$parent_dir"

log "Initializing temporary Git repository"
git init -b main "$main_repo" >/dev/null
git -C "$main_repo" config user.name "Smoke Test"
git -C "$main_repo" config user.email "smoke-test@example.com"
printf '# smoke test repo\n' > "$main_repo/README.md"
git -C "$main_repo" add README.md
git -C "$main_repo" commit -m "init" >/dev/null

log "Copying devcontainer template under test"
cp -R "$repo_root/.devcontainer" "$main_repo/.devcontainer"
git -C "$main_repo" add .devcontainer
git -C "$main_repo" commit -m "add devcontainer" >/dev/null

log "Creating linked worktree"
git -C "$main_repo" worktree add "$worktree_dir" -b branch-1 main >/dev/null

expected_gitdir="gitdir: ${main_repo}/.git/worktrees/branch-1"
actual_gitdir="$(cat "$worktree_dir/.git")"
[[ "$actual_gitdir" == "$expected_gitdir" ]] || fail "Unexpected .git pointer in worktree: $actual_gitdir"

log "Resolving devcontainer configuration"
devcontainer read-configuration --workspace-folder "$worktree_dir" >/dev/null 2>&1

log "Starting devcontainer for linked worktree"
up_log="${test_root}/devcontainer-up.jsonl"
if ! devcontainer up \
	--remove-existing-container \
	--log-format json \
	--workspace-folder "$worktree_dir" > "$up_log" 2>&1; then
	log "devcontainer up failed; inspect $up_log"
	exit 1
fi

container_id="$(grep -E '"outcome":"success"' "$up_log" | tail -n 1 | sed -E 's/.*"containerId":"([^"]+)".*/\1/')"
[[ -n "$container_id" ]] || fail "Could not extract containerId from devcontainer up output"

log "Verifying Git works inside the container"
devcontainer exec --workspace-folder "$worktree_dir" --remote-env EXPECTED_BRANCH=branch-1 sh -lc 'git status --short --branch | grep -Fx "## ${EXPECTED_BRANCH}" >/dev/null' >/dev/null
devcontainer exec --workspace-folder "$worktree_dir" --remote-env EXPECTED_COMMIT_TEXT='add devcontainer' sh -lc 'git log --oneline -2 | grep -F "${EXPECTED_COMMIT_TEXT}" >/dev/null' >/dev/null
devcontainer exec --workspace-folder "$worktree_dir" --remote-env EXPECTED_GITDIR="$expected_gitdir" sh -lc 'grep -Fx "${EXPECTED_GITDIR}" .git >/dev/null' >/dev/null
devcontainer exec --workspace-folder "$worktree_dir" --remote-env EXPECTED_TOPLEVEL=/workspaces/branch-1 sh -lc 'test "$(git rev-parse --show-toplevel)" = "${EXPECTED_TOPLEVEL}"' >/dev/null

log "Verifying safe.directory coverage"
devcontainer exec --workspace-folder "$worktree_dir" --remote-env EXPECTED_SAFE_DIRECTORY='/workspaces/*' sh -lc 'git config --global --get-all safe.directory | grep -Fx "${EXPECTED_SAFE_DIRECTORY}" >/dev/null' >/dev/null
devcontainer exec --workspace-folder "$worktree_dir" --remote-env EXPECTED_SAFE_DIRECTORY="${parent_dir}/*" sh -lc 'git config --global --get-all safe.directory | grep -Fx "${EXPECTED_SAFE_DIRECTORY}" >/dev/null' >/dev/null

log "Smoke test passed"
log "Validated linked worktree Git commands, mirrored .git path, and safe.directory setup"
