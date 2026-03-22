# Installation Guide

This guide covers installing Jumper on macOS and Linux.

## Requirements

- **Operating System**: macOS or Linux (bash/zsh)
- **Shell**: bash or zsh
- **Rust** (for building from source): [Install Rust](https://www.rust-lang.org/tools/install)

## Installation Methods

### Method 1: Build from Source (Recommended)

1. **Clone or download the repository**

   ```bash
   cd /path/to/jumper
   ```

2. **Build the binary**

   ```bash
   cargo build --release
   cp target/release/jumper ./jumper
   chmod +x ./jumper
   ```

3. **Run the installer**

   ```bash
   ./install.sh
   ```

4. **Reload your shell**

   ```bash
   exec "$SHELL" -l
   ```

5. **Verify installation**

   ```bash
   j --help
   ```

### Method 2: Use Pre-built Binary

1. **Download the release tarball** for your platform:
   - macOS: `jumper-macOS-x86_64.tar.gz`
   - Linux: `jumper-Linux-x86_64.tar.gz`

2. **Extract and install**

   ```bash
   tar -xzf jumper-*.tar.gz
   cd jumper
   ./install.sh
   exec "$SHELL" -l
   ```

## What the Installer Does

The `install.sh` script:

1. Creates `~/.jumper` directory for Jumper's data
2. Copies the binary and shell scripts to `~/.jumper`
3. Creates `~/.jumper/jumperrc` with environment variables and aliases
4. Adds `source ~/.jumper/jumperrc` to your shell config (`.zshrc`, `.bashrc`, or `.bash_profile`)

## Installed Aliases

After installation, these commands are available:

| Command | Description |
|---------|-------------|
| `j` | Jump to a directory (or workspace root with no args) |
| `jadd` | Register a new directory |
| `jassemble` | Find and register a directory by name |
| `jalias` | Create an alias for an existing registration |
| `jlist` | List all registered directories |
| `jremove` | Remove a registration |

## Environment Variables

The installer sets these defaults:

| Variable | Default | Description |
|----------|---------|-------------|
| `JUMPER_HOME` | `~/.jumper` | Where Jumper stores its data |
| `JUMPER_WORKSPACE` | `$HOME` | Base directory for auto-discovery |
| `JUMPER_DEPTH` | `4` | Max depth for directory search |

## Shell Completions

Generate shell completions for better CLI experience:

### Bash

```bash
jumper completions bash >> ~/.local/share/bash-completion/completions/jumper
```

### Zsh

```bash
jumper completions zsh > "${fpath[1]}/_jumper"
```

### Fish

```bash
jumper completions fish > ~/.config/fish/completions/jumper.fish
```

## Uninstall

To remove Jumper:

1. Remove the jumper directory:
   ```bash
   rm -rf ~/.jumper
   ```

2. Remove the source line from your shell config:
   ```bash
   # Edit ~/.zshrc or ~/.bashrc and remove:
   # source ~/.jumper/jumperrc
   ```

3. Reload your shell:
   ```bash
   exec "$SHELL" -l
   ```
