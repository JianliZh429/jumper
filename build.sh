#! /bin/bash
# Build Jumper for current platform (native build)
# Use this for local development and testing

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

echo_info() {
    echo -e "${GREEN}✓${NC} $1"
}

echo "Building Jumper for current platform..."

# Build release
cargo build --release

# Copy to repo root for convenience
cp target/release/jumper ./jumper
chmod +x ./jumper

echo ""
echo_info "Build successful!"
echo ""
echo "Binary location: ./jumper"
echo "Version: $(./jumper --version)"
echo ""
echo "To install locally, run:"
echo "  ./install.sh"
