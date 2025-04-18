use std::collections::HashMap;

/// Index vectoriel stub.
pub struct VectorIndex {
    map: HashMap<usize, Vec<f32>>,
}

impl VectorIndex {
    /// Crée un nouvel index vide.
    pub fn new() -> Self {
        VectorIndex { map: HashMap::new() }
    }

    /// Insère un vecteur pour la clé donnée.
    pub fn insert(&mut self, key: usize, vector: Vec<f32>) -> bool {
        self.map.insert(key, vector);
        true
    }

    /// Interroge un vecteur par clé.
    pub fn query(&self, key: usize) -> Option<Vec<f32>> {
        self.map.get(&key).cloned()
    }
}

#[cfg(test)]
mod tests {
    use super::VectorIndex;

    #[test]
    fn test_insert_and_query() {
        let mut idx = VectorIndex::new();
        assert_eq!(idx.query(1), None);
        assert!(idx.insert(1, vec![0.1, 0.2]));
        assert_eq!(idx.query(1), Some(vec![0.1, 0.2]));
    }
}
