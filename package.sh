#! /bin/bash
# Package Jumper for release distribution
# Supports: native cross-compilation or cross (Docker-based)

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

# Check if cross-compilation is available (native)
check_native_cross() {
    # Check for x86_64-linux-musl-gcc (brew musl-cross)
    if command -v x86_64-linux-musl-gcc &> /dev/null; then
        return 0
    fi
    # Check for x86_64-unknown-linux-gnu-gcc
    if command -v x86_64-unknown-linux-gnu-gcc &> /dev/null; then
        return 0
    fi
    # Check for musl-gcc
    if command -v musl-gcc &> /dev/null; then
        return 0
    fi
    return 1
}

# Check if cross (Docker-based) is available
check_cross() {
    # Check in PATH
    if command -v cross &> /dev/null; then
        # Verify Docker is running
        if ! docker info &> /dev/null; then
            return 1
        fi
        # Verify rustup is available (required by cross)
        if command -v rustup &> /dev/null || [[ -x "$HOME/.cargo/bin/rustup" ]]; then
            return 0
        fi
    fi
    
    # Check in cargo bin directory
    if [[ -x "$HOME/.cargo/bin/cross" ]]; then
        if docker info &> /dev/null; then
            if command -v rustup &> /dev/null || [[ -x "$HOME/.cargo/bin/rustup" ]]; then
                return 0
            fi
        fi
    fi
    
    return 1
}

# Create output directory
mkdir -p target

# Build Linux target
echo "Building Linux target..."
if check_native_cross; then
    echo_info "Using native cross-compiler..."
    
    # Find rustup binary and set up environment
    RUSTUP_BIN="rustup"
    RUSTUP_AVAILABLE=false
    if command -v rustup &> /dev/null; then
        RUSTUP_AVAILABLE=true
    elif [[ -x "$HOME/.cargo/bin/rustup" ]]; then
        RUSTUP_BIN="$HOME/.cargo/bin/rustup"
        RUSTUP_AVAILABLE=true
    fi
    
    # Find cargo from rustup (not Homebrew)
    CARGO_BIN="cargo"
    if [[ "$RUSTUP_AVAILABLE" == "true" ]] && [[ -x "$HOME/.cargo/bin/cargo" ]]; then
        # Use rustup's cargo to ensure it uses rustup's rustc
        CARGO_BIN="$HOME/.cargo/bin/cargo"
        echo_info "Using rustup's cargo for cross-compilation"
    fi
    
    # Determine which compiler and target to use
    if command -v x86_64-linux-musl-gcc &> /dev/null; then
        # musl-cross from Homebrew
        echo_info "Detected musl-cross (Homebrew)"
        LINUX_TARGET="x86_64-unknown-linux-musl"
        
        if [[ "$RUSTUP_AVAILABLE" == "true" ]]; then
            echo_info "Adding musl target..."
            "$RUSTUP_BIN" target add "$LINUX_TARGET" 2>/dev/null || true
            CARGO_TARGET_X86_64_UNKNOWN_LINUX_MUSL_LINKER=x86_64-linux-musl-gcc \
                "$CARGO_BIN" build --release --target="$LINUX_TARGET"
        else
            echo_warn "musl-cross detected, but rustup is not available."
            echo_warn ""
            echo_warn "Homebrew Rust doesn't include musl standard libraries."
            echo_warn "To build Linux binaries, you need to install Rust via rustup:"
            echo_warn "  1. Uninstall Homebrew Rust: brew uninstall rust"
            echo_warn "  2. Install rustup: curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh"
            echo_warn "  3. Then run this script again"
            echo_warn ""
            echo_warn "Skipping Linux build..."
            LINUX_TARGET=""
        fi
    elif command -v x86_64-unknown-linux-gnu-gcc &> /dev/null; then
        LINUX_TARGET="x86_64-unknown-linux-gnu"
        
        if [[ "$RUSTUP_AVAILABLE" == "true" ]]; then
            echo_info "Adding GNU target..."
            "$RUSTUP_BIN" target add "$LINUX_TARGET" 2>/dev/null || true
            CARGO_TARGET_X86_64_UNKNOWN_LINUX_GNU_LINKER=x86_64-unknown-linux-gnu-gcc \
                "$CARGO_BIN" build --release --target="$LINUX_TARGET"
        else
            echo_warn "GNU cross-compiler detected, but rustup is not available."
            echo_warn "Please install rustup for cross-compilation support."
            echo_warn "Skipping Linux build..."
            LINUX_TARGET=""
        fi
    elif command -v musl-gcc &> /dev/null; then
        LINUX_TARGET="x86_64-unknown-linux-musl"
        
        if [[ "$RUSTUP_AVAILABLE" == "true" ]]; then
            echo_info "Adding musl target..."
            "$RUSTUP_BIN" target add "$LINUX_TARGET" 2>/dev/null || true
            CARGO_TARGET_X86_64_UNKNOWN_LINUX_MUSL_LINKER=musl-gcc \
                "$CARGO_BIN" build --release --target="$LINUX_TARGET"
        else
            echo_warn "musl-gcc detected, but rustup is not available."
            echo_warn "Skipping Linux build..."
            LINUX_TARGET=""
        fi
    fi
    
    if [[ -n "$LINUX_TARGET" && -f "target/${LINUX_TARGET}/release/jumper" ]]; then
        echo_info "Linux build successful"
        
        mkdir -p pkg
        cp "target/${LINUX_TARGET}/release/jumper" pkg/jumper
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
elif check_cross; then
    echo_info "Using cross (Docker-based build)..."
    
    # Find cross binary
    CROSS_BIN="cross"
    if [[ ! -x "$CROSS_BIN" ]] && [[ -x "$HOME/.cargo/bin/cross" ]]; then
        CROSS_BIN="$HOME/.cargo/bin/cross"
    fi
    
    # Find rustup binary
    RUSTUP_BIN="rustup"
    if ! command -v rustup &> /dev/null && [[ -x "$HOME/.cargo/bin/rustup" ]]; then
        RUSTUP_BIN="$HOME/.cargo/bin/rustup"
    fi
    
    # Pre-add the target
    echo_info "Adding Linux target..."
    if ! "$RUSTUP_BIN" target add x86_64-unknown-linux-gnu 2>/dev/null; then
        "$RUSTUP_BIN" target add x86_64-unknown-linux-gnu --force-non-host 2>/dev/null || true
    fi
    
    # Build with cross (requires rustup installation, not just rustup binary)
    # Note: This may fail if Rust was installed via Homebrew instead of rustup
    export RUSTUP_HOME="${RUSTUP_HOME:-$HOME/.rustup}"
    export CARGO_HOME="${CARGO_HOME:-$HOME/.cargo}"
    
    if "$CROSS_BIN" build --release --target=x86_64-unknown-linux-gnu 2>/dev/null; then
        if [[ -f "target/x86_64-unknown-linux-gnu/release/jumper" ]]; then
            echo_info "Linux build successful (via cross)"
            
            mkdir -p pkg
            cp target/x86_64-unknown-linux-gnu/release/jumper pkg/jumper
            cp install.sh pkg/install.sh
            cp jumper.sh pkg/jumper.sh
            
            cd pkg
            chmod +x jumper install.sh jumper.sh
            tar -zcvf ../target/jumper-Linux-x86_64.tar.gz jumper install.sh jumper.sh
            cd ..
            rm -rf pkg
        fi
    else
        echo_warn "cross build failed."
        echo_warn ""
        echo_warn "This usually happens when Rust was installed via Homebrew instead of rustup."
        echo_warn "For reliable Linux cross-compilation, install musl-cross:"
        echo_warn "  brew install FiloSottile/musl-cross/musl-cross"
        echo_warn ""
        echo_warn "Skipping Linux build..."
    fi
else
    echo_warn "Linux cross-compiler not found."
    echo_warn ""
    echo_warn "To build Linux binaries, you need one of:"
    echo_warn "  1. Native cross-compiler (recommended for macOS):"
    echo_warn "       brew install FiloSottile/musl-cross/musl-cross"
    echo_warn ""
    echo_warn "  2. Cross (Docker-based):"
    echo_warn "       - Install Docker: https://www.docker.com/get-started/"
    echo_warn "       - Install rustup: curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh"
    echo_warn "       - Install cross:  cargo install cross"
    echo_warn ""
    
    if [[ -x "$HOME/.cargo/bin/cross" ]]; then
        if ! docker info &> /dev/null 2>&1; then
            echo_warn "Note: 'cross' is installed but Docker is not running."
            echo_warn "      Start Docker Desktop or install Docker."
        elif ! command -v rustup &> /dev/null; then
            echo_warn "Note: 'cross' is installed but 'rustup' is not available."
            echo_warn "      Cross requires rustup to manage toolchains."
            echo_warn "      Install rustup: curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh"
        fi
    fi
    
    echo_warn ""
    echo_warn "Skipping Linux build..."
fi

# Build macOS targets
echo ""
echo "Building macOS targets..."

# macOS x86_64
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
fi

# macOS ARM64 (Apple Silicon)
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

echo ""
echo_info "Package artifacts created in target/:"
ls -lh target/*.tar.gz 2>/dev/null || echo_warn "No packages created"
echo ""
echo "Done!"
