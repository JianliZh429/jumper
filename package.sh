#! /bin/bash
# Package Jumper for release distribution
# Requires: cross linker for Linux target (x86_64-unknown-linux-gnu-gcc)

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo_info() {
    echo -e "${GREEN}✓${NC} $1"
}

echo_warn() {
    echo -e "${YELLOW}!${NC} $1"
}

echo_error() {
    echo -e "${RED}✗${NC} $1"
}

# Check if cross-compilation is available
check_linux_build() {
    if command -v x86_64-unknown-linux-gnu-gcc &> /dev/null; then
        return 0
    fi
    # Also check for musl-gcc
    if command -v musl-gcc &> /dev/null; then
        return 0
    fi
    return 1
}

check_mac_build() {
    # macOS native build should always work
    return 0
}

# Create output directory
mkdir -p target

# Build Linux target
echo "Building Linux target..."
if check_linux_build; then
    CARGO_TARGET_X86_64_UNKNOWN_LINUX_GNU_LINKER=x86_64-unknown-linux-gnu-gcc \
        cargo build --release --target=x86_64-unknown-linux-gnu 2>/dev/null || \
    CARGO_TARGET_X86_64_UNKNOWN_LINUX_GNU_LINKER=musl-gcc \
        cargo build --release --target=x86_64-unknown-linux-gnu
    
    if [[ -f "target/x86_64-unknown-linux-gnu/release/jumper" ]]; then
        echo_info "Linux build successful"
        
        mkdir -p pkg
        cp target/x86_64-unknown-linux-gnu/release/jumper pkg/jumper
        cp install.sh pkg/install.sh
        cp jumper.sh pkg/jumper.sh
        
        cd pkg
        chmod +x jumper install.sh jumper.sh
        tar -zcvf ../target/jumper-Linux-x86_64.tar.gz jumper install.sh jumper.sh
        cd ..
        rm -rf pkg
    else
        echo_error "Linux build failed - binary not found"
    fi
else
    echo_warn "Linux cross-compiler not found."
    echo_warn "To build Linux binaries, install one of:"
    echo_warn "  - musl-tools: apt install musl-tools"
    echo_warn "  - cross: cargo install cross"
    echo_warn ""
    echo_warn "Skipping Linux build..."
fi

# Build macOS target
echo ""
echo "Building macOS target..."
if check_mac_build; then
    if cargo build --release --target=x86_64-apple-darwin 2>/dev/null; then
        if [[ -f "target/x86_64-apple-darwin/release/jumper" ]]; then
            echo_info "macOS x86_64 build successful"
            
            mkdir -p pkg
            cp target/x86_64-apple-darwin/release/jumper pkg/jumper
            cp install.sh pkg/install.sh
            cp jumper.sh pkg/jumper.sh
            
            cd pkg
            chmod +x jumper install.sh jumper.sh
            tar -zcvf ../target/jumper-macOS-x86_64.tar.gz jumper install.sh jumper.sh
            cd ..
            rm -rf pkg
        fi
    else
        echo_warn "macOS x86_64 build failed or not needed"
    fi
    
    # Also build for Apple Silicon (arm64)
    if cargo build --release --target=aarch64-apple-darwin 2>/dev/null; then
        if [[ -f "target/aarch64-apple-darwin/release/jumper" ]]; then
            echo_info "macOS ARM64 build successful"
            
            mkdir -p pkg
            cp target/aarch64-apple-darwin/release/jumper pkg/jumper
            cp install.sh pkg/install.sh
            cp jumper.sh pkg/jumper.sh
            
            cd pkg
            chmod +x jumper install.sh jumper.sh
            tar -zcvf ../target/jumper-macOS-arm64.tar.gz jumper install.sh jumper.sh
            cd ..
            rm -rf pkg
        fi
    fi
fi

echo ""
echo_info "Package artifacts created in target/:"
ls -lh target/*.tar.gz 2>/dev/null || echo_warn "No packages created"
echo ""
echo "Done!"
