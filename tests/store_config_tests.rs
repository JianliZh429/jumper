use tempfile::tempdir;

use jumper::config::Config;
use jumper::store::Store;

#[test]
fn config_defaults() {
    // Ensure Config::load works without env vars (uses HOME from OS)
    let cfg = Config::load().expect("config loads");
    assert!(cfg.home.is_dir() || !cfg.home.exists());
    assert!(cfg.workspace.is_dir());
    assert!(cfg.depth >= 1);
}

#[test]
fn store_roundtrip() {
    let dir = tempdir().unwrap();
    let home = dir.path().to_path_buf();
    let store = Store::new(&home);

    let mut data = store.load().unwrap();
    data.set("foo".into(), "/tmp".into());
    store.save(&data).unwrap();

    let data2 = store.load().unwrap();
    assert_eq!(data2.get("foo"), Some("/tmp"));
}
