# Installation Guide

This guide covers installing Jumper on macOS and Linux.

## Quick Install (Recommended)

### One-Liner Install

The easiest way to install Jumper:

```bash
# macOS and Linux
curl -fsSL https://github.com/JianliZh429/jumper/releases/latest/download/install.sh | bash
```

Then reload your shell:

```bash
exec "$SHELL" -l
```

## Installation Methods

### Method 1: One-Liner Script (Recommended)

Download and install automatically:

```bash
# Using curl
curl -fsSL https://github.com/JianliZh429/jumper/releases/latest/download/install.sh | bash

# Using wget
wget -qO- https://github.com/JianliZh429/jumper/releases/latest/download/install.sh | bash

# Specify version
VERSION=v0.1.0 curl -fsSL https://github.com/JianliZh429/jumper/releases/download/$VERSION/install.sh | bash
```

**What it does:**
- Downloads the pre-built binary for your platform
- Falls back to `cargo install` if binary unavailable
- Sets up configuration automatically
- Adds aliases to your shell config

### Method 2: Homebrew (macOS)

```bash
# Add the tap
brew tap JianliZh429/jumper https://github.com/JianliZh429/jumper.git

# Install
brew install jumper

# Follow the post-install instructions
```

### Method 3: Cargo Install

```bash
# Install from git repository
cargo install --git https://github.com/JianliZh429/jumper.git

# Then set up shell integration
mkdir -p ~/.jumper
jumper --help  # Verify installation
```

After installing via cargo, you'll need to set up the shell integration manually:

```bash
# Create configuration
cat > ~/.jumper/jumperrc << 'EOF'
export JUMPER_HOME=~/.jumper
export JUMPER_WORKSPACE=$HOME
export JUMPER_DEPTH=4
alias j='. ~/.jumper/jumper.sh'
alias jadd='jumper add'
alias jassemble='jumper assemble'
alias jalias='jumper alias'
alias jlist='jumper list'
alias jremove='jumper remove'
EOF

# Add to shell config
echo 'source ~/.jumper/jumperrc' >> ~/.zshrc
exec "$SHELL" -l
```

### Method 4: Build from Source

1. **Clone the repository**

   ```bash
   git clone https://github.com/JianliZh429/jumper.git
   cd jumper
   ```

2. **Build the binary**

   ```bash
   # Quick build (recommended)
   ./build.sh
   
   # Or manual build
   cargo build --release
   cp target/release/jumper ./jumper
   ```

3. **Run the installer**

   ```bash
   ./install.sh
   exec "$SHELL" -l
   ```

### Method 5: Manual Installation

1. **Download pre-built binary**

   ```bash
   # macOS
   curl -LO https://github.com/JianliZh429/jumper/releases/latest/download/jumper-macOS-x86_64.tar.gz
   
   # Linux
   curl -LO https://github.com/JianliZh429/jumper/releases/latest/download/jumper-Linux-x86_64.tar.gz
   ```

2. **Extract and install**

   ```bash
   tar -xzf jumper-*.tar.gz
   mkdir -p ~/.jumper
   cp jumper ~/.jumper/
   chmod +x ~/.jumper/jumper
   ```

3. **Set up shell integration** (see Method 3)

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

Jumper provides shell completions for a better CLI experience.

### Automatic Completion Setup

The installer automatically sets up tab completion for registered directory names when you use the `j` command.

**Examples:**
```bash
# Type 'j' and press Tab to see all registered directories
j <TAB>

# Type partial name and press Tab to complete
j my<TAB>  # Completes to 'myproject' if registered
```

### Manual Completion Setup

If you installed via cargo or built from source, you can manually enable completions:

#### Bash

```bash
# Add to ~/.bashrc
source ~/.jumper/completion.bash

# Or generate completions for the jumper command
jumper completions bash >> ~/.local/share/bash-completion/completions/jumper
```

#### Zsh

```bash
# Add to ~/.zshrc
source ~/.jumper/completion.zsh

# Or generate completions for the jumper command
jumper completions zsh > "${fpath[1]}/_jumper"
```

#### Fish

```bash
# Generate completions
jumper completions fish > ~/.config/fish/completions/jumper.fish
```

## Uninstall

To remove Jumper completely:

### Using the Uninstall Script

```bash
curl -fsSL https://github.com/JianliZh429/jumper/releases/latest/download/uninstall.sh | bash
```

### Manual Uninstall

1. **Remove Jumper directory:**
   ```bash
   rm -rf ~/.jumper
   ```

2. **Remove from shell config:**
   ```bash
   # Edit ~/.zshrc or ~/.bashrc and remove:
   # # Jumper - Directory navigation
   # source ~/.jumper/jumperrc
   ```

3. **Reload shell:**
   ```bash
   exec "$SHELL" -l
   ```

### Using Homebrew

```bash
brew uninstall jumper
brew untap JianliZh429/jumper
```
