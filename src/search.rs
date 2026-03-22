use anyhow::Result;
use std::fs;
use std::path::{Path, PathBuf};
use walkdir::{DirEntry, WalkDir};

/// Check if a directory entry is hidden (starts with a dot).
fn is_hidden(entry: &DirEntry) -> bool {
    entry
        .file_name()
        .to_str()
        .map(|s| s.starts_with('.'))
        .unwrap_or(false)
}

/// Check if a directory should be skipped during search.
fn skip_dir(name: &str) -> bool {
    matches!(
        name,
        ".git" | ".hg" | ".svn" | "node_modules" | "target" | ".idea" | ".DS_Store"
    )
}

/// Find all directories matching the given name within the workspace.
///
/// Searches recursively up to the specified depth, excluding hidden directories
/// and common non-essential directories (e.g., .git, node_modules, target).
/// Returns a sorted vector of matching paths.
pub fn find(workspace: &Path, depth: usize, name: &str) -> Result<Vec<PathBuf>> {
    let mut matched = Vec::new();
    let mut is_root = true;

    for entry in WalkDir::new(workspace)
        .max_depth(depth)
        .follow_links(true)
        .into_iter()
        .filter_entry(|e| {
            // Always allow the root workspace directory
            if is_root {
                is_root = false;
                return true;
            }
            let fname = e.file_name().to_string_lossy();
            !is_hidden(e) && !skip_dir(&fname)
        })
    {
        let entry = match entry {
            Ok(e) => e,
            Err(err) => {
                // Log permission denied or other access errors
                log::warn!("Skipping inaccessible path: {}", err);
                continue;
            }
        };
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
