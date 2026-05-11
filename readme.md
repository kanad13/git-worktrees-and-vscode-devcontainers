# Git Worktrees + VS Code Dev Containers

This repository shows how to run multiple Git worktrees inside VS Code Dev Containers without breaking Git commands. This is useful for modern AI-assisted development workflows where you want to let each AI code agent develop or fix issues in parallel on different branches, and you want each branch to have its own containerized environment with its own dependencies.

Check out [concepts.md](./concepts.md) for a deeper dive into the underlying concepts and why this combination is powerful for AI-assisted workflows.

You can copy the [.devcontainer setup](./.devcontainer) into your own repository and follow the setup instructions in [.devcontainer/readme.md](./.devcontainer/readme.md) to create worktrees and adapt it to your existing layout.
