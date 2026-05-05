# Why Git Worktrees and Dev Containers fit together for AI coding workflows

If you are reading this repo for the first time, start with [readme.md](./readme.md) for the practical pitch and setup flow. If you already know why you care and only want to adapt the template, go to [`.devcontainer/readme.md`](./.devcontainer/readme.md).

## Why this pattern exists

AI-assisted workflows get better when each task has its own checkout and its own environment. A worktree gives you file isolation. A Dev Container gives you environment isolation. Put them together and you can keep your main setup steady while a second task runs elsewhere.

## What a Git worktree gives you

A Git repo can have one main worktree and additional linked worktrees.

- The directories are separate.
- The commit history and refs are shared.
- Each worktree has its own checked-out branch or detached `HEAD`.
- A branch can only be checked out in one worktree at a time.

Why this matters:

- you can do parallel work without stashing and switching
- AI agents can edit a separate checkout instead of stepping on your current files
- worktrees are lighter than cloning the same repo repeatedly

## What a Dev Container gives you

A Dev Container is a containerized development environment described by `.devcontainer/devcontainer.json`.

Why this matters:

- VS Code opens the repo with a predictable tool environment
- agents and humans can work inside the same declared setup
- the host machine stays cleaner because project-specific tooling lives in the container

## Where they clash

A linked worktree is not a fully standalone repo. Its `.git` entry is usually a file that points back to metadata stored in the main repo.

That is the part that breaks inside a container.

VS Code mounts the folder you opened as the workspace. It does not automatically mount every other host path referenced by Git metadata. If the main repo path from the worktree's `.git` file is missing inside the container, Git commands fail even though the folder itself opened correctly.

The same issue can show up with local filesystem remotes. If `git remote -v` points to a path on disk instead of SSH or HTTPS, that path also has to exist inside the container.

## How this repo handles it

This repo keeps the fix simple:

1. Mount a host directory that contains both the current worktree and the main repo at the same absolute path inside the container.
2. If you use a local filesystem remote outside that shared parent directory, add another mount for it.
3. Register Git `safe.directory` entries for the workspace, the detected main repo, and any visible local-path remotes.

This is enough to make the common linked-worktree case work without bundling unrelated language runtimes or project dependencies.
