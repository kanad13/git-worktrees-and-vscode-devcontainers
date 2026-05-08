# Dev Container Configuration for Git Worktrees

This configuration makes VS Code Dev Containers work with Git worktrees by solving a critical path resolution problem.

## The Problem This Solves

Git worktrees and Dev Containers have a fundamental compatibility challenge:

- A worktree's `.git` file contains an **absolute path** pointing to the main repository's `.git` directory
- When VS Code opens a worktree in a container, it only mounts that worktree folder by default
- The container can't access the path referenced in the `.git` file
- Result: **Every git command fails** with `fatal: not a git repository`

## The Solution

This configuration mounts the **entire parent directory** into the container at the same absolute path it has on the host. This ensures both the worktree and the main repository are accessible at their expected locations.

## File Overview

| File                | Purpose                                                          |
| ------------------- | ---------------------------------------------------------------- |
| `devcontainer.json` | Main configuration: defines mounts, user, and git safe.directory |
| `Dockerfile`        | Defines the base container image                                 |

## Key Configuration Elements

### 1. Parent Directory Mount

```json
"mounts": [
  "source=${localWorkspaceFolder}/..,target=${localWorkspaceFolder}/..,type=bind,consistency=cached"
]
```

This mount makes both the worktree and main repository accessible inside the container. Works automatically regardless of folder names.

### 2. Git Safe Directory

```json
"postCreateCommand": "git config --global --add safe.directory ${containerWorkspaceFolder}/.."
```

Docker bind-mounts may appear owned by root inside the container. Git refuses to operate in such directories unless they're marked safe.

### 3. Cross-Platform Support

The `${localWorkspaceFolder}` variable automatically converts paths for your OS (Windows, macOS, Linux). No customization needed.

## Adapting for Non-Standard Layouts

| Scenario                                 | What to Change                                                                                              |
| ---------------------------------------- | ----------------------------------------------------------------------------------------------------------- |
| **Worktrees not in parent directory**    | Adjust the mount path to point to the correct location where both the worktree and main repo are accessible |
| **Need additional host folders mounted** | Add more entries to the `mounts` array                                                                      |
| **Using submodules**                     | Add additional `git config --add safe.directory` commands for submodule paths                               |

## Verifying It Works

After the container builds, open a terminal and run:

```bash
git status
git log --oneline -5
```

If these commands work without errors, the configuration is successful.

For conceptual background on Git worktrees and why they're useful with AI agents, see [../concepts.md](../concepts.md).
