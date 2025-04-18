use std::collections::HashMap;

/// VFS FUSE-like stub pour TriFS-24.
pub struct Vfs {
    store: HashMap<String, String>,
}

impl Vfs {
    /// Monte le FS, retourne une instance de Vfs.
    pub fn mount(_source: &str, _mount_point: &str) -> Self {
        Vfs { store: HashMap::new() }
    }

    /// Écrit une chaîne dans le fichier virtuel.
    pub fn write(&mut self, path: &str, data: &str) -> bool {
        self.store.insert(path.to_string(), data.to_string());
        true
    }

    /// Lit le contenu d'un fichier virtuel.
    pub fn read(&self, path: &str) -> Option<String> {
        self.store.get(path).cloned()
    }
}

#[cfg(test)]
mod tests {
    use super::Vfs;

    #[test]
    fn test_vfs_mount_write_read() {
        let mut vfs = Vfs::mount("src", "/mnt");
        assert!(vfs.write("/greeting.txt", "hello"));
        assert_eq!(vfs.read("/greeting.txt"), Some("hello".to_string()));
    }
}
