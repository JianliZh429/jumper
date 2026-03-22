#!/bin/bash
# Jumper Installer - Download and install pre-built binaries
# Usage: curl -fsSL https://.../install.sh | bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
JUMPER_HOME="${JUMPER_HOME:-$HOME/.jumper}"
JUMPER_WORKSPACE="${JUMPER_WORKSPACE:-$HOME}"
JUMPER_DEPTH="${JUMPER_DEPTH:-4}"
REPO="${REPO:-yixun/jumper}"
VERSION="${VERSION:-latest}"

echo_info() {
    echo -e "${GREEN}✓${NC} $1"
}

echo_warn() {
    echo -e "${YELLOW}!${NC} $1"
}

echo_error() {
    echo -e "${RED}✗${NC} $1"
}

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

echo "Detecting platform..."
echo "  OS: $OS"
echo "  Architecture: $ARCH"

if [[ "$OS" == "unknown" || "$ARCH" == "unknown" ]]; then
    echo_error "Unsupported platform. Please install from source."
    exit 1
fi

# Create installation directory
echo_info "Creating installation directory: $JUMPER_HOME"
mkdir -p "$JUMPER_HOME"

# Download binary
TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

if [[ "$VERSION" == "latest" ]]; then
    DOWNLOAD_URL="https://github.com/${REPO}/releases/latest/download/jumper-${OS}-${ARCH}.tar.gz"
else
    DOWNLOAD_URL="https://github.com/${REPO}/releases/download/${VERSION}/jumper-${OS}-${ARCH}.tar.gz"
fi

echo_info "Downloading Jumper from: $DOWNLOAD_URL"

if command -v curl &> /dev/null; then
    if ! curl -fsSL "$DOWNLOAD_URL" -o "$TMPDIR/jumper.tar.gz" 2>/dev/null; then
        echo_error "Failed to download. Check your internet connection."
        echo_warn "Falling back to cargo install..."
        install_via_cargo
        exit 0
    fi
elif command -v wget &> /dev/null; then
    if ! wget -q "$DOWNLOAD_URL" -O "$TMPDIR/jumper.tar.gz" 2>/dev/null; then
        echo_error "Failed to download."
        echo_warn "Falling back to cargo install..."
        install_via_cargo
        exit 0
    fi
else
    echo_error "Neither curl nor wget found."
    echo_warn "Falling back to cargo install..."
    install_via_cargo
    exit 0
fi

# Extract binary
echo_info "Extracting binary..."
tar -xzf "$TMPDIR/jumper.tar.gz" -C "$TMPDIR" jumper

# Install binary
cp "$TMPDIR/jumper" "$JUMPER_HOME/jumper"
chmod +x "$JUMPER_HOME/jumper"

# Install shell script
if [[ -f "$TMPDIR/jumper.sh" ]]; then
    cp "$TMPDIR/jumper.sh" "$JUMPER_HOME/jumper.sh"
else
    echo_warn "jumper.sh not found in archive, creating default..."
    cat > "$JUMPER_HOME/jumper.sh" << 'JUMPER_SH'
#! /bin/bash
function jump() {
  target=$1
  if [ -z "${target}" ]; then
    echo -e "GOTO $JUMPER_WORKSPACE"
    cd "${JUMPER_WORKSPACE}"
  else
    if [[ "${target}" == "--help" ]]; then
        echo "Usage: j <directory-name>"
    else
        JUMPER=$JUMPER_HOME/jumper
        FIRST_DIR=$($JUMPER goto "${target}" | tr -d '"')
        if (( $(grep -c . <<<"${FIRST_DIR}") > 1 )); then
            echo -e "${FIRST_DIR}\n"
        fi
        FIRST_DIR=$(echo "${FIRST_DIR}" | tail -n 1)
        echo -e "GOTO: $FIRST_DIR"
        if [[ -d $FIRST_DIR ]]; then
            cd "$FIRST_DIR"
        else
            echo -e "\n$FIRST_DIR is not a valid directory"
        fi
    fi
  fi
}
jump "$1"
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

# Find and update shell config
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
    
    # Default to .zshrc on macOS, .bashrc on Linux
    if [[ "$OS" == "macOS" ]]; then
        echo "$HOME/.zshrc"
    else
        echo "$HOME/.bashrc"
    fi
}

SHELL_CONFIG=$(find_shell_config)
echo_info "Shell config: $SHELL_CONFIG"

# Add source line to shell config
SOURCE_LINE="source ${JUMPERRC}"
if [[ "$(basename "$SHELL_CONFIG")" == "config.fish" ]]; then
    SOURCE_LINE="source ${JUMPERRC}"
fi

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
    # Create the shell config if it doesn't exist
    touch "$SHELL_CONFIG"
    echo "" >> "$SHELL_CONFIG"
    echo "# Jumper - Directory navigation" >> "$SHELL_CONFIG"
    echo "$SOURCE_LINE" >> "$SHELL_CONFIG"
    echo_info "Created $SHELL_CONFIG and added Jumper"
fi

# Verify installation
echo ""
echo_info "Installation complete!"
echo ""
echo "To start using Jumper, either:"
echo "  1. Reload your shell: exec \"\$SHELL\" -l"
echo "  2. Or source manually: source \"$JUMPERRC\""
echo ""
echo "Then try: j --help"
echo ""
