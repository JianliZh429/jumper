#!/bin/bash
# Jumper Uninstaller
# Usage: ./uninstall.sh or curl -fsSL .../uninstall.sh | bash

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

echo "Jumper Uninstaller"
echo "=================="
echo ""

# Find shell config files to clean
find_shell_configs() {
    local configs=()
    for config in "$HOME/.zshrc" "$HOME/.bashrc" "$HOME/.bash_profile" "$HOME/.profile" "$HOME/.config/fish/config.fish"; do
        if [[ -f "$config" ]]; then
            configs+=("$config")
        fi
    done
    echo "${configs[@]}"
}

# Remove source line from shell configs
echo_info "Cleaning shell configurations..."
for config in $(find_shell_configs); do
    if [[ -f "$config" ]]; then
        # Remove Jumper-related lines
        if grep -q "jumper" "$config" 2>/dev/null; then
            # Create backup
            cp "$config" "${config}.jumper.bak"
            
            # Remove Jumper lines
            sed -i.bak '/# Jumper - Directory navigation/d' "$config"
            sed -i.bak "/source.*jumperrc/d" "$config"
            sed -i.bak "/export JUMPER_/d" "$config"
            sed -i.bak "/alias j/d" "$config"
            
            # Clean up backup
            rm -f "${config}.bak"
            
            echo_info "  Cleaned: $config (backup: ${config}.jumper.bak)"
        fi
    fi
done

# Remove Jumper directory
if [[ -d "$JUMPER_HOME" ]]; then
    echo_info "Removing Jumper directory: $JUMPER_HOME"
    rm -rf "$JUMPER_HOME"
fi

# Remove from PATH if added elsewhere
echo_info "Checking for other Jumper references..."

# Check common locations
for location in "/usr/local/bin/jumper" "/usr/bin/jumper" "$HOME/.cargo/bin/jumper"; do
    if [[ -f "$location" ]]; then
        echo_warn "  Found: $location (not removed, may be from other installation)"
    fi
done

echo ""
echo_info "Uninstallation complete!"
echo ""
echo "To finish:"
echo "  1. Reload your shell: exec \"\$SHELL\" -l"
echo "  2. Or start a new terminal session"
echo ""
echo_warn "Note: Your routes.json was deleted. If you want to keep your registrations,"
echo_warn "      restore from ~/.jumper.jumper.bak/routes.json before deleting the backup."
echo ""
