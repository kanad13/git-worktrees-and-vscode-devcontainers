# Need for "Git Worktree" + "Dev Container" Workflow

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

At that point, **branch isolation** is not enough. You also need **environment isolation**.

This repository shows how to combine **Git worktrees** with **VS Code Dev Containers** to achieve exactly that: multiple branches, each in its own containerized environment, all without breaking Git commands. The special sauce is a fix for the compatibility issue that normally appears when you try to use linked worktrees inside containers. [This section or portion needs to be improved to make the message clearer about what special problem does the repo solve and how it solves it. The current wording is a bit vague and doesn't clearly state the problem or the solution. It should be more explicit about the issue with linked worktrees in containers and how the repository addresses that issue.]

To make use of the repository, you can copy the `.devcontainer` folder into your own repository and follow the setup instructions in `.devcontainer/readme.md` to create worktrees and adapt it to your existing layout.

Alternatively, you can continue reading for a deeper dive into the concepts, trade-offs, and example use cases for this workflow in [concepts.md](./concepts.md).

## TL;DR

This repository is a **template and reference implementation** for a workflow where:

- multiple branches are active in parallel
- each branch can have its own Dev Container and dependency choices
- linked Git worktrees still function correctly inside VS Code containers
- the `.devcontainer` folder can be copied into another repository that uses the same shared-parent layout

If you are using AI agents to try different approaches in parallel, this is the “separate branches + separate environments + sane setup” pattern.

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
