# Dev Container Template: Markdown + Python + Node

This folder contains the configuration for a VS Code Dev Container. It is designed as a "portable environment" that can be dropped into any project to provide a consistent workspace with Python, Node.js, and Markdown tools.

## File Map & Purpose

| File                | Purpose                                                                    | Why it's here                                                                                                                                               |
| ------------------- | -------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `devcontainer.json` | The Brain. Configures VS Code settings, extensions, and the build process. | It orchestrates how the container starts and what extensions are pre-installed.                                                                             |
| `Dockerfile`        | The Skeleton. Defines the OS-level environment.                            | Uses the Ubuntu base image (`mcr.microsoft.com/devcontainers/base:ubuntu`). Add `apt-get install` commands here for OS-level tools like `tree` or `pandoc`. |
| `package.json`      | Node/JS Deps. Manages Node.js utilities.                                   | Used for JS-based tools (e.g., `figlet` for banners, `prettier` for formatting).                                                                            |
| `requirements.txt`  | Python Deps. Manages Python libraries.                                     | Used for Python-based logic (e.g., `cowsay`, `pandas`, or automation scripts).                                                                              |
| `welcome.sh`        | Health Check. A script that runs once the container is ready.              | It visually confirms the shell, Node, and Python are all working correctly.                                                                                 |

## Updating Dependencies

- **Python:** Add new libraries to `.devcontainer/requirements.txt`.
- **Node.js:** Add new packages to `.devcontainer/package.json`.
- **System/OS:** Add `apt-get install` commands to the `Dockerfile`.
- **Note:** After changing these files, run the command **Dev Containers: Rebuild Container** to apply changes.

## Using with Project-Root Files

If your project already has a `requirements.txt` or `package.json` in the root folder, you have two choices:

1. **Project Files take precedence:** Keep your project-root files and delete the contents of `.devcontainer/requirements.txt` and `.devcontainer/package.json`.
2. **Dev Container Files take precedence:** Keep the `.devcontainer` files as the source of truth and remove or ignore the project-root files.

## Keeping Files "Empty"

If you don't need specific Python or Node packages for a project, do not delete the files. Instead:

- `requirements.txt`: Leave it empty or keep a "dummy" package like `cowsay`.
- `package.json`: Keep the basic structure `{ "name": "...", "dependencies": {} }`.
- **Why?** The `devcontainer.json` expects these files to exist to complete the build. If they are missing, the build will fail.

## Git Worktree Support

### What is a worktree?

A Git worktree lets you check out multiple branches simultaneously, each in its own folder, all sharing one set of `.git` metadata from a single "main" repository:

```
repos/
  working/    ← main repo — contains the real .git/ directory and all metadata
  backup/     ← worktree — contains a .git FILE (not a folder), not a full repo
```

Inside the worktree, `.git` is a plain text file whose contents look like:

```
gitdir: /Users/you/repos/working/.git/worktrees/backup
```

### Why Dev Containers break with worktrees

When VS Code opens a worktree in a container it mounts the worktree folder — but **not** the main repo. Git reads the `.git` file, finds the absolute host path `/Users/you/repos/working/...`, tries to follow it, and fails because that path doesn't exist inside the container. Every git command then fails with:

```
fatal: not a git repository (or any of the parent directories): .git
```

### How this config fixes it

The `mounts` block in `devcontainer.json` bind-mounts the main repo into the container **at the exact same absolute path it has on the host** (side-by-side with the worktree). This makes the path inside the `.git` file valid, restoring full git functionality.

A second mount handles local filesystem remotes. When `git remote -v` shows a local path (e.g. `/Users/you/remotes/Back-Working`) rather than a GitHub URL, that path must also exist inside the container — otherwise `git fetch`, `push`, and `pull` fail with the same "does not appear to be a git repository" error. This does **not** apply to GitHub, SSH (`git@github.com:...`), or HTTPS remotes, which connect over the network and need no mounts.

The `postCreateCommand` marks all three mounted directories as `safe.directory` in git. This is required because Docker bind-mounts may appear owned by `root` inside the container, and git refuses to operate in directories owned by a different user than the current one.

### Adapting this config

| Scenario                              | What to change                                                                                                                                               |
| ------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **Regular repo (no worktree)**        | Delete the `mounts` block entirely, and remove the second and third `safe.directory` lines from `postCreateCommand`                                          |
| **Main repo has a different name**    | Replace both occurrences of `working` in the first mount entry, and in the second `safe.directory` command in `postCreateCommand`                            |
| **Folders are not side-by-side**      | Update the `../working` relative paths in both places in the first mount entry to reflect the actual layout on disk                                          |
| **Remote is a local filesystem path** | Add a mount for the remotes directory and a `safe.directory` for the bare repo — see the second mount entry and third `safe.directory` in the current config |
| **Remote is on GitHub / SSH / HTTPS** | No additional mounts needed. Remove the second mount entry and the third `safe.directory` line from `postCreateCommand` if they are present                  |

## The "All Good" Test

Upon a successful build, the `welcome.sh` script runs automatically. It uses `figlet` (Node) and `cowsay` (Python) to print a confirmation banner in your terminal. If you see the **"READY!"** banner, your environment is fully functional.
