# Git Worktrees + VS Code Dev Containers

**Run multiple AI coding agents in parallel, each on its own branch, each in its own containerized environment, without breaking Git.**

## The Problem

You're using AI agents to develop in parallel - testing different fixes, comparing refactoring approaches, or experimenting with dependency upgrades. You quickly hit three walls:

- **Branch isolation isn't enough**: Agent A needs Python 3.10, Agent B needs Python 3.12, Agent C is testing a dependency upgrade
- **Shared environments create chaos**: Runtime conflicts, package version collisions, broken shells, polluted caches
- **AI agents waste time fighting setup**: Instead of solving your actual task, they're debugging "works on my machine" environment issues

**What you need**: Branch isolation + environment isolation.

## The Solution

**Git worktrees** give each agent its own branch and folder.
**Dev Containers** give each branch its own containerized environment.

But there's a catch: **linked worktrees break inside Dev Containers by default**.

A linked worktree's `.git` is a file that points back to shared Git metadata in the main repository. VS Code normally mounts only the folder you open, so that path becomes unreachable inside the container. Result: `fatal: not a git repository`.

**This repository solves that compatibility issue.**

It provides a working `.devcontainer` configuration that:

- Mounts the shared parent directory (so the `.git` pointer stays valid)
- Configures Git's `safe.directory` to trust the worktree layout
- Works on macOS, Linux, and WSL

Copy the [.devcontainer](./.devcontainer) folder into your repository and you're ready to run multiple branches in parallel, each in its own isolated container.

## What You Get

This is a **template and reference implementation** where:

- Multiple branches are active simultaneously in separate folders
- Each branch runs in its own Dev Container with independent dependencies
- Git commands work correctly inside all containers
- The [.devcontainer](./.devcontainer) folder can be copied into your own repository

If you're orchestrating AI agents to try different approaches in parallel, this is the "separate branches + separate environments + working Git" pattern.

## Quick Start

**Two paths from here:**

### Path 1: "Help me understand the concepts"

→ Read this if you are new to Git worktrees, Dev Containers, or the integration challenge. It will give you the context you need to understand why this setup is necessary and how it works.

[concepts.md](./concepts.md) will cover:

- What Git worktrees are and how they work
- What Dev Containers are and how they isolate environments
- Why they don't work together by default
- How this repository's configuration solves the integration challenge
- When to use this pattern (and when not to)

### Path 2: "Show me how to set it up"

→ Read this if you just want to get up and running with the setup. It will give you step-by-step instructions to create the shared parent directory, generate linked worktrees, and open each in its own container.

[.devcontainer/readme.md](./.devcontainer/readme.md) will show you how to:

- Create the shared parent directory structure
- Generate linked worktrees for different branches
- Open each worktree in its own container
- Verify that Git works correctly

## Example Use Cases where this pattern shines

The combination of Git worktrees and Dev Containers demonstrated in this repository is ideal for scenarios where you want to run multiple branches in parallel, each with its own isolated environment. Here are some concrete examples:

**Scenario A: Testing Python version compatibility**

- Agent A works on a fix in Python 3.10 (worktree `python-310-fix/`)
- Agent B tests the same fix in Python 3.12 (worktree `python-312-fix/`)
- Each container uses a different base image, no conflicts

**Scenario B: Comparing refactoring approaches**

- Agent A tries a safe, incremental refactor (worktree `safe-refactor/`)
- Agent B attempts a bold rewrite (worktree `bold-rewrite/`)
- You review both in parallel, merge the winner

**Scenario C: Dependency upgrade testing**

- Agent A maintains stable dependencies (worktree `stable-deps/`)
- Agent B tests an upgrade (worktree `upgrade-test/`)
- Containers have different `package.json` or `requirements.txt`, no interference
