# Configuration Guide

Jumper can be configured through environment variables or a configuration file.

## Configuration Methods

Jumper reads configuration in the following priority order (highest to lowest):

1. **Environment variables** (highest priority)
2. **Configuration file** (`~/.jumper/config.toml`)
3. **Default values** (lowest priority)

## Configuration Options

### JUMPER_HOME

**Default:** `~/.jumper`

The directory where Jumper stores its data files:
- `routes.json` - Your directory registrations
- `config.toml` - Configuration file (optional)
- `jumper` - The binary (after installation)
- `jumper.sh` - Shell script for `cd` integration
- `jumperrc` - Environment setup script

**Set via environment:**
```bash
export JUMPER_HOME=~/.config/jumper
```

**Set via config file:**
```toml
# ~/.jumper/config.toml
home = "~/.config/jumper"
```

### JUMPER_WORKSPACE

**Default:** `$HOME`

The base directory that Jumper searches when using `jassemble`. This is where your projects and directories live.

**Set via environment:**
```bash
export JUMPER_WORKSPACE=~/projects
```

**Set via config file:**
```toml
# ~/.jumper/config.toml
workspace = "~/projects"
```

**Example scenarios:**

```bash
# All projects in ~/projects
export JUMPER_WORKSPACE=~/projects

# Work projects only
export JUMPER_WORKSPACE=~/work

# Multiple workspaces (use the parent directory)
export JUMPER_WORKSPACE=~/dev
```

### JUMPER_DEPTH

**Default:** `4`

The maximum depth for directory search when using `jassemble`. Higher values search deeper but may be slower.

**Set via environment:**
```bash
export JUMPER_DEPTH=6
```

**Set via config file:**
```toml
# ~/.jumper/config.toml
depth = 6
```

**Depth examples:**

```
Depth 1: ~/projects/
Depth 2: ~/projects/my-app/
Depth 3: ~/projects/my-app/frontend/
Depth 4: ~/projects/my-app/frontend/src/  (default max)
```

## Configuration File

Create `~/.jumper/config.toml` for persistent configuration:

```toml
# ~/.jumper/config.toml

# Where Jumper stores its data
home = "~/.jumper"

# Base directory for auto-discovery
workspace = "~/projects"

# Maximum search depth for jassemble
depth = 5
```

### Creating the Config File

```bash
# Create the config file
cat > ~/.jumper/config.toml << 'EOF'
workspace = "~/projects"
depth = 5
EOF
```

### Full Example

```toml
# ~/.jumper/config.toml

# Store Jumper data in a custom location
home = "~/.config/jumper"

# Search for projects in ~/work directory
workspace = "~/work"

# Search up to 6 levels deep
depth = 6
```

## Environment Variables Setup

The installer creates `~/.jumper/jumperrc` with:

```bash
export JUMPER_HOME=~/.jumper
export JUMPER_WORKSPACE=$HOME
export JUMPER_DEPTH=4
export PATH=$PATH:~/.jumper
alias j='. ~/.jumper/jumper.sh'
alias jadd='~/.jumper/jumper add'
alias jassemble='~/.jumper/jumper assemble'
alias jalias='~/.jumper/jumper alias'
alias jlist='~/.jumper/jumper list'
alias jremove='~/.jumper/jumper remove'
```

### Customizing Environment Variables

Edit `~/.jumper/jumperrc`:

```bash
# Open the file
nano ~/.jumper/jumperrc

# Modify the values
export JUMPER_HOME=~/.jumper
export JUMPER_WORKSPACE=~/projects
export JUMPER_DEPTH=6

# Reload
source ~/.jumper/jumperrc
```

Or add overrides to your shell config:

```bash
# Add to ~/.zshrc or ~/.bashrc after the jumperrc source
export JUMPER_WORKSPACE=~/projects
export JUMPER_DEPTH=6
```

## Verifying Configuration

Check your current configuration:

```bash
# Check environment variables
echo "JUMPER_HOME: $JUMPER_HOME"
echo "JUMPER_WORKSPACE: $JUMPER_WORKSPACE"
echo "JUMPER_DEPTH: $JUMPER_DEPTH"

# Check if config file exists
cat ~/.jumper/config.toml

# Check if routes.json exists
cat ~/.jumper/routes.json
```

## Troubleshooting Configuration

### Configuration Not Applied

If your configuration changes aren't taking effect:

1. **Reload your shell:**
   ```bash
   exec "$SHELL" -l
   ```

2. **Check priority order:** Environment variables override config file

3. **Verify file location:** Config must be at `~/.jumper/config.toml`

### Reset to Defaults

Delete the config file and reload:

```bash
rm ~/.jumper/config.toml
exec "$SHELL" -l
```

### Custom Home Directory

To use a completely custom location:

```bash
# Set custom home
export JUMPER_HOME=~/.config/jumper

# Create directory
mkdir -p ~/.config/jumper

# Re-run installer with new home
cd /path/to/jumper
JUMPER_HOME=~/.config/jumper ./install.sh
```
