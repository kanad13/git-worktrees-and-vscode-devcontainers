# Git Worktrees + VS Code Dev Containers

If you are using AI coding agents, the next bottleneck is usually not code generation. It is coordination.

One agent can take over your checkout. Two or three agents start colliding with your files, tools, and runtime. Git worktrees help with file isolation. Dev Containers help with environment isolation. But when you combine them, Git often breaks inside the container because a linked worktree's `.git` file points back to the main repo on the host.

This repository solves that problem.

It gives you a minimal, clonable setup that makes linked Git worktrees behave correctly inside VS Code Dev Containers so multiple AI agents can work on the same repo in parallel, each on its own branch and in its own environment.

## Start here

- Want the fast overview? Keep reading this file.
- Want the mental model? Read [concepts.md](./concepts.md).
- Want to adapt just the template? Read [`.devcontainer/readme.md`](./.devcontainer/readme.md).
- Want to create your first worktrees now? Jump to [Create your first worktrees](#create-your-first-worktrees).

## What problem this solves

Without this pattern, AI-agent workflows usually run into one or more of these problems:

- an agent and a human are editing the same checkout
- multiple agents step on each other's changes
- one task's setup or test run pollutes another task's environment
- Git commands fail inside a worktree-based Dev Container because the main repo path is missing

This repo is an enabler for the whole workflow: Git worktrees give you parallel branches, Dev Containers give you isolated environments, and the template here removes the Git-in-container breakage that usually stops the pattern from feeling reliable.

## What you get from this repo

- a minimal `.devcontainer` folder you can copy into another repo
- a default mount strategy for the common side-by-side worktree layout
- automatic Git `safe.directory` registration for the current workspace, the main repo, and visible local-path remotes
- a practical setup for running multiple AI agents on separate branches and separate worktrees
- copy-paste commands for creating worktrees from new or existing branches

## How the workflow looks

In a typical setup:

- your main checkout stays available for your foreground work
- worktree A is opened in its own Dev Container for agent A
- worktree B is opened in its own Dev Container for agent B
- each worktree uses a different branch, but all of them share the same repo history

That is the core value of this repo: parallel agent work without turning your main repo into a demolition site.

## Why the repo does not ship with pre-created worktrees

I do not think this repo should include committed worktrees or a pile of permanent demo branches.

Why:

- worktrees are local checkout state, not reusable repository content
- pre-created branches in a template repo become noisy and artificial very quickly
- what people actually need is a clean way to create worktrees from their own branch strategy

So instead of shipping fake worktrees, this repo should make the creation flow obvious and easy.

## Create your first worktrees

From your main repo, create one worktree per agent or task.

### New branches

If you want each worktree to start on a new branch:

```bash
git worktree add ../my-repo-agent-a -b agent-a main
git worktree add ../my-repo-agent-b -b agent-b main
```

### Existing branches

If the branch already exists:

```bash
git worktree add ../my-repo-bugfix bugfix-123
```

Then for each worktree:

1. Open the worktree folder in VS Code.
2. Run **Dev Containers: Reopen in Container**.
3. Verify:
   - `git status`
   - `git worktree list`
   - `git remote -v`

If those commands work, the core setup is in good shape.

## Two ways to use this repo

### Clone the repo

Use this repo as a working reference and adapt the parts you need.

### Copy only `.devcontainer/`

If you already have a repo, copy the `.devcontainer/` folder into it and adapt only the parts that depend on your folder layout or AI tooling.

## Where to go next

- [concepts.md](./concepts.md) explains why worktrees and Dev Containers fit together for agentic workflows.
- [`.devcontainer/readme.md`](./.devcontainer/readme.md) explains how to adapt the template to your own repo layout.
- [`.devcontainer/devcontainer.json`](./.devcontainer/devcontainer.json) contains the minimal worktree-ready container configuration.
