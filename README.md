# Jumper

A small CLI that lets you “jump” to directories by name. It keeps a persistent map of names -> absolute paths and can auto-discover folders in your workspace.

- Jump by name with `j <name>`
- Auto-assemble a name by scanning your workspace up to a configurable depth
- Manually add or alias names

## Requirements
- macOS or Linux (bash/zsh)
- Rust toolchain (for building from source): https://www.rust-lang.org/tools/install
- Optional for packaging: cross linker for Linux target (`x86_64-unknown-linux-gnu-gcc`)

## Quick start
1) Build the binary
```
# from repo root
cargo build --release
cp target/release/jumper ./jumper
chmod +x ./jumper
```

2) Install shell integration and defaults
```
./install.sh
# reload your shell so aliases and env vars take effect
exec "$SHELL" -l
```

3) Verify
```
j --help
```

## Usage
The installer defines helpful aliases:
- `j`        — jump; with no args it goes to your workspace base
- `jadd`     — register a name to a path
- `jassemble`— discover a folder by name under your workspace and register it
- `jalias`   — create an alias pointing at an existing registered name

Examples:
```
# go to workspace root
j

# jump to folder named "my-service" (registered or auto-discovered)
j my-service

# manually register a directory
jadd blog /Users/me/work/blog

# scan workspace for a directory named "frontend" and register it
jassemble frontend

# add a short alias for an existing name
jalias fe frontend
```
Behavior notes:
- If multiple directories match during assemble, all matches are printed and the first (sorted) is chosen.
- Errors occur if required environment variables are not set; the installer configures them for you.

## Configuration
Jumper uses the following environment variables (created by the installer in `~/.jumper/jumperrc`):
- `JUMPER_HOME`      — where Jumper stores its files (default: `~/.jumper`)
- `JUMPER_WORKSPACE` — base directory to search when assembling (default: `$HOME`)
- `JUMPER_DEPTH`     — max recursive depth when assembling (default: `4`)

To customize, edit `~/.jumper/jumperrc`, then reload your shell:
```
exec "$SHELL" -l
```

## Data store
Mappings are saved as JSON in `$JUMPER_HOME/routes.json`, e.g.:
```
{
  "blog": "/Users/me/work/blog",
  "fe": "/Users/me/work/frontend",
  "frontend": "/Users/me/work/frontend"
}
```
Delete this file to reset all registrations.

## Build and package
Build natively:
```
cargo build --release
```
Create tarballs for macOS and Linux (requires cross linker for Linux):
```
./package.sh
# artifacts in target/jumper-*.tar.gz
```
Each archive contains: `jumper` (binary), `install.sh`, and `jumper.sh`.

## Troubleshooting
- “JUMPER_* variable is not set”: ensure your shell sourced `~/.jumper/jumperrc` (relaunch or `exec "$SHELL" -l`).
- “not a valid directory”: ensure the target exists or register it with `jadd`.
- On first run Jumper will create an empty `routes.json` automatically.

## Development
Useful commands:
```
cargo fmt
cargo clippy -- -D warnings
cargo test
```
