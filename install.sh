#!/bin/bash
# Jumper Installer - Flexible installer supporting multiple methods
# Usage: 
#   Local:  ./install.sh
#   Remote: curl -fsSL https://.../install.sh | bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo_info() {
    echo -e "${GREEN}✓${NC} $1"
}

echo_warn() {
    echo -e "${YELLOW}!${NC} $1"
}

echo_error() {
    echo -e "${RED}✗${NC} $1"
}

# Configuration
JUMPER_HOME="${JUMPER_HOME:-$HOME/.jumper}"
JUMPER_WORKSPACE="${JUMPER_WORKSPACE:-$HOME}"
JUMPER_DEPTH="${JUMPER_DEPTH:-4}"

# Detect if running from local repo or remote
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IS_LOCAL=false

if [[ -f "$SCRIPT_DIR/jumper" && -x "$SCRIPT_DIR/jumper" ]]; then
    IS_LOCAL=true
    echo_info "Local installation detected"
elif [[ -f "$SCRIPT_DIR/target/release/jumper" ]]; then
    IS_LOCAL=true
    cp "$SCRIPT_DIR/target/release/jumper" "$SCRIPT_DIR/jumper"
    chmod +x "$SCRIPT_DIR/jumper"
    echo_info "Built binary found, copying to repo root"
fi

# Create installation directory
echo_info "Creating installation directory: $JUMPER_HOME"
mkdir -p "$JUMPER_HOME"

if [[ "$IS_LOCAL" == "true" ]]; then
    # Local installation - copy from repo
    echo_info "Installing from local build..."
    
    if [[ ! -f "$SCRIPT_DIR/jumper" ]]; then
        echo_error "Binary not found. Please build first:"
        echo "  cargo build --release"
        echo "  cp target/release/jumper ./jumper"
        exit 1
    fi
    
    cp "$SCRIPT_DIR/jumper" "$JUMPER_HOME/jumper"
    cp "$SCRIPT_DIR/jumper.sh" "$JUMPER_HOME/jumper.sh" 2>/dev/null || true
else
    # Remote installation - try to download pre-built binary
    echo_info "Installing from remote release..."
    
    # Detect OS and architecture
    detect_os() {
        case "$(uname -s)" in
            Linux*)  echo "Linux" ;;
            Darwin*) echo "macOS" ;;
            *)       echo "unknown" ;;
        esac
    }

    detect_arch() {
        case "$(uname -m)" in
            x86_64)  echo "x86_64" ;;
            arm64)   echo "aarch64" ;;
            aarch64) echo "aarch64" ;;
            *)       echo "unknown" ;;
        esac
    }

    OS=$(detect_os)
    ARCH=$(detect_arch)
    
    echo "  OS: $OS"
    echo "  Architecture: $ARCH"
    
    if [[ "$OS" != "unknown" && "$ARCH" != "unknown" ]]; then
        DOWNLOAD_URL="https://github.com/yixun/jumper/releases/latest/download/jumper-${OS}-${ARCH}.tar.gz"
        TMPDIR=$(mktemp -d)
        trap 'rm -rf "$TMPDIR"' EXIT
        
        echo_info "Downloading from: $DOWNLOAD_URL"
        
        if command -v curl &> /dev/null; then
            if curl -fsSL "$DOWNLOAD_URL" -o "$TMPDIR/jumper.tar.gz" 2>/dev/null; then
                tar -xzf "$TMPDIR/jumper.tar.gz" -C "$TMPDIR" jumper 2>/dev/null && {
                    cp "$TMPDIR/jumper" "$JUMPER_HOME/jumper"
                    chmod +x "$JUMPER_HOME/jumper"
                    
                    if [[ -f "$TMPDIR/jumper.sh" ]]; then
                        cp "$TMPDIR/jumper.sh" "$JUMPER_HOME/jumper.sh"
                    fi
                    echo_info "Installed pre-built binary"
                }
            fi
        fi
    fi
    
    # Fall back to cargo install if download failed
    if [[ ! -f "$JUMPER_HOME/jumper" ]]; then
        echo_warn "Pre-built binary not available, trying cargo install..."
        if command -v cargo &> /dev/null; then
            cargo install --git https://github.com/yixun/jumper.git --force 2>/dev/null && {
                # Find where cargo installed it
                CARGO_BIN="$(cargo install --list | grep jumper | head -1 | awk '{print $2}' | tr -d 'v0-9.')"
                if [[ -n "$CARGO_BIN" ]]; then
                    cp "$CARGO_BIN" "$JUMPER_HOME/jumper" 2>/dev/null || true
                fi
                echo_info "Installed via cargo"
            } || {
                echo_error "Cargo install failed. Please install manually:"
                echo "  cargo install --git https://github.com/yixun/jumper.git"
                exit 1
            }
        else
            echo_error "Neither pre-built binary nor cargo available."
            exit 1
        fi
    fi
fi

# Ensure binary is executable
chmod +x "$JUMPER_HOME/jumper"

# Create shell script if not present
if [[ ! -f "$JUMPER_HOME/jumper.sh" ]]; then
    cat > "$JUMPER_HOME/jumper.sh" << 'JUMPER_SH'
#! /bin/bash
# Jumper shell wrapper - enables cd functionality

function j_help() {
    cat << 'HELP'
Jumper - Directory navigation tool

Usage:
  j              Jump to workspace root
  j <name>       Jump to a registered directory
  j --help       Show this help message

Shell aliases (set up by installer):
  j              - Jump to directory
  jadd           - Register a directory (jumper add)
  jassemble      - Find and register (jumper assemble)
  jalias         - Create alias (jumper alias)
  jlist          - List all registrations (jumper list)
  jremove        - Remove registration (jumper remove)

Examples:
  j              # Jump to workspace root
  j my-project   # Jump to registered directory
  jadd blog ~/work/blog
  jlist

For more information: https://github.com/yixun/jumper
HELP
}

function jump() {
  local target="$1"
  local JUMPER="${JUMPER_HOME:-$HOME/.jumper}/jumper"
  local target_dir

  if [[ "${target}" == "--help" || "${target}" == "-h" || "${target}" == "help" ]]; then
    j_help
    return 0
  fi

  if [[ -z "${target}" ]]; then
    target_dir="${JUMPER_WORKSPACE:-$HOME}"
    echo "GOTO: $target_dir"
    cd "$target_dir" || return 1
    return 0
  fi

  target_dir=$("$JUMPER" goto "$target" 2>&1)
  local exit_code=$?

  if [[ $exit_code -ne 0 ]]; then
    echo "Error: $target_dir" >&2
    return 1
  fi

  if [[ -d "$target_dir" ]]; then
    echo "GOTO: $target_dir"
    cd "$target_dir" || return 1
  else
    echo "Error: '$target_dir' is not a valid directory" >&2
    return 1
  fi
}

jump "$@"
JUMPER_SH
    chmod +x "$JUMPER_HOME/jumper.sh"
fi

# Create configuration
JUMPERRC="$JUMPER_HOME/jumperrc"
echo_info "Creating configuration: $JUMPERRC"
cat > "$JUMPERRC" << EOF
export JUMPER_HOME=${JUMPER_HOME}
export JUMPER_WORKSPACE=${JUMPER_WORKSPACE}
export JUMPER_DEPTH=${JUMPER_DEPTH}
export PATH=\${PATH}:${JUMPER_HOME}
alias j='. ${JUMPER_HOME}/jumper.sh'
alias jadd='${JUMPER_HOME}/jumper add'
alias jassemble='${JUMPER_HOME}/jumper assemble'
alias jalias='${JUMPER_HOME}/jumper alias'
alias jlist='${JUMPER_HOME}/jumper list'
alias jremove='${JUMPER_HOME}/jumper remove'
EOF

# Find shell config
find_shell_config() {
    if [[ -n "${XDG_CONFIG_HOME:-}" && -f "$XDG_CONFIG_HOME/fish/config.fish" ]]; then
        echo "$XDG_CONFIG_HOME/fish/config.fish"
        return
    fi
    
    for config in "$HOME/.zshrc" "$HOME/.bashrc" "$HOME/.bash_profile" "$HOME/.profile"; do
        if [[ -f "$config" ]]; then
            echo "$config"
            return
        fi
    done
    
    # Default
    if [[ "$(uname)" == "Darwin" ]]; then
        echo "$HOME/.zshrc"
    else
        echo "$HOME/.bashrc"
    fi
}

SHELL_CONFIG=$(find_shell_config)
echo_info "Shell config: $SHELL_CONFIG"

# Add source line to shell config
SOURCE_LINE="source ${JUMPERRC}"
if [[ -f "$SHELL_CONFIG" ]]; then
    if grep -qF "$SOURCE_LINE" "$SHELL_CONFIG" 2>/dev/null; then
        echo_info "Jumper already configured in $SHELL_CONFIG"
    else
        echo "" >> "$SHELL_CONFIG"
        echo "# Jumper - Directory navigation" >> "$SHELL_CONFIG"
        echo "$SOURCE_LINE" >> "$SHELL_CONFIG"
        echo_info "Added Jumper to $SHELL_CONFIG"
    fi
else
    touch "$SHELL_CONFIG"
    echo "" >> "$SHELL_CONFIG"
    echo "# Jumper - Directory navigation" >> "$SHELL_CONFIG"
    echo "$SOURCE_LINE" >> "$SHELL_CONFIG"
    echo_info "Created $SHELL_CONFIG and added Jumper"
fi

# Verify installation
echo ""
if "$JUMPER_HOME/jumper" --version &>/dev/null; then
    VERSION=$("$JUMPER_HOME/jumper" --version)
    echo_info "Installation successful! $VERSION"
else
    echo_info "Installation complete!"
fi

echo ""
echo "To start using Jumper:"
echo "  1. Reload your shell: exec \"\$SHELL\" -l"
echo "  2. Or source manually: source \"$JUMPERRC\""
echo ""
echo "Then try: j --help"
echo ""
