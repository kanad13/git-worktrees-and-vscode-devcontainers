# Git Worktrees + VS Code Dev Containers

With the rise of AI coding agents, many developers want to run multiple agents on the same codebase trying out different branches or tasks in parallel.
Since Git allows you to only have one active branch checked out at a time, this can be tricky. How can you have multiple agents running on the same repository, if only one branch can be active?
Git Worktrees are the answer. They let you have multiple checkouts of the same repository, each on a different branch, without interfering with each other. Each worktree is like a separate workspace that shares the same Git history but has its own HEAD and index.

Here comes the second challenge: Each branch needs its own environment, e.g. one branch has a Python 3.10 setup with a certain set of dependencies, libraries, and tools, while another branch has a different setup. This is where VS Code Dev Containers come in. They allow you to create isolated development environments that can be customized for each worktree.

What that means in practice is:

- You have one git repository with multiple branches.
- You create a worktree for each branch.
- You plug each worktree into its own Dev Container.
- You let each AI agent run in its own container, working on its own branch, without stepping on each other.
- You can switch between worktrees and containers as needed, while keeping your main checkout clean and available for foreground work.

This repo is a template for that workflow. It solves the two main pain points that usually come up when trying to set this up:

- VS Code Dev Containers and Git worktrees don't play well together out of the box, because the worktree's `.git` file points to a path that is not mounted inside the container. This repo includes a mount strategy and Git configuration to fix that.
- without a template, setting up multiple worktrees and containers can be a manual and error-prone process. This repo provides copy-paste commands and a clear structure to make it easy to create and manage multiple worktrees and containers for your AI agents.

You have 2 ways to use this repo:

1. Copy the `.devcontainer` folder into your existing repository and follow the instructions to set up your worktrees and containers.
2. Use this repo as a starting point for a new project, and customize it as needed.

## Where to go next

- [concepts.md](./concepts.md) explains the underlying concepts of Git worktrees and VS Code Dev Containers, and how they interact with each other.
- [`.devcontainer/readme.md`](./.devcontainer/readme.md) provides step-by-step instructions on how to set up and use the worktree-ready Dev Container configuration in this repo.
