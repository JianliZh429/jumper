use crate::config::Config;
use crate::search;
use crate::store::Store;
use anyhow::{anyhow, Result};
use std::path::{Path, PathBuf};

#[derive(Debug)]
pub struct Jumper {
    cfg: Config,
    store: Store,
}

impl Jumper {
    pub fn new() -> Result<Self> {
        let cfg = Config::load()?;
        let store = Store::new(&cfg.home);
        Ok(Self { cfg, store })
    }

    pub fn goto(&self, name: &str) -> Result<PathBuf> {
        let store = self.store.load()?;
        if let Some(p) = store.get(name) {
            return Ok(PathBuf::from(p));
        }
        // fallback to assemble
        self.assemble(name)
    }

    pub fn assemble(&self, name: &str) -> Result<PathBuf> {
        let matches = search::find(&self.cfg.workspace, self.cfg.depth, name)?;
        if matches.is_empty() {
            return Err(anyhow!(
                "Cannot find '{}' under '{}'",
                name,
                self.cfg.workspace.display()
            ));
        }
        let chosen = matches[0].clone();
        // persist
        let mut store = self.store.load()?;
        store.set(name.to_string(), chosen.to_string_lossy().to_string());
        self.store.save(&store)?;
        Ok(chosen)
    }

    pub fn add(&self, name: &str, path: &Path) -> Result<String> {
        if !path.is_dir() {
            return Err(anyhow!("{} is not a directory", path.display()));
        }
        let mut store = self.store.load()?;
        store.set(name.to_string(), path.to_string_lossy().to_string());
        self.store.save(&store)?;
        Ok(format!("Registered '{}' -> {}", name, path.display()))
    }

    pub fn alias(&self, alias: &str, name: &str) -> Result<PathBuf> {
        let mut store = self.store.load()?;
        let Some(target) = store.get(name).map(|s| s.to_string()) else {
            return Err(anyhow!("'{}' is not registered", name));
        };
        store.set(alias.to_string(), target.clone());
        self.store.save(&store)?;
        Ok(PathBuf::from(target))
    }

    pub fn list(&self) -> Result<Vec<(String, String)>> {
        let store = self.store.load()?;
        let mut entries: Vec<(String, String)> = store.routes.into_iter().collect();
        entries.sort_by(|a, b| a.0.cmp(&b.0));
        Ok(entries)
    }

    pub fn remove(&self, name: &str) -> Result<String> {
        let mut store = self.store.load()?;
        if store.routes.remove(name).is_none() {
            return Err(anyhow!("'{}' is not registered", name));
        }
        self.store.save(&store)?;
        Ok(format!("Removed '{}'", name))
    }
}
