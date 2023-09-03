#![allow(unused)]

use std::{
    env, fs,
    io::{BufWriter, Write},
    path::Path,
};

use clap::Parser;
use serde_json::{Result, Value};
use walkdir::{DirEntry, WalkDir};

struct Jumper {
    routes: String,
}

fn is_hidden(entry: &DirEntry) -> bool {
    entry
        .file_name()
        .to_str()
        .map(|s| s.starts_with("."))
        .unwrap_or(false)
}

impl Jumper {
    fn default() -> Self {
        Jumper {
            routes: "routes.json".to_string(),
        }
    }

    pub fn goto(&self, dir: &String) -> String {
        let jumpers = self
            .load_routes()
            .expect("Could not load routes for jumper.");
        if !jumpers.is_null() {
            let path = &jumpers[dir];
            println!("{}", path);
            return path.to_string();
        }
        return "".to_string();
    }
    pub fn assemble(&self, dir: &String) -> String {
        // let workspace = self.workspace();
        let path = self.find(&dir);
        if !path.is_empty() {
            self.add_route(&dir, &path);
            return path;
        }
        return "".to_string();
    }
    pub fn add(&self, dir: &String, path: &String) -> std::io::Result<()> {
        self.add_route(&dir, &path)
    }
    pub fn shortcut(&self, shortcut: &str, filename: &str) -> Result<()> {
        return Ok(());
    }

    fn find(&self, dir: &String) -> String {
        let workspace = self.workspace();
        let workspace_path = Path::new(workspace.as_str());
        let mut matched = Vec::new();
        let walker = WalkDir::new(workspace_path)
            .max_depth(self.depth())
            .follow_links(true)
            .into_iter();
        for entry in walker.filter_entry(|e| !is_hidden(e)) {
            match entry {
                Ok(entry) => {
                    let path = entry.path();
                    let metadata = fs::metadata(&path).unwrap();
                    if metadata.is_dir() {
                        let filename = path.file_name().unwrap().to_str().unwrap();
                        if dir.eq(filename.trim()) {
                            matched.push(path.to_str().unwrap().to_string())
                        }
                    }
                }
                Err(e) => continue,
            }
        }
        if matched.len() == 0 {
            println!("Can not find '{}' in '{}'", dir, workspace);
            return "".to_string();
        } else if matched.len() > 1 {
            println!(
                "Found multiple matches, will choose the first one. You can manually add others if needed.",
            );
            for m in matched.iter() {
                println!("{}", m);
            }
        }
        return matched.remove(0);
    }

    fn depth(&self) -> usize {
        return match env::var("JUMPER_DEPTH") {
            Ok(v) => v.parse().unwrap(),
            Err(err) => {
                panic!("JUMPER_DEPTH variable is not set")
            }
        };
    }
    fn workspace(&self) -> String {
        return match env::var("JUMPER_WORKSPACE") {
            Ok(v) => v,
            Err(err) => {
                panic!("JUMPER_WORKSPACE variable is not set")
            }
        };
    }
    fn home(&self) -> String {
        match env::var("JUMPER_HOME") {
            Ok(v) => {
                return v;
            }
            Err(err) => {
                panic!("JUMPER_HOME is not set")
            }
        }
    }
    fn load_routes(&self) -> Result<Value> {
        let filepath = Path::new(&self.home()).join(self.routes.as_str());
        return match fs::read_to_string(&filepath) {
            Ok(value) => {
                let json: serde_json::Value =
                    serde_json::from_str(&value).expect("JSON was not well-formatted");
                Ok(json)
            }
            Err(err) => {
                println!("Datastore file not existed, create a new one");
                let mut file = fs::File::create(filepath).expect("Create routes.json file failed");
                file.write_all(b"{}");
                Ok(serde_json::Value::String("{}".to_string()))
            }
        };
    }
    fn add_route(&self, dir: &String, path: &String) -> std::io::Result<()> {
        let mut routes = self.load_routes().expect("Failed to load routes");
        routes[dir] = Value::from(path.as_str());
        let filepath = Path::new(&self.home()).join(self.routes.as_str());
        let mut fs = fs::File::create(filepath).expect("Can not open routes file");
        serde_json::to_writer_pretty(&mut fs, &routes);
        fs.flush()?;
        Ok(())
    }
}

fn main() {
    let args: Vec<String> = env::args().collect();
    let command = args[1].as_str();
    let jumper = Jumper::default();
    match command {
        "goto" => {
            let dir = &args[2];
            jumper.goto(dir);
        }
        "assemble" => {
            let dir = &args[2];
            jumper.assemble(dir);
        }
        "add" => {
            let dir = &args[2];
            let path = &args[3];
            jumper.add(dir, path);
        }
        _ => println!("Unrecognized command: {}", command),
    }
}
