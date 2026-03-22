use std::fs;
use std::path::PathBuf;
use std::sync::{Mutex, OnceLock};
use tempfile::tempdir;

use jumper::config::Config;
use jumper::jumper::Jumper;
use jumper::store::Store;

/// Global mutex to ensure tests run with isolated environment variables.
static ENV_MUTEX: OnceLock<Mutex<()>> = OnceLock::new();

fn get_env_mutex() -> &'static Mutex<()> {
    ENV_MUTEX.get_or_init(|| Mutex::new(()))
}

/// Helper to create a test Jumper instance with a temp home and workspace.
/// Each test gets its own isolated environment.
fn setup_test_jumper() -> (
    Jumper,
    tempfile::TempDir,
    tempfile::TempDir,
    std::sync::MutexGuard<'static, ()>,
) {
    // Acquire mutex to prevent concurrent tests from interfering with env vars
    let _guard = get_env_mutex().lock().unwrap();

    let home_dir = tempdir().unwrap();
    let workspace_dir = tempdir().unwrap();

    // Use canonical paths to avoid symlink issues on macOS (/var -> /private/var)
    let home_path = home_dir.path().canonicalize().unwrap();
    let workspace_path = workspace_dir.path().canonicalize().unwrap();

    // Set up environment variables
    std::env::set_var("JUMPER_HOME", &home_path);
    std::env::set_var("JUMPER_WORKSPACE", &workspace_path);
    std::env::set_var("JUMPER_DEPTH", "3");

    // Ensure home directory exists for store
    fs::create_dir_all(&home_path).unwrap();

    let j = Jumper::new().expect("Failed to create Jumper instance");
    (j, home_dir, workspace_dir, _guard)
}

#[test]
fn test_add_and_goto() {
    let (j, _home, _workspace, _guard) = setup_test_jumper();

    // Create a test directory using the env var path (which is canonical)
    let workspace = std::env::var("JUMPER_WORKSPACE")
        .map(PathBuf::from)
        .unwrap();
    let test_dir = workspace.join("test_project");
    fs::create_dir_all(&test_dir).unwrap();

    // Add the directory
    let msg = j.add("test", &test_dir).unwrap();
    assert!(msg.contains("Registered 'test'"));

    // Goto should return the same path
    let path = j.goto("test").unwrap();
    assert_eq!(path, test_dir.canonicalize().unwrap());
}

#[test]
fn test_alias() {
    let (j, _home, _workspace, _guard) = setup_test_jumper();

    let workspace = std::env::var("JUMPER_WORKSPACE")
        .map(PathBuf::from)
        .unwrap();

    // Create a test directory
    let test_dir = workspace.join("frontend");
    fs::create_dir_all(&test_dir).unwrap();

    // Add and create alias
    j.add("frontend", &test_dir).unwrap();
    let alias_path = j.alias("fe", "frontend").unwrap();

    assert_eq!(alias_path, test_dir.canonicalize().unwrap());

    // Goto using alias should work
    let path = j.goto("fe").unwrap();
    assert_eq!(path, test_dir.canonicalize().unwrap());
}

#[test]
fn test_list() {
    let (j, _home, _workspace, _guard) = setup_test_jumper();

    let workspace = std::env::var("JUMPER_WORKSPACE")
        .map(PathBuf::from)
        .unwrap();

    // Create test directories
    let dir1 = workspace.join("alpha");
    let dir2 = workspace.join("beta");
    fs::create_dir_all(&dir1).unwrap();
    fs::create_dir_all(&dir2).unwrap();

    j.add("alpha", &dir1).unwrap();
    j.add("beta", &dir2).unwrap();

    let entries = j.list().unwrap();
    assert_eq!(entries.len(), 2);
    assert_eq!(entries[0].0, "alpha");
    assert_eq!(entries[1].0, "beta");
}

#[test]
fn test_remove() {
    let (j, _home, _workspace, _guard) = setup_test_jumper();

    let workspace = std::env::var("JUMPER_WORKSPACE")
        .map(PathBuf::from)
        .unwrap();

    // Create and add a test directory
    let test_dir = workspace.join("to_remove");
    fs::create_dir_all(&test_dir).unwrap();

    j.add("remove_me", &test_dir).unwrap();

    // Verify it exists
    let entries = j.list().unwrap();
    assert!(entries.iter().any(|(name, _)| name == "remove_me"));

    // Remove it
    let msg = j.remove("remove_me").unwrap();
    assert!(msg.contains("Removed 'remove_me'"));

    // Verify it's gone
    let entries = j.list().unwrap();
    assert!(!entries.iter().any(|(name, _)| name == "remove_me"));
}

#[test]
fn test_remove_non_existent() {
    let (j, _home, _workspace, _guard) = setup_test_jumper();

    let result = j.remove("non_existent");
    assert!(result.is_err());
    assert!(result
        .unwrap_err()
        .to_string()
        .contains("is not registered"));
}

#[test]
fn test_assemble() {
    let (j, _home, _workspace, _guard) = setup_test_jumper();

    // Create a subdirectory in the workspace (depth=1)
    let workspace = std::env::var("JUMPER_WORKSPACE")
        .map(PathBuf::from)
        .unwrap();
    let nested_dir = workspace.join("myapp");
    fs::create_dir_all(&nested_dir).unwrap();

    // Canonicalize to match what the search will return
    let nested_dir_canonical = nested_dir.canonicalize().unwrap();

    // Assemble should find and register it
    let path = j.assemble("myapp").unwrap();
    assert_eq!(path, nested_dir_canonical);

    // Subsequent goto should find it in store
    let path2 = j.goto("myapp").unwrap();
    assert_eq!(path2, nested_dir_canonical);
}

#[test]
fn test_assemble_not_found() {
    let (j, _home, _workspace, _guard) = setup_test_jumper();

    let result = j.assemble("nonexistent_directory_xyz");
    assert!(result.is_err());
    assert!(result.unwrap_err().to_string().contains("Cannot find"));
}

#[test]
fn test_add_non_directory() {
    let (j, _home, _workspace, _guard) = setup_test_jumper();

    let workspace = std::env::var("JUMPER_WORKSPACE")
        .map(PathBuf::from)
        .unwrap();
    let fake_path = workspace.join("does_not_exist");
    let result = j.add("fake", &fake_path);
    assert!(result.is_err());
    assert!(result.unwrap_err().to_string().contains("does not exist"));
}

#[test]
fn test_store_roundtrip() {
    let dir = tempdir().unwrap();
    let home = dir.path().to_path_buf();
    let store = Store::new(&home);

    let mut data = store.load().unwrap();
    data.set("foo".into(), "/tmp".into());
    store.save(&data).unwrap();

    let data2 = store.load().unwrap();
    assert_eq!(data2.get("foo"), Some("/tmp"));
}

#[test]
fn test_config_defaults() {
    // Clear env vars to test defaults
    let _guard = get_env_mutex().lock().unwrap();
    std::env::remove_var("JUMPER_HOME");
    std::env::remove_var("JUMPER_WORKSPACE");
    std::env::remove_var("JUMPER_DEPTH");

    // Ensure Config::load works without env vars (uses HOME from OS)
    let cfg = Config::load().expect("config loads");
    assert!(cfg.home.is_dir() || !cfg.home.exists());
    assert!(cfg.workspace.is_dir());
    assert!(cfg.depth >= 1);
}
