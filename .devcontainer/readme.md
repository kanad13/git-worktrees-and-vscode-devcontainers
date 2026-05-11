# Dev Container Technical Reference for Linked Git Worktrees

This folder contains the Dev Container configuration that makes linked Git worktrees usable inside VS Code containers.

## What this configuration assumes

The happy path for this repository is a sibling layout inside one shared parent directory:

```text
shared-parent/
  my-project/      ← main repository
  agent-1/         ← linked worktree
  agent-2/         ← linked worktree
```

## The implementation used in this repository

This repository fixes the problem by mounting the **shared parent directory** into the container at the **same path** it has on the host, then configuring Git trust for repositories or worktrees under that parent.

That gives you two important properties:

1. Git can still follow the worktree's `.git` pointer to the main repository's metadata
2. the sibling repositories or worktrees under that parent share one predictable trust boundary

## Key configuration elements

### 1. Pinned base image

```jsonc
"image": "mcr.microsoft.com/devcontainers/base:ubuntu-24.04"
```

The configuration uses the published base image directly to keep the setup simple and reproducible without adding an extra `Dockerfile` layer.

### 2. Parent-directory bind mount

```jsonc
"mounts": [
  "source=${localWorkspaceFolder}/..,target=${localWorkspaceFolder}/..,type=bind,consistency=cached"
]
```

This is the heart of the worktree fix.

It bind-mounts the shared parent directory into the container at the same path it has on the host. That means the main repository and the sibling worktrees remain reachable where the worktree expects them to be.

`consistency=cached` is mostly relevant to Docker Desktop on macOS. It is safe to leave in place on Linux and WSL.

### 3. Git `safe.directory` wildcard entries

```jsonc
"postCreateCommand": "container_parent=\"$(dirname '${containerWorkspaceFolder}')\" && mirrored_parent=\"$(dirname '${localWorkspaceFolder}')\" && git config --global --add safe.directory \"${container_parent}/*\" && git config --global --add safe.directory \"${mirrored_parent}/*\""
```

Git's `safe.directory` is path-based. Trusting only one directory is not enough when you expect multiple sibling worktrees under the same parent.

This configuration adds wildcard trust entries for both:

- the default container-side parent path, such as `/workspaces/...`
- the mirrored host-path parent exposed by the extra bind mount

That keeps Git happy whether you inspect the repository via the default workspace path or the mirrored host path.

## Why the helper script exists

This Dev Container configuration is intentionally opinionated rather than universal.

The helper script exists so the filesystem layout, the extra bind mount, the Git trust settings, and the documentation all agree on the same assumptions. It keeps the setup understandable instead of pretending every possible host layout can be supported with the same one-line configuration.

## Security implications

Because this configuration mounts and trusts `parent/*`:

- the container can see sibling folders under that parent directory
- Git will trust repositories or worktrees under that parent, not just the specific sibling worktrees you planned to create

That is why the recommended setup is a **dedicated shared parent directory** containing only:

- the main repository
- its linked worktrees

If you deliberately place the repository inside a broader folder such as `~/code`, the setup can still work, but the visibility and trust boundary become broader too.

## Platform scope

This repository officially supports:

- macOS
- Linux
- Windows via WSL

Native Windows hosts are not the default target because mirrored path strategies differ enough that you may need a custom mount solution.

## Verifying the setup

After VS Code reopens a linked worktree in a container, run:

```bash
git status
git log --oneline -5
cat .git
```

You want to see all of the following:

- `git status` works without a repository error
- `git log` works normally
- `.git` contains a pointer back to Git admin data owned by the main repository

## Troubleshooting

### `fatal: not a git repository`

Check these first:

- the main repository and the worktree are siblings under one shared parent directory
- you opened the worktree folder itself in VS Code, not some broader parent
- `devcontainer.json` still includes the parent-directory bind mount

### `detected dubious ownership in repository`

That usually means one of these is true:

- `postCreateCommand` did not run
- the trusted wildcard paths no longer match your actual layout
- you changed the mount strategy but not the `safe.directory` entries

### Native Windows host path issues

If you are not using WSL, plan on customizing the mount strategy. The mirrored host-path approach in this repository is primarily aimed at POSIX-style paths.

## Customizing for non-standard layouts

If your worktrees do **not** live as siblings of the main repository, update both of the following together:

1. the `mounts` entry so the container can reach the path referenced by the worktree
2. the `postCreateCommand` safe-directory entries so Git trusts the resulting paths

That pairing matters. Changing only one of them is how you end up with a container that can see the files but still refuses to run Git, or a container where Git would trust the path if only the path existed.
