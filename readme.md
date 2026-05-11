# Git Worktrees + VS Code Dev Containers

This repository shows how to run multiple Git worktrees inside VS Code Dev Containers without breaking Git commands. This is useful for modern AI-assisted development workflows where you want to let each AI code agent develop or fix issues in parallel on different branches, and you want each branch to have its own containerized environment with its own dependencies.

You can use this repository as a template for new projects or copy the relevant parts into an existing repository.

## The Problem: Git worktrees often break inside VS Code Dev Containers

More teams are using AI coding agents to try several different fixes or approaches in parallel. Git worktrees solve the **separate branch, separate folder** part of that workflow.

But the moment one branch wants **Python 3.10** while another wants **Python 3.12**, or one experiment upgrades package versions while another stays pinned, worktrees alone are not enough. Each branch also needs its own environment.

That is where Dev Containers help — and that is also where the usual linked-worktree problem shows up. This repository exists to solve that last mile cleanly:

- use Git worktrees for parallel branches
- use Dev Containers for per-branch environments
- make the combination actually work inside VS Code containers

In other words: **This repository is a reusable pattern for running multiple branches in parallel when each branch may need different toolchain or dependency choices.**

## How to use this repository

1. Start by reading this file for the overview, the problem statement, and the quick start
2. Optionally read [concepts.md](./concepts.md) to understand the underlying topics like what Git worktrees are, what Dev Containers add, and why the combination is powerful
3. Finally, read [.devcontainer/readme.md](./.devcontainer/readme.md) to understand how the container setup works, how to verify it, and how to customize it safely if your layout differs from the recommended one

If you just want the recommended happy path, clone the repository and run [`./.devcontainer/setup-worktrees.sh`](./.devcontainer/setup-worktrees.sh). That is the guided setup this repo is optimized for.

## Quick start

### 1. Install the prerequisites

- Git
- Python 3
- Docker
- VS Code
- The [Dev Containers extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers)

### 2. Clone the repository

Clone this repository normally.

### 3. Run the helper script on the host

From the repository root on your **host machine**:

```bash
./.devcontainer/setup-worktrees.sh
```

The script can:

- create a dedicated shared parent directory for the main repository and its worktrees
- move the main repository into that shared parent directory if needed
- create one or more worktrees and branches in one pass
- optionally open each new worktree in a separate VS Code window if `code` or `code-insiders` is available

If both VS Code CLIs are installed, the script prefers `code` and falls back to `code-insiders`.

For the recommended workflow, this script handles essentially all of the **repo-local setup** that should be automated:

- choose or create the shared parent directory
- move the main repository into that layout if needed
- create the branches and linked worktrees
- optionally open each worktree in VS Code

After that, each branch can evolve independently — including `.devcontainer` changes, language-version changes, or dependency pins — because each worktree is its own checkout.

One important caveat: if the repository already has linked worktrees and still needs to be moved into the shared-parent layout, the script will refuse that auto-move. In that case, move the repository manually first and run `git worktree repair` before re-running the script.

The script is intentionally narrow. It does **not** install Docker, manage secrets, or choose your branching strategy for you. It standardizes the filesystem layout that the Dev Container configuration expects.

To inspect usage:

```bash
./.devcontainer/setup-worktrees.sh --help
```

To preview actions without changing anything:

```bash
./.devcontainer/setup-worktrees.sh --dry-run
```

Example non-interactive usage:

```bash
./.devcontainer/setup-worktrees.sh \
  --managed-parent /Users/me/my-project-worktrees \
  --base-branch main \
  --branches agent-1,agent-2 \
  --yes
```

This repository intentionally does **not** ship with pre-created demo branches. The useful branches and worktrees are local, task-specific state, and the helper script can create the ones you actually want on your machine.

### 4. Open each worktree in its own VS Code window

Open each worktree folder separately. VS Code should detect the `.devcontainer` folder and prompt you to reopen the folder in a container.

### 5. Verify Git works inside the container

After the container starts, run:

```bash
git status
git log --oneline -5
cat .git
```

You want `git status` and `git log` to work normally, and you want `.git` to show a pointer back to the main repository's Git metadata.

## Recommended layout

The happy path for this repository is a dedicated **shared parent directory** that contains only the main repository and its worktrees:

```text
my-project-worktrees/
  my-project/      ← main repository
  agent-1/         ← linked worktree
  agent-2/         ← linked worktree
```

That shared parent directory becomes both:

- the container's extra bind-mount boundary
- Git's trust boundary for repositories or worktrees under `parent/*`

Keep it dedicated to this repository whenever possible.

## Manual setup for advanced users

If you already manage your own layout, you can create worktrees manually as long as the main repository and the linked worktrees still share the same shared parent directory.

Example:

```bash
# main repository
/projects/my-project-worktrees/my-project

# inside the main repository
git worktree add ../agent-1 -b agent-1 main
git worktree add ../agent-2 -b agent-2 main
```

If you keep the repository under a broad folder such as `~/code` or `~/Data`, the container can still work, but it will mount that broader parent and Git will trust `parent/*` under it as well. That is less tidy and less isolated than using a dedicated shared parent directory.

## Advanced path: use the Dev Container setup without the helper script

The helper script is optional. Advanced users can copy or use the `.devcontainer` setup directly without using [`.devcontainer/setup-worktrees.sh`](./.devcontainer/setup-worktrees.sh).

If you take that route, you are responsible for keeping all three of these aligned:

- the shared parent directory layout on the host
- the container mount path that makes the main repository reachable from each worktree
- the Git `safe.directory` entries that trust the resulting paths

In other words: skipping the helper script is absolutely supported, but it also means you own the sharp edges.

## Two ways to adopt this repository

You can use this repository in either of these ways:

1. **Use it as a template or starting point** for a new project that wants this workflow from day one
2. **Copy the `.devcontainer` folder and `.devcontainer/setup-worktrees.sh` into an existing repository** to retrofit the same workflow

The approach is local-layout based, so it works the same whether your remote is GitHub over HTTPS, GitHub over SSH, or another standard Git remote setup.

If the main thing you want is the linked-worktree-inside-devcontainer fix, you can absolutely reuse the `.devcontainer` setup directly and adapt it to your own repository.

## Security and trust-boundary note

This setup intentionally mounts and trusts the whole shared parent directory so linked worktrees can function correctly inside the container.

That means:

- the container can see sibling folders under that parent
- Git trust is configured for `parent/*`, which can include any sibling repository or worktree under that parent, not just the ones you intended for this workflow

For that reason, the recommended shared parent directory should contain only the main repository and its worktrees.
