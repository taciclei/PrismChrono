use std::collections::HashSet;

/// Manager de snapshots/versioning.
pub struct SnapshotManager {
    versions: HashSet<String>,
}

impl SnapshotManager {
    /// Crée un nouveau SnapshotManager.
    pub fn new() -> Self {
        SnapshotManager { versions: HashSet::new() }
    }

    /// Crée un snapshot pour la version donnée.
    pub fn create_snapshot(&mut self, version: &str) -> bool {
        self.versions.insert(version.to_string())
    }

    /// Restaure le snapshot de la version donnée.
    pub fn restore_snapshot(&self, version: &str) -> bool {
        self.versions.contains(version)
    }
}

#[cfg(test)]
mod tests {
    use super::SnapshotManager;

    #[test]
    fn test_snapshot_manager() {
        let mut manager = SnapshotManager::new();
        assert!(manager.create_snapshot("v1"));
        assert!(manager.restore_snapshot("v1"));
        assert!(!manager.restore_snapshot("v2"));
    }
}
