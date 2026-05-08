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
This is how a typical repo with several branches looks like:

```ascii
repository_folder/
  main_branch/
    foo.py
    .git/       ← contains all metadata and history for the entire repo
  branch_1/
    bar.py
    .git        ← a FILE that points to the main repo's .git, not a full repo
  branch_2/
    baz.py
    .git        ← a FILE that points to the main repo's .git, not a full repo
```

In this example, `main_branch_folder` is the main repo, and without the worktree feature, you would have to switch branches in-place, which can be disruptive. With worktrees, you can have `branch_1_folder` and `branch_2_folder` as separate folders that are checked out to different branches, but they all share the same `.git` metadata from `main_branch_folder`.

```ascii
repository_folder/
  main_branch_folder/
    foo.py
    .git/       ← contains all metadata and history for the entire repo
  branch_1_folder/
    bar.py
    .git        ← a FILE that points to the main repo's .git, not a full repo
  branch_2_folder/
    baz.py
    .git        ← a FILE that points to the main repo's .git, not a full repo
```

Notice above how the `.git` in `branch_1_folder` and `branch_2_folder` is not a directory but a file that contains a reference to the main repo's `.git` directory. This allows all branches to share the same history and metadata while being checked out in separate folders.
This also allows you to work on multiple branches at the same time since the AI agents treat each folder as a separate workspace, even though they all share the same underlying git repository.

## VSCode DevContainers

### What is a Dev Container?

DevContainers are a feature of Visual Studio Code that allows you to develop inside a Docker container. This means you can have a consistent development environment across different machines, with all the necessary tools and dependencies pre-installed in the container. When you open a folder in VS Code that contains a `devcontainer.json` file, VS Code will automatically build the container based on the configuration and open the folder inside that container. This is especially useful for projects that require specific versions of tools or libraries, as it ensures that everyone working on the project has the same environment.

This makes Dev Containers a great fit for AI agents, as it allows you to create a self-contained environment with all the necessary tools and dependencies for the agent to function properly. You can also easily share this environment with others by sharing the `devcontainer.json` and related configuration files.

Worktrees and Dev Containers are both powerful tools for managing development environments, but they can have compatibility issues if not configured correctly. The main issue arises because worktrees rely on the `.git` file pointing to the main repository's `.git` directory, and if the container does not have access to that directory, git commands will fail.

From the host machine, you might have a folder structure like this:

```ascii
repos/
  working/       ← this is the worktree folder you open in VS Code
  .git/          ← this is the main repo's .git directory that contains all the metadata and history
  remotes/       ← this is a local filesystem remote that the repo fetches from and pushes to
```

As long as you open the `working` folder in VS Code, the `.git` file inside it will point to the `.git` directory at the absolute path `/Users/you/repos/.git`. If the container does not have that path mounted, git commands will fail because they cannot find the repository metadata.

When VS Code opens a worktree in a container it mounts the worktree folder — but **not** the main repo. Git reads the `.git` file, finds the absolute host path `/Users/you/repos/working/...`, tries to follow it, and fails because that path doesn't exist inside the container. Every git command then fails with:

```
fatal: not a git repository (or any of the parent directories): .git
```

### How this repo's `devcontainer.json` solves the issue

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
