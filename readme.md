# Git Worktrees + VS Code Dev Containers

A template for running multiple Git worktrees in parallel, each in its own VS Code Dev Container.

The goal is simple: give every branch its own folder, its own container, and its own breathing room so humans and AI agents can work in parallel without trampling each other.

## What this repository provides

- A Dev Container configuration that keeps Git worktree metadata reachable inside the container
- A host-side helper script that can create the recommended directory layout, move the main repository into it, and create worktrees for you
- Documentation that explains both the mental model and the technical trade-offs

## Supported workflow

This repository officially targets:

- macOS
- Linux
- WSL-based Windows

Native Windows path models are not the default target for this setup because the container mount strategy mirrors host paths directly. If you need native Windows support, plan on customizing the mount strategy.

## Recommended layout

This setup works best when the main repository and every worktree live as siblings under one shared parent directory:

```text
my-project-worktrees/
  my-project/      ← main repository
  agent-1/         ← linked worktree
  agent-2/         ← linked worktree
```

That shared parent directory becomes the trust and mount boundary for the Dev Container configuration. Keep it dedicated to this repository and its worktrees whenever possible.

## Quick start

### 1. Prerequisites

- Git
- Docker
- VS Code
- The [Dev Containers extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers)

### 2. Clone the repository

Clone this repository normally.

### 3. Run the helper script on the host

From the repository root, run:

```bash
./scripts/setup-worktrees.sh
```

The script can:

- create a dedicated parent directory for the repo and its worktrees
- move the main repository into that parent directory if needed
- create one or more worktrees and branches in one pass
- optionally open each new worktree in a separate VS Code window if the `code` CLI is available

### 4. Open each worktree in VS Code

Open each worktree folder in its own VS Code window. VS Code should detect the `.devcontainer` folder and prompt you to reopen the folder in a container.

## What the helper script standardizes

The helper script is intentionally narrow. It does not install Docker, manage secrets, or guess your branching strategy. It focuses on one job: putting the repository into a directory layout that this Dev Container configuration can support reliably.

You can inspect script usage any time with:

```bash
./scripts/setup-worktrees.sh --help
```

Example non-interactive usage:

```bash
./scripts/setup-worktrees.sh \
  --managed-parent /Users/me/my-project-worktrees \
  --base-branch main \
  --branches agent-1,agent-2 \
  --yes
```

## Manual setup for advanced users

If you already have a parent directory layout you like, you can still create worktrees manually. The important part is that the main repository and the linked worktrees share the same parent directory.

Example:

```bash
# main repository
/projects/my-project-worktrees/my-project

# inside the main repository
git worktree add ../agent-1 -b agent-1 main
git worktree add ../agent-2 -b agent-2 main
```

If you keep the main repository in a broad folder like `~/code` or `~/Data`, the Dev Container will mount and trust that broader parent. That still works, but it is less tidy and less isolated than using a dedicated parent directory.

## Security and path-model notes

- The container bind-mounts the full shared parent directory so Git can resolve linked worktree metadata.
- Git safe-directory configuration is added for `parent/*`, not just one repo path, so sibling worktrees are trusted as well.
- Because of that, the recommended parent directory should contain only the main repository and its worktrees.
- Native Windows hosts may require a different mount strategy than the one included here.

## Two usage patterns

- **Use this repository as a template or starting point** for your own project
- **Copy `.devcontainer` and `scripts/setup-worktrees.sh` into an existing repository** to give that repository the same workflow

## Learn more

- **[concepts.md](./concepts.md)** — Conceptual background for worktrees, containers, and why the combination helps
- **[.devcontainer/readme.md](./.devcontainer/readme.md)** — Technical reference for the Dev Container configuration and its assumptions
