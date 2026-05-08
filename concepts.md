# Concepts: Worktrees and Dev Containers for AI Agents

## Git Worktrees: The "Multithreading" Feature for AI Agents

Git worktrees are a built-in feature of Git that allows you to have multiple branches of the same repository checked out simultaneously in separate folders. This enables you to run multiple AI agents in parallel without them interfering with each other.

### What is a Git Worktree?

Normally, a single repository has one "working tree" (your project folder). To switch tasks, you have to `git stash` or commit your work and then `git checkout` a new branch. A worktree lets you "multithread" your repo:

- **Shared History:** All worktrees share the same `.git` folder and commit history.
- **Isolated Folders:** Each worktree lives in its own directory on your machine.
- **Multiple Active Branches:** You can have `feature-A` open in one folder and `bugfix-B` in another at the exact same time.

Here's how the folder structure looks:

```ascii
parent-folder/
  ├── my-project/      ← main repository
  │   ├── src/
  │   ├── .git/        ← directory with all git metadata and history
  │   └── .devcontainer/
  └── feature-fix/     ← worktree
      ├── src/
      └── .git         ← FILE (not directory) pointing to ../my-project/.git
```

Notice that `.git` in the worktree is a **file** (not a directory) containing a reference to the main repository's `.git` directory. This allows all branches to share the same history while being checked out in separate folders.

### Why the AI Hype?

- The rise of "Agentic AI" (tools like [Claude Code](https://code.claude.com/docs/en/common-workflows#run-parallel-sessions-with-worktrees), or [OpenAI's Codex](https://developers.openai.com/codex/app/worktrees)) has made worktrees a necessity for three main reasons:
  - `1. True Parallelism:` AI agents often take minutes to reason and write code. If you run an agent in your main directory, you are "locked out" until it finishes. With worktrees, you can spin up 3–5 agents in separate folders, each working on a different ticket simultaneously.
  - `2. Conflict Prevention:` If two agents work in the same folder, they might overwrite each other's changes mid-edit or pollute each other's context. Worktrees provide a "sandbox" for each agent to safely "break things" in isolation.
  - `3. Efficiency over Clones:` You could just clone the repo 5 times, but that wastes massive disk space and requires you to git fetch in every single copy. Worktrees are lightweight and stay perfectly synced with your main repo.

## VS Code Dev Containers

VS Code Dev Containers take the idea of a "sandbox" even further than Git worktrees. While a worktree isolates your code, a Dev Container isolates your entire development environment—including the OS, compilers, tools, and extensions—using Docker.

### What is a Dev Container?

Think of it as **"Environment as Code."** Instead of asking a teammate to "install Node 18, Python 3.10, and the ESLint extension," you commit a `.devcontainer` folder to your repo. When you open that folder in [Visual Studio Code](https://code.visualstudio.com/docs/devcontainers/containers), it:

- Spins up a Docker container with the exact versions of everything you need
- Mounts your project files into that container
- Automatically installs the VS Code extensions required for that project

### Why are Dev Containers useful?

- **Zero Onboarding:** New developers (or agents) can start coding in seconds without installing anything locally besides [Docker](https://www.docker.com/products/docker-desktop/) and [VS Code](https://code.visualstudio.com/download)
- **"Works on My Machine" is Dead:** Since everyone uses the same container image, you eliminate bugs caused by different OS versions or missing libraries
- **Clean Host Machine:** You don't have to clutter your personal laptop with 20 different versions of Java or Ruby; everything stays inside the container

## The "Golden Combo": Worktrees + Dev Containers for AI

When you combine [Git worktrees](https://git-scm.com/docs/git-worktree) with [Dev Containers](https://containers.dev/), you unlock a professional Agentic Development workflow that solves the "Messy Agent" problem:

### 1. Total Isolation (Code + Runtime)

**The Problem:**

- A worktree gives an AI agent its own folder so it won't overwrite your files.
- But if that agent runs a test that clears a database or starts a web server on port 3000, it might still crash your local environment.

**The Fix:**

- If each worktree also has its own Dev Container, the agent gets a private virtual machine.
- It can delete databases, install weird packages, and crash its own server without ever touching your host machine or your other active tasks.

### 2. Parallel Problem Solving

- You can act as a "conductor" for an army of agents:
  - Worktree A + Container 1: Agent A is refactoring the backend in a Node 20 environment.
  - Worktree B + Container 2: Agent B is fixing a UI bug in a React environment.
  - Your Main Folder: You are writing a new feature on your local machine.
- All three run at the same time, sharing history but nothing else.

### 3. Deterministic Results

**The Problem:**

- AI agents are notoriously sensitive to their environment.
- If an agent tries to run code and fails because a library is missing, it might waste $5 of API credits trying to "fix" the environment instead of the code.

**The Fix:**

- Dev Containers ensure the agent always starts in a perfectly configured state, making its actions much more predictable and cost-effective.

## The Technical Challenge (And How This Template Solves It)

### The Problem

Making Git worktrees work with Dev Containers is technically challenging:

- A worktree's `.git` file contains an **absolute path** pointing to the main repository's `.git` directory
- When VS Code opens a worktree in a container, it only mounts that worktree folder by default
- The `.git` file references a path on the host machine that doesn't exist inside the container
- Every git command fails: `fatal: not a git repository`

### The Solution (Already Implemented)

This template solves the problem by **mounting the entire parent directory** into the container at the same absolute path it has on the host. This ensures:

- Both the worktree and the main repository are accessible at their expected paths
- Git can follow the path in the `.git` file and find the repository metadata
- It works automatically regardless of what you name your folders
- It supports GitHub, SSH, and HTTPS remotes out of the box
- **It works on Windows, macOS, and Linux** — VS Code's `${localWorkspaceFolder}` variable automatically converts paths for your OS

You don't need to configure anything. Just clone the repository, open it in VS Code with the [Dev Containers extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers), and start creating worktrees.

For technical details about the mount strategy and customization options, see [`.devcontainer/readme.md`](./.devcontainer/readme.md).
