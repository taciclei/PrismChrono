/// Stub d'un pipeline de préchargement IA.
pub struct PreloadPipeline {
    loaded: Vec<usize>,
}

impl PreloadPipeline {
    /// Crée un nouveau PreloadPipeline.
    pub fn new() -> Self {
        PreloadPipeline { loaded: Vec::new() }
    }

    /// Précharge un ensemble de triclusters, retourne ceux préchargés.
    pub fn preload(&mut self, keys: Vec<usize>) -> Vec<usize> {
        self.loaded = keys.clone();
        self.loaded.clone()
    }
}

#[cfg(test)]
mod tests {
    use super::PreloadPipeline;

    #[test]
    fn test_preload() {
        let mut pp = PreloadPipeline::new();
        let keys = vec![0, 1, 2];
        assert_eq!(pp.preload(keys.clone()), keys);
    }
}
