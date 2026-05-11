# Need for "Git Worktree" + "Dev Container" Workflow

Many developers now want to run **multiple AI coding agents in parallel**, each trying a different fix, refactor, or experiment on its own branch.

That is exactly where **Git worktrees** shine. They let you check out multiple branches of the same repository at the same time in separate folders without cloning the repo over and over.

But here is the part that matters even more in real-world AI workflows:

- one branch might need **Python 3.10**
- another branch might need **Python 3.12**
- one experiment might upgrade a package
- another might intentionally stay pinned to the old dependency set

At that point, branch isolation is not enough. You also need **environment isolation**.

That is why this repository combines **Git worktrees** with **VS Code Dev Containers** — and why it includes a specific fix for the annoying compatibility issue that appears when you try to use linked worktrees inside containers.

If you want the deep dive, start with the main repo docs:

- [Repository overview and quick start](./readme.md)
- [Concepts and trade-offs](./concepts.md)
- [Technical reference for the Dev Container setup](./.devcontainer/readme.md)

## TL;DR

This repository is a **template and reference implementation** for a workflow where:

- multiple branches are active in parallel
- each branch can have its own Dev Container and dependency choices
- linked Git worktrees still function correctly inside VS Code containers
- a helper script can set up the recommended shared-parent layout and create worktrees for you

If you are using AI agents to try different approaches in parallel, this is the “separate branches + separate environments + sane setup” pattern.

## The modern problem: AI agents are parallel, but your dev environment usually is not

A lot of teams are experimenting with AI coding agents for tasks like:

- trying two or three possible bug fixes in parallel
- testing a safe refactor versus a bolder rewrite
- comparing dependency upgrades on separate branches
- splitting several small tickets across multiple agents

The obvious first step is to give each agent its own branch. That prevents code edits from colliding.

But once those branches need different environments, things get messy fast.

For example:

- Agent A is testing a fix on **Python 3.10**
- Agent B is testing the same fix on **Python 3.12**
- Agent C is trying a dependency upgrade that changes package resolution

If all of that happens in one local environment, you get exactly the kind of chaos you would expect:

- runtime conflicts
- package version conflicts
- broken shells and polluted caches
- “works on my machine” nonsense
- AI agents wasting time fixing setup instead of solving the actual task

## Why Git worktrees are the right foundation

Git worktrees let you have multiple branches of the same repository checked out simultaneously in separate folders.

That means you can have:

- `bugfix-a/`
- `experiment-b/`
- `dependency-upgrade/`

all active at the same time, all backed by the same repository history, without cloning the repo three times.

That makes worktrees a great fit for:

- AI agent workflows
- parallel human development
- testing multiple ideas side by side
- keeping task boundaries explicit

Compared with multiple full clones, worktrees are lighter, cleaner, and easier to manage.

## Why worktrees alone are not enough

Worktrees isolate the **code checkout**. They do not isolate the **runtime environment**.

That distinction matters.

If one branch needs a different Python version, different Node version, or different dependency tree, separate folders are not enough. You also need separate environments.

That is where **VS Code Dev Containers** become powerful.

Each worktree can be opened in its own container, which means each branch can carry its own:

- language version
- package set
- tooling stack
- editor extensions
- process sandbox

This is the real selling point for modern AI-assisted workflows:

> Git worktrees give each agent its own branch and folder. Dev Containers give each branch its own environment.

## The catch: linked worktrees often break inside Dev Containers

There is a hidden compatibility issue here.

In a linked worktree, `.git` is usually not a full directory. It is a small file that points back to Git admin data owned by the main repository.

VS Code, however, normally mounts only the folder you open into the container.

So if you open a linked worktree in a container, the path referenced by `.git` may no longer exist inside that container. That is how you get errors like:

```text
fatal: not a git repository
```

This is the exact problem the repository solves.

## What this repository gives you

This repo packages the workflow into something reusable.

### 1. A reusable Dev Container fix for linked worktrees

The `.devcontainer` configuration bind-mounts the **shared parent directory** into the container at the same path it has on the host.

That keeps the linked worktree's `.git` pointer valid inside the container, so Git can still find the metadata it needs.

If you want the implementation details, see the [Dev Container technical reference](./.devcontainer/readme.md).

### 2. A host-side setup script for the recommended layout

The repository includes [`.devcontainer/setup-worktrees.sh`](./.devcontainer/setup-worktrees.sh), which can:

- choose or create the shared parent directory
- move the main repository into that layout if needed
- create multiple branches and linked worktrees in one pass
- optionally open each worktree in VS Code

That makes the “happy path” much easier to adopt.

### 3. A documented mental model you can copy into your own repo

This is not just a config dump. The repository also explains:

- why the shared-parent layout matters
- why Git `safe.directory` has to be handled carefully
- what trade-offs the approach makes
- when you should or should not use it
