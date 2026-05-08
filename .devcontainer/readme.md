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

This Dev Container configuration is designed to work seamlessly with Git worktrees. For conceptual background on what worktrees are and why they're useful for AI agents, see [concepts.md](../concepts.md).

### How Worktrees and Dev Containers Interact

Worktrees and Dev Containers have a compatibility challenge: a worktree's `.git` file contains an absolute path pointing to the main repository's `.git` directory. When VS Code opens a worktree in a container, it only mounts the worktree folder by default—not the parent directory or main repository. This causes git commands to fail because the container can't access the path referenced in the `.git` file.

**Error you'd see without proper configuration:**

```
fatal: not a git repository (or any of the parent directories): .git
```

### How this repo's `devcontainer.json` solves the issue

This configuration mounts the **entire parent directory** into the container at the same absolute path it has on the host. This means:

- Both the worktree (the folder you open in VS Code) and the main repository are accessible at their expected absolute paths
- Git can follow the path in the `.git` file and find the repository metadata
- This works automatically regardless of what you name your repository folder or worktrees
- It supports GitHub, SSH, and HTTPS remotes out of the box

**Technical implementation:**

```json
"mounts": [
  "source=${localWorkspaceFolder}/..,target=${localWorkspaceFolder}/..,type=bind,consistency=cached"
]
```

The `postCreateCommand` marks the parent directory as `safe.directory` in git. This is required because Docker bind-mounts may appear owned by `root` inside the container, and git refuses to operate in directories owned by a different user.

### Adapting this config

| Scenario                              | What to change                                                                                                                                                                                       |
| ------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Using GitHub/SSH/HTTPS remotes**    | No changes needed. This config works out of the box.                                                                                                                                                 |
| **Worktrees not in parent directory** | If your worktrees are in a different location (not siblings), you'll need to adjust the mount path in `devcontainer.json` to point to the correct parent directory.                                  |
| **Windows users**                     | The configuration works cross-platform, but ensure Docker Desktop and WSL2 (if applicable) are properly configured. The `${localWorkspaceFolder}` variable automatically converts paths for your OS. |
| **Need additional mounts**            | Add more mount entries to the `mounts` array if you need to access other directories on your host machine.                                                                                           |

## The "All Good" Test

Upon a successful build, the `welcome.sh` script runs automatically. It uses `figlet` (Node) and `cowsay` (Python) to print a confirmation banner in your terminal. If you see the **"READY!"** banner, your environment is fully functional.
