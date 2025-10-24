use std::env;
use std::fs;
use std::sync::Mutex;
use tempfile::{tempdir, TempDir};

use jumper::config::Config;
use jumper::jumper::Jumper;
use jumper::store::Store;

// Use a mutex to ensure tests don't interfere with each other's environment variables
static ENV_MUTEX: Mutex<()> = Mutex::new(());

fn setup_test_env() -> TempDir {
    let temp_dir = tempdir().unwrap();

    // Create some test directories
    let workspace = temp_dir.path().join("workspace");
    fs::create_dir_all(&workspace).unwrap();

    let test_dir = workspace.join("test_project");
    fs::create_dir_all(&test_dir).unwrap();

    let another_dir = workspace.join("another_project");
    fs::create_dir_all(&another_dir).unwrap();

    temp_dir
}

#[test]
fn test_config_load_with_env_vars() {
    let _lock = ENV_MUTEX.lock().unwrap();

    let temp_dir = tempdir().unwrap();
    let home_path = temp_dir.path().join("jumper_home");
    let workspace_path = temp_dir.path().join("workspace");
    fs::create_dir_all(&home_path).unwrap();
    fs::create_dir_all(&workspace_path).unwrap();

    // Set environment variables
    env::set_var("JUMPER_HOME", &home_path);
    env::set_var("JUMPER_WORKSPACE", &workspace_path);
    env::set_var("JUMPER_DEPTH", "5");

    let config = Config::load().unwrap();

    assert_eq!(config.home, home_path);
    assert_eq!(config.workspace, workspace_path);
    assert_eq!(config.depth, 5);

    // Clean up
    env::remove_var("JUMPER_HOME");
    env::remove_var("JUMPER_WORKSPACE");
    env::remove_var("JUMPER_DEPTH");
}

#[test]
fn test_config_load_defaults() {
    let _lock = ENV_MUTEX.lock().unwrap();

    // Ensure environment variables are not set
    env::remove_var("JUMPER_HOME");
    env::remove_var("JUMPER_WORKSPACE");
    env::remove_var("JUMPER_DEPTH");

    let config = Config::load().unwrap();

    // Should use default values
    assert!(config.home.to_string_lossy().contains(".jumper"));
    assert!(config.workspace.is_absolute());
    assert_eq!(config.depth, 4);
}

#[test]
fn test_jumper_goto_returns_pre_registered_path() {
    let _lock = ENV_MUTEX.lock().unwrap();

    let temp_dir = setup_test_env();
    let home_path = temp_dir.path().join("jumper_home");
    fs::create_dir_all(&home_path).unwrap();

    // Set up environment
    env::set_var("JUMPER_HOME", &home_path);
    env::set_var("JUMPER_WORKSPACE", temp_dir.path().join("workspace"));

    // Pre-register a path in the store
    let store = Store::new(&home_path);
    let mut route_store = store.load().unwrap(); // Load first to ensure file exists
    let registered_path = temp_dir.path().join("workspace").join("test_project");
    route_store.set(
        "test".to_string(),
        registered_path.to_string_lossy().to_string(),
    );
    store.save(&route_store).unwrap();

    // Test that goto returns the pre-registered path
    let jumper = Jumper::new().unwrap();
    let result = jumper.goto("test").unwrap();

    assert_eq!(result, registered_path);

    // Clean up
    env::remove_var("JUMPER_HOME");
    env::remove_var("JUMPER_WORKSPACE");
}

#[test]
fn test_jumper_assemble_finds_and_registers_directory() {
    let _lock = ENV_MUTEX.lock().unwrap();

    let temp_dir = setup_test_env();
    let home_path = temp_dir.path().join("jumper_home");
    fs::create_dir_all(&home_path).unwrap();

    // Set up environment
    env::set_var("JUMPER_HOME", &home_path);
    env::set_var("JUMPER_WORKSPACE", temp_dir.path().join("workspace"));
    env::set_var("JUMPER_DEPTH", "3");

    let jumper = Jumper::new().unwrap();
    let result = jumper.assemble("test_project").unwrap();

    // Should find and return the test_project directory
    let expected_path = temp_dir.path().join("workspace").join("test_project");
    assert_eq!(result, expected_path);

    // Verify it was registered in the store
    let store = Store::new(&home_path);
    let route_store = store.load().unwrap();
    assert_eq!(
        route_store.get("test_project"),
        Some(expected_path.to_string_lossy().as_ref())
    );

    // Clean up
    env::remove_var("JUMPER_HOME");
    env::remove_var("JUMPER_WORKSPACE");
    env::remove_var("JUMPER_DEPTH");
}

#[test]
fn test_jumper_add_registers_valid_directory() {
    let _lock = ENV_MUTEX.lock().unwrap();

    let temp_dir = setup_test_env();
    let home_path = temp_dir.path().join("jumper_home");
    fs::create_dir_all(&home_path).unwrap();

    // Set up environment
    env::set_var("JUMPER_HOME", &home_path);

    let jumper = Jumper::new().unwrap();
    let target_dir = temp_dir.path().join("workspace").join("test_project");

    let result = jumper.add("my_project", &target_dir).unwrap();

    // Check the return message
    assert!(result.contains("Registered 'my_project'"));
    assert!(result.contains(&target_dir.to_string_lossy().to_string()));

    // Verify it was registered in the store
    let store = Store::new(&home_path);
    let route_store = store.load().unwrap();
    assert_eq!(
        route_store.get("my_project"),
        Some(target_dir.to_string_lossy().as_ref())
    );

    // Clean up
    env::remove_var("JUMPER_HOME");
}

#[test]
fn test_jumper_add_rejects_non_directory() {
    let _lock = ENV_MUTEX.lock().unwrap();

    let temp_dir = setup_test_env();
    let home_path = temp_dir.path().join("jumper_home");
    fs::create_dir_all(&home_path).unwrap();

    // Set up environment
    env::set_var("JUMPER_HOME", &home_path);

    // Create a file (not a directory)
    let test_file = temp_dir.path().join("test_file.txt");
    fs::write(&test_file, "test content").unwrap();

    let jumper = Jumper::new().unwrap();
    let result = jumper.add("my_file", &test_file);

    // Should return an error
    assert!(result.is_err());
    assert!(result
        .unwrap_err()
        .to_string()
        .contains("is not a directory"));

    // Clean up
    env::remove_var("JUMPER_HOME");
}

#[test]
fn test_jumper_alias_creates_alias_to_existing_path() {
    let _lock = ENV_MUTEX.lock().unwrap();

    let temp_dir = setup_test_env();
    let home_path = temp_dir.path().join("jumper_home");
    fs::create_dir_all(&home_path).unwrap();

    // Set up environment
    env::set_var("JUMPER_HOME", &home_path);

    // Pre-register a path
    let store = Store::new(&home_path);
    let mut route_store = store.load().unwrap(); // Load first to ensure file exists
    let target_path = temp_dir.path().join("workspace").join("test_project");
    route_store.set(
        "original".to_string(),
        target_path.to_string_lossy().to_string(),
    );
    store.save(&route_store).unwrap();

    let jumper = Jumper::new().unwrap();
    let result = jumper.alias("alias_name", "original").unwrap();

    // Should return the path that the alias points to
    assert_eq!(result, target_path);

    // Verify the alias was created in the store
    let route_store = store.load().unwrap();
    assert_eq!(
        route_store.get("alias_name"),
        Some(target_path.to_string_lossy().as_ref())
    );
    assert_eq!(
        route_store.get("original"),
        Some(target_path.to_string_lossy().as_ref())
    );

    // Clean up
    env::remove_var("JUMPER_HOME");
}

#[test]
fn test_jumper_alias_fails_for_non_existing_path() {
    let _lock = ENV_MUTEX.lock().unwrap();

    let temp_dir = setup_test_env();
    let home_path = temp_dir.path().join("jumper_home");
    fs::create_dir_all(&home_path).unwrap();

    // Set up environment
    env::set_var("JUMPER_HOME", &home_path);

    let jumper = Jumper::new().unwrap();
    let result = jumper.alias("alias_name", "non_existent");

    // Should return an error
    assert!(result.is_err());
    assert!(result
        .unwrap_err()
        .to_string()
        .contains("is not registered"));

    // Clean up
    env::remove_var("JUMPER_HOME");
}
