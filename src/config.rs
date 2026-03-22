use anyhow::{Context, Result};
use directories::BaseDirs;
use serde::{Deserialize, Serialize};
use std::env;
use std::fs;
use std::path::PathBuf;

/// Configuration for Jumper.
///
/// Contains the home directory for storing data, the workspace directory
/// to search, and the maximum depth for recursive searches.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Config {
    pub home: PathBuf,
    pub workspace: PathBuf,
    pub depth: usize,
}

impl Config {
    /// Load configuration from environment variables or config file.
    ///
    /// Priority order: environment variables > config.toml > defaults.
    pub fn load() -> Result<Self> {
        let base = BaseDirs::new().context("Could not determine home directory")?;
        let default_home = base.home_dir().join(".jumper");
        let home = env::var("JUMPER_HOME")
            .map(PathBuf::from)
            .unwrap_or(default_home);
        let default_workspace = base.home_dir().to_path_buf();
        let workspace = env::var("JUMPER_WORKSPACE")
            .map(PathBuf::from)
            .unwrap_or(default_workspace);
        let depth = env::var("JUMPER_DEPTH")
            .ok()
            .and_then(|v| v.parse::<usize>().ok())
            .unwrap_or(4);

        // Optional config file overrides
        let cfg_path = home.join("config.toml");
        if cfg_path.exists() {
            let s = fs::read_to_string(&cfg_path)
                .with_context(|| format!("reading {}", cfg_path.display()))?;
            let file_cfg: PartialConfig =
                toml::from_str(&s).with_context(|| format!("parsing {}", cfg_path.display()))?;
            return Ok(Config {
                home: file_cfg.home.unwrap_or(home),
                workspace: file_cfg.workspace.unwrap_or(workspace),
                depth: file_cfg.depth.unwrap_or(depth),
            });
        }

        Ok(Config {
            home,
            workspace,
            depth,
        })
    }
}

#[derive(Debug, Clone, Serialize, Deserialize, Default)]
struct PartialConfig {
    home: Option<PathBuf>,
    workspace: Option<PathBuf>,
    depth: Option<usize>,
}
