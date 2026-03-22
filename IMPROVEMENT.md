# Jumper - Improvement Plan

This document outlines potential improvements for the Jumper CLI tool.

---

## 1. Bug Fixes

### 1.1 Race Condition in `alias()` Function
**Location:** `src/jumper.rs:56-64`

The `alias()` function loads the store twice unnecessarily, and there's a potential race condition where the target could be deleted between the two loads.

```rust
pub fn alias(&self, alias: &str, name: &str) -> Result<PathBuf> {
    let store = self.store.load()?;  // First load
    let Some(target) = store.get(name).map(|s| s.to_string()) else {
        return Err(anyhow!("'{}' is not registered", name));
    };
    // write new alias
    let mut store2 = self.store.load()?;  // Second load - redundant
    store2.set(alias.to_string(), target.clone());
    self.store.save(&store2)?;
    Ok(PathBuf::from(target))
}
```

**Fix:** Load once and reuse:
```rust
pub fn alias(&self, alias: &str, name: &str) -> Result<PathBuf> {
    let mut store = self.store.load()?;
    let Some(target) = store.get(name).map(|s| s.to_string()) else {
        return Err(anyhow!("'{}' is not registered", name));
    };
    store.set(alias.to_string(), target.clone());
    self.store.save(&store)?;
    Ok(PathBuf::from(target))
}
```

### 1.2 Empty Test File
**Location:** `tests/main.rs`

The file is completely empty. Either add integration tests or remove the file.

---

## 2. Code Quality Improvements

### 2.1 Error Handling in Search
**Location:** `src/search.rs:32-35`

Silently swallowing errors in `WalkDir` iteration may hide important issues:

```rust
let entry = match entry {
    Ok(e) => e,
    Err(_) => continue,  // Error is ignored
};
```

**Suggestion:** Log the error or return it for critical failures (e.g., permission denied on root).

### 2.2 Store File Locking
**Location:** `src/store.rs:52-58`

The file lock is released when `f` goes out of scope, but explicit unlock before flush would be clearer:

```rust
f.lock_exclusive().ok();
let mut writer = BufWriter::new(&f);
serde_json::to_writer_pretty(&mut writer, store)?;
writer.flush()?;
f.unlock().ok();  // Explicit unlock
```

Consider using a proper file locking crate like `fd-lock` for better cross-platform support.

### 2.3 Config File Not Created Automatically
**Location:** `src/config.rs`

The config file is only read, never created. Users must manually create `~/.jumper/config.toml`. Consider generating a default config on first run.

---

## 3. Feature Enhancements

### 3.1 Remove Command
Add a `remove`/`rm` command to delete registered names or aliases:

```rust
Commands::Remove { name } => {
    j.remove(&name)?;
    println!("Removed '{}'", name);
}
```

### 3.2 List Command
Add a `list`/`ls` command to display all registered paths:

```
$ j list
blog       -> /Users/me/work/blog
fe         -> /Users/me/work/frontend
frontend   -> /Users/me/work/frontend
```

### 3.3 Interactive Mode
When multiple matches are found during `assemble`, prompt the user to select one instead of always choosing the first (sorted) match.

### 3.4 Fuzzy Search
Add fuzzy matching for directory names using a crate like `nucleo` or `fuzzy-matcher`.

### 3.5 Shell Completion
Generate shell completions for bash, zsh, and fish using clap's completion generation:

```rust
use clap::CommandFactory;
use clap_complete::{generate, Shell};
```

### 3.6 Recent Directories
Track recently visited directories and allow quick access via `j -` (like `cd -`).

---

## 4. Testing Improvements

### 4.1 Add Integration Tests
Create comprehensive integration tests in `tests/main.rs`:
- Test full workflow (add, goto, alias, assemble)
- Test error cases (invalid paths, non-existent names)
- Test concurrent access

### 4.2 Mock Environment Variables
Current tests use OS environment variables. Use `temp_env` crate to isolate tests:

```rust
#[test]
fn config_with_env_vars() {
    temp_env::with_var("JUMPER_DEPTH", Some("10"), || {
        let cfg = Config::load().unwrap();
        assert_eq!(cfg.depth, 10);
    });
}
```

### 4.3 Test Store Concurrency
Add tests for concurrent read/write to the store to verify file locking works correctly.

---

## 5. Documentation Improvements

### 5.1 Add Inline Documentation
Add rustdoc comments to public APIs:

```rust
/// Jumper is the main entry point for directory jumping.
///
/// It maintains a persistent store of name -> path mappings.
pub struct Jumper { ... }
```

### 5.2 Usage Examples in Help
The CLI help could include more examples:

```rust
#[command(
    name = "jumper",
    version,
    about = "Jump between directories by name",
    long_about = "Jumper lets you quickly navigate between directories...\n\n\
                  Examples:\n\
                    j my-project    # Jump to my-project\n\
                    jadd blog /path # Register a new path"
)]
```

---

## 6. Build & Distribution

### 6.1 CI/CD Pipeline
The `.github/workflows/` directory exists but is empty. Add a workflow for:
- Running tests on PR
- Building releases for macOS and Linux
- Publishing to crates.io

### 6.2 Cross-Platform Build
The `package.sh` script requires a cross-compiler for Linux builds. Consider using `cross` crate for easier cross-compilation:

```bash
cargo install cross
cross build --release --target=x86_64-unknown-linux-gnu
```

### 6.3 Homebrew Formula
Create a Homebrew formula for easier macOS installation.

### 6.4 AUR Package
Create an AUR package for Arch Linux users.

---

## 7. Performance Optimizations

### 7.1 Cache Search Results
The `assemble` command searches the filesystem every time. Cache results with a TTL or invalidate on file changes.

### 7.2 Lazy Store Loading
Currently the store is loaded on every command. Consider caching in memory for repeated calls.

---

## 8. Security Considerations

### 8.1 Path Traversal
Validate that registered paths don't escape the workspace (if desired):

```rust
pub fn add(&self, name: &str, path: &Path) -> Result<String> {
    if !path.is_dir() {
        return Err(anyhow!("{} is not a directory", path.display()));
    }
    // Optional: ensure path is within workspace
    // let canonical = path.canonicalize()?;
    // if !canonical.starts_with(&self.cfg.workspace) { ... }
    ...
}
```

### 8.2 Symlink Handling
The search follows symlinks (`follow_links(true)`). Consider making this configurable to avoid infinite loops or unintended directory traversal.

---

## 9. Configuration Improvements

### 9.1 TOML Config Schema
Document the config.toml schema in README:

```toml
# ~/.jumper/config.toml
home = "~/.jumper"
workspace = "~/projects"
depth = 5
```

### 9.2 Environment Variable Priority
Clarify priority order: env vars > config file > defaults. Currently this is implicit in the code.

---

## 10. User Experience

### 10.1 Better Error Messages
Some error messages could be more helpful:

```
// Current
"Cannot find 'frontend' under '/home/user'"

// Improved
"Cannot find 'frontend' under '/home/user'\n\
Hint: Try 'jassemble frontend' to search and register it"
```

### 10.2 Verbose/Debug Mode
Add a `--verbose` flag to show what's happening:

```
$ j --verbose assemble frontend
Searching /home/user (depth: 4)...
Found 2 matches:
  1. /home/user/projects/frontend
  2. /home/user/work/frontend
Selected: /home/user/projects/frontend
Registered 'frontend' -> /home/user/projects/frontend
```

### 10.3 Color Output
Add colored output using `colored` or `anstream` crate for better readability.

---

## Priority Recommendations

| Priority | Item | Effort |
|----------|------|--------|
| High | Fix alias() race condition | Low |
| High | Add remove/list commands | Medium |
| High | Add integration tests | Medium |
| Medium | Add shell completions | Low |
| Medium | Improve error messages | Low |
| Medium | Set up CI/CD pipeline | Medium |
| Low | Fuzzy search | High |
| Low | Interactive mode | Medium |
| Low | Caching layer | Medium |

---

## Quick Wins (Can be done in < 1 hour each)

1. Fix the `alias()` function to avoid double load
2. Add rustdoc comments to public APIs
3. Add `list` command
4. Add shell completions
5. Document config.toml schema in README
6. Remove or populate `tests/main.rs`
