# Jumper

A CLI tool for quickly navigating between directories by name. Jump to your projects with short, memorable names instead of long paths.

```bash
# Jump to a registered directory
j my-project

# Register a new directory
jadd my-project ~/projects/my-app

# List all registered directories
jlist
```

## 📚 Documentation

For detailed guides, see the [Documentation](docs/README.md):

- **[Installation Guide](docs/installation.md)** - Install and set up Jumper
- **[Usage Guide](docs/usage.md)** - Commands and examples
- **[Configuration Guide](docs/configuration.md)** - Customize Jumper
- **[Troubleshooting](docs/troubleshooting.md)** - Common issues and solutions

## ✨ Features

- **Jump by Name** - Navigate with `j <name>` instead of `cd /long/path`
- **Auto-Discovery** - Find directories automatically with `jassemble`
- **Aliases** - Create shortcuts with `jalias`
- **Persistent Storage** - Your mappings are saved between sessions
- **Shell Integration** - Seamless integration with bash/zsh
- **Shell Completions** - Tab completion for all commands

## 🚀 Quick Start

### One-Liner Install (Recommended)

```bash
curl -fsSL https://github.com/yixun/jumper/releases/latest/download/install.sh | bash
exec "$SHELL" -l
```

### Other Installation Methods

```bash
# Homebrew (macOS)
brew tap yixun/jumper https://github.com/yixun/jumper.git
brew install jumper

# Cargo
cargo install --git https://github.com/yixun/jumper.git

# Build from source
git clone https://github.com/yixun/jumper.git
cd jumper && cargo build --release
./install.sh
```

For detailed installation instructions, see the [Installation Guide](docs/installation.md).

## 📖 Usage

### Basic Commands

| Command | Description | Example |
|---------|-------------|---------|
| `j <name>` | Jump to a directory | `j my-project` |
| `j` | Jump to workspace root | `j` |
| `jadd <name> <path>` | Register a directory | `jadd blog ~/work/blog` |
| `jassemble <name>` | Find and register | `jassemble frontend` |
| `jalias <short> <name>` | Create an alias | `jalias fe frontend` |
| `jlist` | List all registrations | `jlist` |
| `jremove <name>` | Remove a registration | `jremove old-project` |

### Example Workflow

```bash
# Register your projects
jadd frontend ~/projects/my-app/frontend
jadd backend ~/projects/my-app/api

# Jump between them
j frontend
# ... work on frontend ...
j backend
# ... work on backend ...

# Create short aliases
jalias fe frontend
jalias be backend
j fe  # Now you can use the short name

# List all registrations
jlist
```

## ⚙️ Configuration

Jumper uses these environment variables (set by installer in `~/.jumper/jumperrc`):

| Variable | Default | Description |
|----------|---------|-------------|
| `JUMPER_HOME` | `~/.jumper` | Data storage directory |
| `JUMPER_WORKSPACE` | `$HOME` | Base directory for search |
| `JUMPER_DEPTH` | `4` | Max search depth |

You can also create `~/.jumper/config.toml`:

```toml
# ~/.jumper/config.toml
workspace = "~/projects"
depth = 5
```

**Priority:** environment variables > config.toml > defaults

## 📦 Data Storage

Mappings are saved as JSON in `$JUMPER_HOME/routes.json`:

```json
{
  "backend": "/Users/me/projects/api",
  "fe": "/Users/me/projects/frontend",
  "frontend": "/Users/me/projects/frontend"
}
```

Delete this file to reset all registrations.

## 🛠️ Development

### Build

```bash
cargo build --release
```

### Test

```bash
cargo test
```

### Format & Lint

```bash
cargo fmt
cargo clippy --all-targets -- -D warnings
```

### Package

Create distributable tarballs (requires cross-linker for Linux):

```bash
./package.sh
# artifacts in target/jumper-*.tar.gz
```

## 📋 Requirements

- **OS:** macOS or Linux
- **Shell:** bash or zsh
- **Rust:** For building from source ([install](https://www.rust-lang.org/tools/install))

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run tests: `cargo test`
5. Submit a pull request

## 📄 License

MIT License - see LICENSE file for details.

## 🔗 Links

- [Full Documentation](docs/README.md)
- [Installation Guide](docs/installation.md)
- [Usage Guide](docs/usage.md)
- [Configuration Guide](docs/configuration.md)
- [Troubleshooting](docs/troubleshooting.md)
