#![allow(unused)]

use clap::Parser;
use serde_json::{Result, Value};
use std::{
    env, fs,
    io::{BufWriter, Write},
    path::Path,
};

struct Jumper {
    routes: String,
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
        let path = self.search(&dir);
        if !path.is_empty() {
            self.add_route(&dir, &path);
            return path;
        }
        return "".to_string();
    }
    pub fn shortcut(&self, shortcut: &str, filename: &str) -> Result<()> {
        return Ok(());
    }
    fn search(&self, dir: &String) -> String {
        let workspace = self.workspace();
        let workspace_path = Path::new(workspace.as_str());
        let mut matched = Vec::new();
        for entry in fs::read_dir(workspace_path).unwrap() {
            let entry = entry.unwrap();
            let path = entry.path();
            let metadata = fs::metadata(&path).unwrap();
            if metadata.is_dir() {
                let filename = path.file_name().unwrap().to_str().unwrap();
                if dir.eq(filename) {
                    matched.push(path.to_str().unwrap().to_string())
                }
            }
        }
        if matched.len() == 0 {
            println!("Can tot find '{}' in '{}'", dir, workspace);
            return "".to_string();
        } else if matched.len() > 1 {
            println!(
                "Found multiple matches, will choose the first one. You can manually add others if needed.",
            );
            for m in matched.iter() {
                println!("{}", m);
            }
        }
        return matched.pop().unwrap();
    }

    fn workspace(&self) -> String {
        return match env::var("JUMPER_WORKSPACE") {
            Ok(v) => {
                v
            }
            Err(err) => {
                panic!("JUMPER_WORKSPACE variable is not set")
            }
        }
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
        println!("Filepath, {}", filepath.display());
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
        }
    }
    fn add_route(&self, dir: &String, path: &String) -> std::io::Result<()> {
        let mut routes = self.load_routes().expect("Failed to load routes");
        routes[dir] = Value::from(path.as_str());
        let filepath = Path::new(&self.home()).join(self.routes.as_str());
        let mut fs = fs::File::create(filepath).expect("Can not open routes file");
        // let mut wirter = BufWriter::new(fs);
        let vec = vec![1, 2, 3];
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
            jumper.goto(&dir);
        }
        "assemble" => {
            let dir = &args[2];
            jumper.assemble(&dir);
        }
        _ => println!("Unrecognized command: {}", command),
    }
}
