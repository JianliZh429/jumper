# Troubleshooting Guide

Common issues and solutions for Jumper.

## Installation Issues

### "command not found: j"

**Problem:** The `j` command is not recognized.

**Solutions:**

1. **Ensure installer was run:**
   ```bash
   ./install.sh
   ```

2. **Reload your shell:**
   ```bash
   exec "$SHELL" -l
   ```

3. **Check if jumperrc is sourced:**
   ```bash
   grep -q "jumperrc" ~/.zshrc || grep -q "jumperrc" ~/.bashrc
   ```

4. **Manually source jumperrc:**
   ```bash
   source ~/.jumper/jumperrc
   ```

### "JUMPER_HOME variable is not set"

**Problem:** Environment variables are not configured.

**Solution:**

```bash
# Source the jumperrc file
source ~/.jumper/jumperrc

# Or add to your shell config
echo 'source ~/.jumper/jumperrc' >> ~/.zshrc
exec "$SHELL" -l
```

## Navigation Issues

### "is not a valid directory"

**Problem:** The directory doesn't exist or was moved/deleted.

**Solutions:**

1. **Verify the path exists:**
   ```bash
   ls -la /path/to/directory
   ```

2. **Update the registration:**
   ```bash
   jremove <name>
   jadd <name> /new/path
   ```

3. **Check routes.json for stale entries:**
   ```bash
   cat ~/.jumper/routes.json
   ```

### "Cannot find 'name' under 'workspace'"

**Problem:** `jassemble` couldn't find the directory.

**Solutions:**

1. **Verify the directory exists:**
   ```bash
   find ~/projects -type d -name "dirname"
   ```

2. **Increase search depth:**
   ```bash
   export JUMPER_DEPTH=6
   jassemble dirname
   ```

3. **Manually register instead:**
   ```bash
   jadd dirname /full/path/to/dirname
   ```

4. **Check if directory is being skipped:**
   - Hidden directories (starting with `.`) are skipped
   - Common directories like `.git`, `node_modules`, `target` are skipped

### Multiple Directories Found

**Problem:** Multiple directories match during assemble.

**Behavior:** Jumper selects the first match (alphabetically sorted) and registers it.

**Solution:** Use `jadd` to register the specific path you want:

```bash
jadd myname /specific/path/to/directory
```

## Configuration Issues

### Changes Not Taking Effect

**Problem:** Configuration changes aren't applied.

**Solutions:**

1. **Reload shell:**
   ```bash
   exec "$SHELL" -l
   ```

2. **Check priority order:**
   - Environment variables override config.toml
   - Check with: `echo $JUMPER_WORKSPACE`

3. **Verify config file syntax:**
   ```bash
   cat ~/.jumper/config.toml
   ```

### Wrong Workspace Directory

**Problem:** Searching in the wrong directory.

**Solution:**

```bash
# Check current workspace
echo $JUMPER_WORKSPACE

# Set correct workspace
export JUMPER_WORKSPACE=~/projects

# Make permanent in jumperrc
sed -i '' 's|JUMPER_WORKSPACE=.*|JUMPER_WORKSPACE=~/projects|' ~/.jumper/jumperrc
source ~/.jumper/jumperrc
```

## Data Issues

### Lost Registrations

**Problem:** Your registered directories are gone.

**Solutions:**

1. **Check if routes.json exists:**
   ```bash
   ls -la ~/.jumper/routes.json
   ```

2. **Check file contents:**
   ```bash
   cat ~/.jumper/routes.json
   ```

3. **Restore from backup if available**

4. **Re-register directories:**
   ```bash
   jadd name /path/to/directory
   ```

### Corrupted routes.json

**Problem:** JSON parsing errors.

**Symptoms:**
```
Error: parse JSON in ~/.jumper/routes.json
```

**Solution:**

```bash
# Backup the corrupted file
cp ~/.jumper/routes.json ~/.jumper/routes.json.bak

# Create a new empty store
echo '{}' > ~/.jumper/routes.json

# Re-register your directories
jadd name /path/to/directory
```

### Reset All Registrations

**Problem:** Want to start fresh.

**Solution:**

```bash
# Delete the routes file
rm ~/.jumper/routes.json

# Jumper will create a new empty one on next use
jlist  # Should show "No registered directories"
```

## Performance Issues

### Slow Directory Search

**Problem:** `jassemble` takes too long.

**Solutions:**

1. **Reduce search depth:**
   ```bash
   export JUMPER_DEPTH=2
   ```

2. **Narrow workspace:**
   ```bash
   export JUMPER_WORKSPACE=~/projects
   ```

3. **Use `jadd` instead of `jassemble`** for known paths

## Shell Issues

### Aliases Not Working

**Problem:** `jadd`, `jassemble`, etc. don't work.

**Solution:**

```bash
# Check if aliases are defined
alias | grep jumper

# Re-source jumperrc
source ~/.jumper/jumperrc

# Or manually define
alias jadd='~/.jumper/jumper add'
alias jassemble='~/.jumper/jumper assemble'
alias jalias='~/.jumper/jumper alias'
alias jlist='~/.jumper/jumper list'
alias jremove='~/.jumper/jumper remove'
```

### zsh: command not found: _jumper

**Problem:** Shell completion not set up correctly.

**Solution:**

```bash
# Remove old completion
rm -f "${fpath[1]}/_jumper"

# Generate new completion
jumper completions zsh > "${fpath[1]}/_jumper"

# Reload shell
exec "$SHELL" -l
```

## Platform-Specific Issues

### macOS: /var vs /private/var

**Problem:** Symlink issues with temp directories.

**Note:** This is handled automatically in Jumper. If you encounter issues, use absolute paths with `jadd`.

### Linux: Missing Linker

**Problem:** Can't build Linux binary on macOS.

**Solution:**

```bash
# Install cross linker
brew install FiloSottile/musl-cross/musl-cross

# Or use pre-built binary
```

## Getting Help

### Enable Debug Logging

```bash
# Set log level
export RUST_LOG=debug
jumper goto mydir
```

### Check Version

```bash
jumper --version
```

### Report Issues

If you can't resolve an issue:

1. Check the [GitHub Issues](https://github.com/your-repo/jumper/issues)
2. Include:
   - OS and shell version
   - Jumper version
   - Error messages
   - Steps to reproduce

## Quick Reference

| Issue | Quick Fix |
|-------|-----------|
| Command not found | `source ~/.jumper/jumperrc` |
| Directory not found | `jadd name /correct/path` |
| Config not applied | `exec "$SHELL" -l` |
| Lost registrations | Check `~/.jumper/routes.json` |
| Slow search | Reduce `JUMPER_DEPTH` |
