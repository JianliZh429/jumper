use anyhow::Result;
use clap::{CommandFactory, Parser, Subcommand};
use clap_complete::engine::{ArgValueCompleter, CompletionCandidate};
use clap_complete::env::CompleteEnv;
use clap_complete::{generate, Shell};
use env_logger::Env;
use log::error;
use std::io;
use std::path::Path;

use jumper::jumper::Jumper;
use jumper::store::Store;

/// Get all registered directory names for shell completion.
fn get_registered_names() -> Vec<String> {
    let home = std::env::var("JUMPER_HOME").unwrap_or_else(|_| {
        directories::BaseDirs::new()
            .map(|d| d.home_dir().join(".jumper").to_string_lossy().to_string())
            .unwrap_or_else(|| "~/.jumper".to_string())
    });
    let store = Store::new(Path::new(&home));
    match store.load() {
        Ok(route_store) => route_store.routes.into_keys().collect(),
        Err(_) => Vec::new(),
    }
}

fn complete_registered_names(_current: &std::ffi::OsStr) -> Vec<CompletionCandidate> {
    let names = get_registered_names();
    names.into_iter().map(CompletionCandidate::new).collect()
}

#[derive(Debug, Parser)]
#[command(
    name = "jumper",
    bin_name = "jumper",
    version,
    about = "Jump between directories by name",
    long_about = "Jumper is a CLI tool that lets you quickly navigate between directories by name.\n\n\
                  It maintains a persistent map of names to absolute paths and can auto-discover \
                  folders in your workspace.\n\n\
                  Common usage:\n  \
                    j <name>       - Jump to a registered directory\n  \
                    jadd <name> <path> - Register a new directory\n  \
                    jlist          - List all registered directories\n\n\
                  For more information, see: https://github.com/JianliZh429/jumper"
)]
struct Cli {
    #[command(subcommand)]
    command: Commands,
}

#[derive(Debug, Subcommand)]
enum Commands {
    /// Jump to a registered directory (or workspace root if no name given)
    #[command(visible_alias = "g")]
    Goto {
        /// Directory name to jump to. If omitted, jumps to workspace root.
        #[arg(default_value = "", value_name = "NAME")]
        #[arg(add = ArgValueCompleter::new(complete_registered_names))]
        name: String,
    },
    /// Find a directory by name and register it
    #[command(visible_alias = "a")]
    Assemble {
        /// Directory name to search for
        #[arg(value_name = "NAME")]
        name: String,
    },
    /// Register a directory with a custom name
    #[command(visible_alias = "add")]
    Add {
        /// Name to register the directory under
        name: String,
        /// Absolute path to the directory
        path: String,
    },
    /// Create an alias for an existing registration
    #[command(visible_alias = "al")]
    Alias {
        /// Shortcut name (alias)
        alias: String,
        /// Existing registered directory name
        name: String,
    },
    /// List all registered directories and aliases
    #[command(visible_alias = "ls")]
    List,
    /// Remove a registered directory or alias
    #[command(visible_alias = "rm")]
    Remove {
        /// Name to remove
        name: String,
    },
    /// Generate shell completion script for bash, zsh, or fish
    Completions {
        /// Shell type
        shell: Shell,
    },
    /// Output registered names for shell completion (internal use)
    #[command(hide = true)]
    Complete,
}

fn main() {
    // Handle dynamic shell completion BEFORE any output
    CompleteEnv::with_factory(Cli::command).complete();

    env_logger::Builder::from_env(Env::default().default_filter_or("warn")).init();
    if let Err(err) = run() {
        error!("{err:#}");
        std::process::exit(1);
    }
}

fn run() -> Result<()> {
    let cli = Cli::parse();
    let j = Jumper::new()?;

    // Validate workspace directory accessibility for commands that need it
    if matches!(
        cli.command,
        Commands::Assemble { .. } | Commands::Goto { .. }
    ) {
        let cfg = jumper::config::Config::load()?;
        if !cfg.workspace.exists() {
            return Err(anyhow::anyhow!(
                "Workspace directory '{}' does not exist.\n\
                Hint: Set a valid workspace with JUMPER_WORKSPACE environment variable:\n  \
                  export JUMPER_WORKSPACE=/path/to/your/workspace",
                cfg.workspace.display()
            ));
        }
        if let Err(e) = std::fs::read_dir(&cfg.workspace) {
            return Err(anyhow::anyhow!(
                "Cannot access workspace directory '{}': {}\n\
                Hint: Set a valid workspace with JUMPER_WORKSPACE environment variable:\n  \
                  export JUMPER_WORKSPACE=/path/to/your/workspace\n  \
                Or set it permanently in ~/.jumper/config.toml:\n  \
                  workspace = \"/path/to/your/workspace\"",
                cfg.workspace.display(),
                e
            ));
        }
    }

    match cli.command {
        Commands::Goto { name } => {
            if name.is_empty() {
                // No name given, jump to workspace root
                let cfg = jumper::config::Config::load()?;
                println!("{}", cfg.workspace.display());
            } else {
                let p = j.goto(&name)?;
                println!("{}", p.display());
            }
        }
        Commands::Assemble { name } => {
            let p = j.assemble(&name)?;
            println!("{}", p.display());
        }
        Commands::Add { name, path } => {
            let msg = j.add(&name, Path::new(&path))?;
            println!("{}", msg);
        }
        Commands::Alias { alias, name } => {
            let p = j.alias(&alias, &name)?;
            println!("{}", p.display());
        }
        Commands::List => {
            let entries = j.list()?;
            if entries.is_empty() {
                println!("No registered directories");
            } else {
                for (name, path) in entries {
                    println!("{:<15} -> {}", name, path);
                }
            }
        }
        Commands::Remove { name } => {
            let msg = j.remove(&name)?;
            println!("{}", msg);
        }
        Commands::Completions { shell } => {
            let mut cmd = Cli::command();
            generate(shell, &mut cmd, "jumper", &mut io::stdout());
        }
        Commands::Complete => {
            // Output registered names for shell completion
            for name in get_registered_names() {
                println!("{}", name);
            }
        }
    }
    Ok(())
}
