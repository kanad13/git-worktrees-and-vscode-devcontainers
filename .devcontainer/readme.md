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

Why have this flexibility? Some projects may want to maintain separate dependency lists for development (in the container) vs production (in the project root). This setup allows you to choose which files are used without breaking the container build.

## Keeping Files "Empty"

If you don't need specific Python or Node packages for a project, do not delete the files. Instead:

- `requirements.txt`: Leave it empty or keep a "dummy" package like `cowsay`.
- `package.json`: Keep the basic structure `{ "name": "...", "dependencies": {} }`.
- **Why?** The `devcontainer.json` expects these files to exist to complete the build. If they are missing, the build will fail.

## Git Worktree Support

### What is a worktree?

A Git worktree lets you check out multiple branches simultaneously, each in its own folder, all sharing one set of `.git` metadata from a single "main" repository.

This is the typical structure when using worktrees:

```ascii
parent-folder/
  ├── my-repo/          ← main repository
  │   ├── src/
  │   ├── .git/         ← directory containing all metadata and history
  │   └── ...
  └── feature-branch/   ← worktree
      ├── src/
      ├── .git          ← FILE pointing to ../my-repo/.git
      └── ...
```

Notice how the `.git` in `feature-branch` is not a directory but a **file** that contains a reference to the main repo's `.git` directory. This allows all branches to share the same history and metadata while being checked out in separate folders.

This structure allows you to work on multiple branches simultaneously. Each AI agent can work in its own folder without interfering with others, even though they all share the same underlying git repository.

## VSCode DevContainers

### What is a Dev Container?

DevContainers are a feature of Visual Studio Code that allows you to develop inside a Docker container. This means you can have a consistent development environment across different machines, with all the necessary tools and dependencies pre-installed in the container. When you open a folder in VS Code that contains a `.devcontainer` folder, VS Code will automatically build the container based on the configuration and open the folder inside that container. This is especially useful for projects that require specific versions of tools or libraries, as it ensures that everyone working on the project has the same environment.

This makes Dev Containers a great fit for AI agents, as it allows you to create a self-contained environment with all the necessary tools and dependencies for the agent to function properly. You can also easily share this environment with others by sharing the `.devcontainer` folder and related configuration files.

### The worktree compatibility challenge

Worktrees and Dev Containers are both powerful tools for managing development environments, but they can have compatibility issues if not configured correctly. The main issue arises because worktrees rely on the `.git` file pointing to the main repository's `.git` directory, and if the container does not have access to that directory, git commands will fail.

From the host machine, you might have a folder structure like this:

```ascii
parent-folder/
  ├── my-repo/       ← main repository with .git/ directory
  └── feature-task/  ← worktree you open in VS Code
```

When VS Code opens the worktree (`feature-task`) in a container, it mounts only that folder by default — **not** the parent directory or the main repo. Git reads the `.git` file in `feature-task`, finds an absolute host path pointing to `my-repo/.git`, tries to follow it, and fails because that path doesn't exist inside the container. Every git command then fails with:

```
fatal: not a git repository (or any of the parent directories): .git
```

### How this repo's `devcontainer.json` solves the issue

This configuration mounts the **entire parent directory** into the container at the same absolute path it has on the host. This means:

- Both the worktree (the folder you open in VS Code) and the main repository are accessible at their expected absolute paths
- Git can follow the path in the `.git` file and find the repository metadata
- This works automatically regardless of what you name your repository folder or worktrees
- It supports GitHub, SSH, and HTTPS remotes out of the box

The `postCreateCommand` marks the parent directory as `safe.directory` in git. This is required because Docker bind-mounts may appear owned by `root` inside the container, and git refuses to operate in directories owned by a different user than the current one.

### Adapting this config

| Scenario                              | What to change                                                                                                                                                                                       |
| ------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Using GitHub/SSH/HTTPS remotes**    | No changes needed. This config works out of the box.                                                                                                                                                 |
| **Worktrees not in parent directory** | If your worktrees are in a different location (not siblings), you'll need to adjust the mount path in `devcontainer.json` to point to the correct parent directory.                                  |
| **Windows users**                     | The configuration works cross-platform, but ensure Docker Desktop and WSL2 (if applicable) are properly configured. The `${localWorkspaceFolder}` variable automatically converts paths for your OS. |
| **Need additional mounts**            | Add more mount entries to the `mounts` array if you need to access other directories on your host machine.                                                                                           |

## The "All Good" Test

Upon a successful build, the `welcome.sh` script runs automatically. It uses `figlet` (Node) and `cowsay` (Python) to print a confirmation banner in your terminal. If you see the **"READY!"** banner, your environment is fully functional.
