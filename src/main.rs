use anyhow::Result;
use clap::{CommandFactory, Parser, Subcommand};
use clap_complete::{generate, Shell};
use env_logger::Env;
use log::error;
use std::io;
use std::path::Path;

use jumper::jumper::Jumper;

#[derive(Debug, Parser)]
#[command(name = "jumper", version, about = "Jump between directories by name")]
struct Cli {
    #[command(subcommand)]
    command: Commands,
}

#[derive(Debug, Subcommand)]
enum Commands {
    Goto {
        name: String,
    },
    Assemble {
        name: String,
    },
    Add {
        name: String,
        path: String,
    },
    Alias {
        alias: String,
        name: String,
    },
    List,
    Remove {
        name: String,
    },
    /// Generate shell completion script
    Completions {
        shell: Shell,
    },
}

fn main() {
    env_logger::Builder::from_env(Env::default().default_filter_or("warn")).init();
    if let Err(err) = run() {
        error!("{err:#}");
        std::process::exit(1);
    }
}

fn run() -> Result<()> {
    let cli = Cli::parse();
    let j = Jumper::new()?;
    match cli.command {
        Commands::Goto { name } => {
            let p = j.goto(&name)?;
            println!("{}", p.display());
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
    }
    Ok(())
}
