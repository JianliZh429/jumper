# Usage Guide

This guide explains how to use Jumper's commands for efficient directory navigation.

## Getting Help

View help for any command:

```bash
# General help
jumper --help
jumper -h

# Help for specific command
jumper goto --help
jumper add --help
jumper list -h
```

## Basic Commands

### Jump to a Directory (`goto`)

Jump to a registered directory by name:

```bash
jumper goto <name>
jumper g <name>      # Short alias
```

Or use the shell alias:

```bash
j <name>
```

**Jump to workspace root** (no arguments):

```bash
jumper goto
j                    # Shell alias jumps to workspace root
```

**Examples:**

```bash
# Jump to a project
j my-project

# Jump to workspace root
j
```

### Register a Directory (`jadd`)

Manually register a directory with a name:

```bash
jadd <name> <path>
```

**Examples:**

```bash
# Register a project directory
jadd frontend ~/projects/my-app/frontend

# Register with absolute path
jadd docs /usr/local/share/docs

# Register a directory on an external drive
jadd backup /Volumes/ExternalDrive/Backups
```

### Auto-Discover and Register (`jassemble`)

Search your workspace for a directory and register it automatically:

```bash
jassemble <name>
```

**How it works:**

1. Searches within `JUMPER_WORKSPACE` (default: `$HOME`)
2. Searches up to `JUMPER_DEPTH` levels (default: 4)
3. Skips hidden directories and common non-essential folders (`.git`, `node_modules`, `target`, etc.)
4. Registers the first match found (alphabetically sorted)

**Examples:**

```bash
# Find and register a directory named "frontend"
jassemble frontend

# This will find ~/projects/my-app/frontend if it exists
```

### Create an Alias (`jalias`)

Create a shortcut for an existing registration:

```bash
jalias <shortcut> <existing-name>
```

**Examples:**

```bash
# Create short alias
jalias fe frontend

# Now both work:
j fe       # Uses alias
j frontend # Uses original name

# Alias for a long name
jalias k8s-configs kubernetes-configurations
```

### List All Registrations (`jlist`)

View all registered directories and aliases:

```bash
jlist
```

**Example output:**

```
backend       -> /Users/me/projects/api
docs          -> /Users/me/projects/docs
fe            -> /Users/me/projects/frontend
frontend      -> /Users/me/projects/frontend
k8s-configs   -> /Users/me/projects/kubernetes-configurations
```

### Remove a Registration (`jremove`)

Remove a registered name or alias:

```bash
jremove <name>
```

**Examples:**

```bash
# Remove an alias
jremove fe

# Remove a registration
jremove old-project
```

## Advanced Usage

### Command-Line Help

View help for any command:

```bash
# General help
jumper --help

# Help for specific command
jumper goto --help
jumper add --help
```

### Generate Shell Completions

Enable tab-completion for your shell:

```bash
# Bash
jumper completions bash >> ~/.local/share/bash-completion/completions/jumper

# Zsh
jumper completions zsh > "${fpath[1]}/_jumper"

# Fish
jumper completions fish > ~/.config/fish/completions/jumper.fish
```

## Common Workflows

### Daily Development

```bash
# Morning: jump to your project
j my-project

# Switch between frontend and backend
j frontend
# ... work ...
j backend
# ... work ...

# Quick access with aliases
j fe  # If you created: jalias fe frontend
```

### Setting Up a New Project

```bash
# Clone your project
cd ~/projects
git clone git@github.com:user/my-app.git

# Register the main directory
jadd my-app ~/projects/my-app

# Register subdirectories
jadd my-app-fe ~/projects/my-app/frontend
jadd my-app-be ~/projects/my-app/backend

# Create short aliases
jalias app my-app
jalias fe my-app-fe
jalias be my-app-be
```

### Managing Multiple Projects

```bash
# List all registrations to see what you have
jlist

# Remove old projects
jremove old-project
jremove old-project-fe

# Auto-discover new projects in your workspace
jassemble new-repo
```

## Tips and Best Practices

### 1. Use Consistent Naming

```bash
# Good: clear and consistent
jadd project-name-feature
jadd project-name-backend

# Avoid: inconsistent naming
jadd ProjectName
jadd project_name_v2
```

### 2. Create Hierarchical Aliases

```bash
# Register full paths
jadd company-project-alpha
jadd company-project-beta

# Create short aliases for daily use
jalias alpha company-project-alpha
jalias beta company-project-beta
```

### 3. Use Auto-Discovery for Simple Cases

```bash
# For directories directly in your workspace
jassemble documents    # Finds ~/documents

# For nested directories
jassemble frontend     # Finds ~/projects/my-app/frontend
```

### 4. Keep It Clean

```bash
# Regularly review your registrations
jlist

# Remove unused entries
jremove old-project
```

## Data Storage

Jumper stores your registrations in `~/.jumper/routes.json`:

```json
{
  "backend": "/Users/me/projects/api",
  "fe": "/Users/me/projects/frontend",
  "frontend": "/Users/me/projects/frontend"
}
```

**Note:** You can edit this file directly if needed, but using the CLI commands is recommended.

## Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Success |
| 1 | Error (directory not found, invalid path, etc.) |
