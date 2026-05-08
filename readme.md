# Git Worktrees + VS Code Dev Containers

A zero-configuration template for running multiple AI agents in parallel, each working on a different branch in its own isolated environment.

## The Problem

AI coding agents need to work on multiple branches simultaneously. Git only allows one active branch per repository checkout, and each branch may need its own environment setup. How do you run multiple agents in parallel without conflicts?

## The Solution

**Git Worktrees** let you check out multiple branches simultaneously in separate folders. **VS Code Dev Containers** provide isolated, reproducible environments for each branch. This template combines both, pre-configured to work together seamlessly.

## Quick Start

- **Prerequisites:**
  - Git
  - VS Code with the [Dev Containers extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers)
  - Docker
- **Steps:**
  - **Clone this repository** (or copy `.devcontainer` into your existing project)
  - **Open in VS Code** with the Dev Containers extension
  - **Create worktrees** as needed: `git worktree add ../feature-branch-name`
  - **Open each worktree** in a new VS Code window — each gets its own container automatically

No configuration needed. The template handles the complexity of mounting and path resolution automatically.

## Two Usage Patterns

- **Copy `.devcontainer` into your project:** Drop the configuration into any existing repository to make it worktree-ready
- **Use as a starting point:** Clone this repo and build your project on top of the pre-configured structure

## Learn More

- **[concepts.md](./concepts.md)** — Understand how Git worktrees and Dev Containers work together, and why this matters for AI agents
- **[.devcontainer/readme.md](./.devcontainer/readme.md)** — Technical reference for customizing the configuration
