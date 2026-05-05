# Worktree-ready Dev Container template

This folder exists for one reason: make linked Git worktrees work inside VS Code Dev Containers with as little extra configuration as possible.

If you want the repo-level overview first, read [../readme.md](../readme.md). If you want the conceptual explanation of why this works, read [../concepts.md](../concepts.md). If you want the commands for creating your first worktrees, jump to [the setup section in the root README](../readme.md#create-your-first-worktrees).

## What is in this folder

- `devcontainer.json`: the minimal container configuration, mount strategy, and VS Code customizations
- `welcome.sh`: a first-run setup script that registers safe Git directories and checks that Git can read the repo correctly

The default VS Code customizations install GitHub Copilot and GitHub Copilot Chat. Replace or remove them if you use a different AI assistant in VS Code.

## Default assumption

The template assumes the common layout where your main repo and linked worktrees live under the same parent directory. In that layout, the default parent-directory mount works without needing to hardcode the main repo name.

If your main repo is elsewhere, replace the default mount with the smallest host directory that contains both the current worktree and the main repo.

## Local filesystem remotes

If your Git remote uses SSH or HTTPS, no extra remote mount is needed.

If `git remote -v` points to an absolute path on disk and that path lives outside the shared parent directory, add another bind mount for that location.

`welcome.sh` automatically marks visible local-path remotes as safe once they are mounted inside the container.

## Copy it into another repo

1. Copy the `.devcontainer/` folder into the repo root.
2. Create or open a linked worktree for that repo.
3. Reopen the worktree in the container.
4. If Git still cannot see the main repo metadata, adjust the mount in `devcontainer.json`.

## What to verify after reopen

- `git status` works
- `git worktree list` works
- `git remote -v` shows any local-path remotes you expect

## What this template intentionally leaves to you

This folder does not install app runtimes, package dependencies, or project tools. Its job is only to make the worktree + devcontainer combination reliable. Add the rest in your own repo once this layer works.
