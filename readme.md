## Git Worktrees + VS Code Dev Containers: The Ultimate AI Coding Workflow

## The Orchestrator: Git Worktrees + Dev Containers

This repository demonstrates the "Multi-Agent" workflow for modern development. By combining Git Worktrees for code isolation and VS Code Dev Containers for environment isolation, we solve the primary friction point of AI-driven development: `Parallelism without Pollution`.

## The Problem: The "One-at-a-Time" Bottleneck

When you ask an AI agent to fix a bug or implement a feature, it takes over your development environment.
Normally, your code lives in one folder. If you ask an AI agent to fix a bug, it takes over that folder. While the AI is working:

- You can't code: If you try to write code at the same time, you'll clash with the AI.
- Your tools are busy: The AI might be running tests or installing packages, making your computer slow or "freezing" your ability to run your own tests.
- You’re stuck waiting: You have to sit and watch the AI finish before you can switch back to your own work.

## The Solution: "Parallel Sandboxing"

This repo shows you how to use Git Worktrees and Dev Containers to create separate "rooms" for your work:

1.  The Worktree gives the AI its own copy of the code in a new folder. You keep your main folder exactly how you like it.
2.  The Dev Container gives the AI its own virtual computer. It can install things and run heavy tests in the background without slowing down your machine.

Result: You can keep building Feature A while three different AI agents are fixing bugs in the background. It turns your development process from a single-lane road into a multi-lane highway.

## What's Inside

- `[Working devcontainer](./.devcontainer)` A production-ready Dev Container specification that auto-installs Git, Docker-in-Docker, and common AI CLI tools.
- `[Explanation of concepts](./concepts.md)`: In-depth explainers on [Git Worktree architecture](https://git-scm.com/docs/git-worktree) and containerized workflows.

## Getting Started

### 1. Prerequisites

Ensure you have [Docker Desktop](https://www.docker.com/products/docker-desktop/) and [VS Code](https://code.visualstudio.com/) with the [Dev Containers extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers) installed.

### 2. Clone the Repository

```bash
git clone https://github.com/kanad13/git-worktrees-and-vscode-devcontainers.git
```

### 3. Open in VS Code

Open the cloned folder in VS Code, then use the Command Palette to select **Dev Containers: Reopen in Container**. This will build the Dev Container and open your project inside it.

[More steps pending]
