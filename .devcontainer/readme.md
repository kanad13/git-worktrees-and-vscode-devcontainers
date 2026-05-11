# Dev Container configuration for Git worktrees

This folder contains a VS Code Dev Container configuration for linked Git worktrees.
For more context on why this is useful and how it works, see the main [readme.md](https://github.com/kanad13/git-worktrees-and-vscode-devcontainers/readme.md) and [concepts.md](https://github.com/kanad13/git-worktrees-and-vscode-devcontainers/concepts.md).

You can copy this `.devcontainer/` folder into your own repository and follow the setup below so that you can run multiple Git worktrees inside VS Code Dev Containers without breaking Git commands.

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

Copy the `.devcontainer/` folder from this repository into the root of your main repository, which is now `my-project/` in the example layout.

After copying it, your layout should look like this:

```text
my-project-worktrees/
  my-project/
    .devcontainer/
```


Because each linked worktree is its own checkout of the repository, each worktree will also contain the same `.devcontainer/` folder.

### 4. Create linked worktrees with plain Git

Now create linked worktrees using plain Git commands. The worktree command can create new branches and check them out simultaneously.

**For new branches** (creates the branch and worktree in one step):

```bash
cd my-project-worktrees/my-project/
git worktree add ../branch-1 -b branch-1 main
git worktree add ../branch-2 -b branch-2 main
```

**If a branch already exists locally**, omit the `-b` flag:

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

### 5. Open each worktree in VS Code

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

### Optional: verify with the Dev Container CLI

If you want to verify the setup outside the VS Code UI, you can do the same check with the Dev Container CLI:

```bash
devcontainer up --workspace-folder /path/to/branch-1
devcontainer exec --workspace-folder /path/to/branch-1 git status
devcontainer exec --workspace-folder /path/to/branch-1 git log --oneline -5
devcontainer exec --workspace-folder /path/to/branch-1 sh -lc 'cat .git && printf "\n---\n" && git config --global --get-all safe.directory'
```

That lets you confirm both parts of the fix:

- the linked worktree's `.git` pointer still resolves inside the container
- `safe.directory` trusts the sibling set under the shared parent

## Platform scope

This repository officially supports:

- macOS
- Linux
- Windows via WSL

Native Windows hosts are not the default target because mirrored path strategies differ enough that you may need a custom mount solution.

## Example use cases

### Different Python versions

Create worktrees for testing Python version compatibility.

The important detail is that this template reads the `image` field directly from `.devcontainer/devcontainer.json`. If you want different branches to use different base images, edit that field in each branch's copy of `devcontainer.json`.

```bash
# Create a test branch worktree
cd my-project-worktrees/my-project
git worktree add ../python-3.10-test -b python-3.10-test
```

Then update `.devcontainer/devcontainer.json` in each worktree, for example:

```json
// my-project/.devcontainer/devcontainer.json
"image": "mcr.microsoft.com/devcontainers/python:3.12"

// python-3.10-test/.devcontainer/devcontainer.json
"image": "mcr.microsoft.com/devcontainers/python:3.10"
```

Each worktree can customize its own `devcontainer.json` independently.

### Different dependencies

Test dependency upgrades in isolated branches:

```bash
# Branch A: stable dependencies
git worktree add ../stable-deps -b stable-deps

# Branch B: upgraded dependencies
git worktree add ../upgrade-test -b upgrade-test
cd ../upgrade-test
# Modify requirements.txt or package.json for testing
```

Each container will have its own isolated environment, preventing conflicts.
