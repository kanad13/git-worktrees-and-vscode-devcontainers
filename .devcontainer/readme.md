# Dev Container Configuration for Git Worktrees

This folder contains the Dev Container configuration that makes linked Git worktrees usable inside VS Code containers.

The short version: a worktree's `.git` file points back to Git admin data in the main repository, so the container has to be able to reach that path too.

## Supported layout

This repository is built around one recommended layout:

```text
parent-directory/
  my-project/      ← main repository
  agent-1/         ← linked worktree
  agent-2/         ← linked worktree
```

The helper script at [`../scripts/setup-worktrees.sh`](../scripts/setup-worktrees.sh) creates this layout for you and can move the main repository into a dedicated parent directory when needed.

If you choose a different layout, you will likely need to customize the mount strategy manually.

## Why the helper script exists

This Dev Container configuration is intentionally opinionated. It assumes the main repository and all worktrees share one parent directory. The helper script standardizes that assumption so the docs, mount strategy, and Git safe-directory settings all line up.

That keeps the configuration understandable instead of pretending it is universal.

## The problem this solves

Git worktrees and Dev Containers have a compatibility problem:

- a worktree's `.git` file points back to Git admin data in the main repository
- VS Code normally mounts only the folder you open
- inside the container, the path in `.git` may not exist anymore
- the result is usually: `fatal: not a git repository`

## The solution implemented here

The configuration mounts the **entire shared parent directory** into the container at the same absolute path it has on the host.

That does two things:

1. Git can follow the path stored in the worktree's `.git` file
2. sibling worktrees live under one predictable trust boundary

## Key configuration elements

### 1. Pinned base image

```jsonc
"image": "mcr.microsoft.com/devcontainers/base:ubuntu-24.04"
```

This keeps the setup simple and reproducible without an extra `Dockerfile` layer.

### 2. Parent-directory bind mount

```jsonc
"mounts": [
  "source=${localWorkspaceFolder}/..,target=${localWorkspaceFolder}/..,type=bind,consistency=cached"
]
```

This is the core of the worktree fix. It makes the shared parent directory reachable inside the container using the same absolute path as the host.

`consistency=cached` is mainly relevant to Docker Desktop on macOS. It is safe to leave in place on Linux and WSL.

### 3. Git safe-directory wildcards

```jsonc
"postCreateCommand": "container_parent=\"$(dirname '${containerWorkspaceFolder}')\" && mirrored_parent=\"$(dirname '${localWorkspaceFolder}')\" && git config --global --add safe.directory \"${container_parent}/*\" && git config --global --add safe.directory \"${mirrored_parent}/*\""
```

Git's `safe.directory` is path-based. A single parent path is **not** enough by itself; to trust all sibling worktrees you need a wildcard entry like `parent/*`.

This configuration adds two wildcard entries:

- one for the default `/workspaces/...` path that VS Code uses inside the container
- one for the mirrored host-path parent that the extra bind mount exposes inside the container

That keeps Git happy whether you inspect the repo through the default workspace path or the mirrored host path.

## Platform scope

This repository officially supports:

- macOS
- Linux
- WSL-based Windows

Native Windows hosts are not the default target because path mirroring is different enough that you may need a custom mount strategy.

## Security note

Because this configuration mounts and trusts `parent/*`, the container can see and Git will trust sibling repositories under that parent directory.

That is why the recommended setup is:

- create a dedicated parent directory
- keep only the main repository and its linked worktrees under that parent

If you intentionally keep the repository under a broad folder like `~/code`, the setup can still work, but the mount and trust boundary become broader too.

## Customizing for non-standard layouts

If your worktrees do **not** live as siblings of the main repository, update both of these together:

1. the `mounts` entry so the container can reach the path referenced by the worktree `.git` file
2. the `postCreateCommand` safe-directory entries so Git trusts the resulting worktree paths

That pairing matters. Changing only one of them is how you end up with a container that can see the repo but still refuses to run Git, or vice versa.

## Verifying the configuration

After VS Code reopens a worktree in a container, run:

```bash
git status
git log --oneline -5
cat .git
```

What you want to see:

- `git status` works without a repository error
- `git log` works normally
- `.git` contains a pointer back to the main repository's Git admin data

## Troubleshooting

### `fatal: not a git repository`

Check these first:

- the main repository and worktree are siblings under one parent directory
- you opened the worktree folder itself in VS Code
- the container includes the parent-directory bind mount from `devcontainer.json`

### `detected dubious ownership in repository`

That usually means the `postCreateCommand` did not run or the safe-directory paths do not match the layout you are actually using.

### Native Windows host path issues

If you are not using WSL, expect to customize the mount strategy. The mirrored host-path technique in this repository is primarily aimed at POSIX-style paths.

For conceptual background on why this all matters, see [../concepts.md](../concepts.md).
