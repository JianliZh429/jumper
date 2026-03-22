# Jumper Documentation

Welcome to Jumper's documentation. Jumper is a CLI tool that lets you quickly navigate between directories by name.

## Table of Contents

- [Installation](installation.md) - How to install Jumper
- [Usage Guide](usage.md) - How to use Jumper commands
- [Configuration](configuration.md) - Configure Jumper to your needs
- [Troubleshooting](troubleshooting.md) - Common issues and solutions

## Quick Start

```bash
# Install
./install.sh

# Jump to a registered directory
j my-project

# Register a new directory
jadd my-project /path/to/project

# List all registered directories
jlist
```

## What is Jumper?

Jumper is a directory navigation tool that:

- **Jump by name**: Quickly switch to directories using short, memorable names
- **Auto-discover**: Find directories in your workspace automatically
- **Create aliases**: Set up shortcuts for frequently used paths
- **Persistent storage**: Your mappings are saved between sessions

## Example Workflow

```bash
# Register your projects
jadd frontend ~/projects/my-app/frontend
jadd backend ~/projects/my-app/api

# Jump between them
j frontend
# ... work on frontend ...
j backend
# ... work on backend ...

# Create a short alias
jalias fe frontend
j fe  # Now you can use the short name
```
