use anyhow::{Context, Result};
use fs2::FileExt;
use serde::{Deserialize, Serialize};
use std::collections::BTreeMap;
use std::fs::{self, File};
use std::io::{BufReader, BufWriter, Write};
use std::path::{Path, PathBuf};

/// A route store containing mappings of names to paths.
#[derive(Debug, Clone, Serialize, Deserialize, Default)]
pub struct RouteStore {
    #[serde(flatten)]
    pub routes: BTreeMap<String, String>,
}

impl RouteStore {
    /// Get the path for a registered name.
    pub fn get(&self, name: &str) -> Option<&str> {
        self.routes.get(name).map(|s| s.as_str())
    }

    /// Set or update a name -> path mapping.
    pub fn set(&mut self, name: String, path: String) {
        self.routes.insert(name, path);
    }
}

/// A persistent store for directory routes.
///
/// Routes are stored as JSON in the home directory and are
/// locked during write operations to prevent concurrent modification.
#[derive(Debug, Clone)]
pub struct Store {
    file: PathBuf,
}

impl Store {
    /// Create a new Store with the given home directory.
    pub fn new(home: &Path) -> Self {
        Self {
            file: home.join("routes.json"),
        }
    }

    /// Load the route store from disk.
    ///
    /// Creates an empty store file if it doesn't exist.
    pub fn load(&self) -> Result<RouteStore> {
        if !self.file.exists() {
            if let Some(parent) = self.file.parent() {
                fs::create_dir_all(parent).ok();
            }
            let mut f = File::create(&self.file)
                .with_context(|| format!("create {}", self.file.display()))?;
            f.write_all(b"{}")?;
        }
        let f = File::open(&self.file).with_context(|| format!("open {}", self.file.display()))?;
        let reader = BufReader::new(f);
        let store: RouteStore = serde_json::from_reader(reader)
            .with_context(|| format!("parse JSON in {}", self.file.display()))?;
        Ok(store)
    }

    /// Save the route store to disk.
    ///
    /// Uses exclusive file locking to prevent concurrent writes.
    pub fn save(&self, store: &RouteStore) -> Result<()> {
        let f = File::options()
            .write(true)
            .truncate(true)
            .open(&self.file)
            .with_context(|| format!("open {} for write", self.file.display()))?;
        // lock during write
        f.lock_exclusive().ok();
        let mut writer = BufWriter::new(&f);
        serde_json::to_writer_pretty(&mut writer, store)?;
        writer.flush()?;
        f.unlock().ok();
        Ok(())
    }
}
