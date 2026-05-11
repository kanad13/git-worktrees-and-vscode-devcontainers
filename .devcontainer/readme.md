# Dev Container configuration for Git worktrees

This folder contains a VS Code Dev Container configuration for [linked Git worktrees](https://github.com/kanad13/git-worktrees-and-vscode-devcontainers).

You can copy this `.devcontainer/` folder into your own repository and follow the setup below.

## Preread

- Read [`../concepts.md`](https://github.com/kanad13/git-worktrees-and-vscode-devcontainers/concepts.md) if you want the background on why combining Git worktrees and VS Code Dev Containers is powerful for AI-assisted workflows, and what the hidden compatibility issue is that this repository solves.

## Quick start

### 1. Install the prerequisites

You need:

- Git
- Docker
- VS Code
- the [Dev Containers extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers)

This setup officially targets:

- macOS
- Linux
- Windows via WSL

### 2. Create one dedicated shared parent directory

Assuming you have an existing repository, say `my-project`, then create a new folder named something like `my-project-worktrees` and move the repository into it.

Example:

```text
my-project-worktrees/
  my-project/      ← main repository
```

The shared parent directory is important because it allows the container to see the main repository's Git metadata from each linked worktree, which is how it can run Git commands without breaking.

That dedicated parent becomes both:

- the extra bind-mount boundary used by the container
- the Git trust boundary for `parent/*`

### 3. Copy this `.devcontainer/` folder into your repository root

Clone [this repository](https://github.com/kanad13/git-worktrees-and-vscode-devcontainers) and copy from it the `.devcontainer/` folder into the root of your main repository, which is now `my-project/` in the example layout.

After copying it, your layout should look like this:

```text
my-project-worktrees/
  my-project/
    .devcontainer/
```

Because each linked worktree is its own checkout of the repository, each worktree will also contain the same `.devcontainer/` folder.

### 4. Create branches in your repository

If you don't have any branches yet, create the ones you want to work on in parallel.
These are the branches that your AI code agents will work on at the same time.

```bash
git checkout -b branch-1
git checkout -b branch-2
```

### 5. Create linked worktrees with plain Git

Now create linked worktrees for each branch using plain Git commands.

For new branches:

```bash
cd my-project-worktrees/my-project/
git worktree add ../branch-1 -b branch-1 main
git worktree add ../branch-2 -b branch-2 main
```

If a branch already exists locally, omit `-b`:

```bash
git worktree add ../branch-1 branch-1
```

Your layout will then look like this:

```text
my-project-worktrees/
  my-project/
    .devcontainer/
  branch-1/
  branch-2/
```

### 6. Open each worktree in VS Code

Open each folder separately in different VS Code windows:

- `my-project/`
- `branch-1/`
- `branch-2/`

VS Code should detect `.devcontainer/` and offer to reopen the folder in a container.

Each worktree can then run in its own containerized environment.

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

## Platform scope

This repository officially supports:

- macOS
- Linux
- Windows via WSL

Native Windows hosts are not the default target because mirrored path strategies differ enough that you may need a custom mount solution.
