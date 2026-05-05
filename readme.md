# Git Worktrees + VS Code Dev Containers

This repository is a small, purpose-built starter for one specific problem: making linked Git worktrees behave correctly inside a VS Code Dev Container so you can do parallel AI-assisted work without breaking your main setup.

## Why this exists

Git worktrees isolate files. Dev Containers isolate tools and runtime. Together, they are a clean way to let you work in one checkout while AI agents work in another.

The catch is that a linked worktree usually stores `.git` as a file that points back to metadata in the main repo. Inside a container, that host path often does not exist. The folder opens, but Git commands fail.

This repo keeps the solution narrow:

- a minimal `.devcontainer` folder you can copy into another repo
- a default mount strategy for the common side-by-side worktree layout
- automatic Git `safe.directory` registration for the current workspace, the main repo, and visible local-path remotes
- docs organized around the why, what, and how

## What this repo is for

Use this if you want:

- Git worktrees for parallel tasks
- VS Code Dev Containers for isolated environments
- AI agents working in those isolated environments
- a setup that fixes the usual Git path issues caused by linked worktrees inside containers

## Two ways to use it

### Clone the repo

Use this repo as a reference and working example.

### Copy only `.devcontainer/`

If you already have a repo, copy the `.devcontainer/` folder into it and adapt only the parts that depend on your folder layout or AI tooling.

## Quick start

1. Make sure you have Docker, VS Code, the Dev Containers extension, and Git with worktree support.
2. Clone this repo or copy its `.devcontainer/` folder into your own repo.
3. Open a linked worktree in VS Code.
4. Reopen the folder in the container.
5. After the container is created, run:
   - `git status`
   - `git worktree list`
   - `git remote -v`

If those commands work, the core setup is in good shape.

## Repo map

- `.devcontainer/readme.md` explains how the template works and how to adapt it.
- `.devcontainer/devcontainer.json` contains the minimal worktree-ready container configuration.
- `concepts.md` explains the underlying model and why this setup works.
