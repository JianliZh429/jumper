use anyhow::Result;
use std::fs;
use std::path::{Path, PathBuf};
use walkdir::{DirEntry, WalkDir};

fn is_hidden(entry: &DirEntry) -> bool {
    entry
        .file_name()
        .to_str()
        .map(|s| s.starts_with('.'))
        .unwrap_or(false)
}

fn skip_dir(name: &str) -> bool {
    matches!(
        name,
        ".git" | ".hg" | ".svn" | "node_modules" | "target" | ".idea" | ".DS_Store"
    )
}

pub fn find(workspace: &Path, depth: usize, name: &str) -> Result<Vec<PathBuf>> {
    let mut matched = Vec::new();
    for entry in WalkDir::new(workspace)
        .max_depth(depth)
        .follow_links(true)
        .into_iter()
        .filter_entry(|e| {
            let fname = e.file_name().to_string_lossy();
            !is_hidden(e) && !skip_dir(&fname)
        })
    {
        let entry = match entry { Ok(e) => e, Err(_) => continue };
        let path = entry.path();
        if let Ok(metadata) = fs::metadata(path) {
            if metadata.is_dir() {
                if let Some(fname) = path.file_name().and_then(|s| s.to_str()) {
                    if fname.trim() == name {
                        matched.push(path.to_path_buf());
                    }
                }
            }
        }
    }
    matched.sort();
    Ok(matched)
}