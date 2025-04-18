use std::collections::HashMap;
use super::predictive::PredictiveAllocator;

/// Cache IA pour prédictions.
pub struct Cache {
    map: HashMap<Vec<u32>, Vec<usize>>,
}

impl Cache {
    /// Crée un cache vide.
    pub fn new() -> Self {
        Cache { map: HashMap::new() }
    }

    /// Retourne la prédiction mise en cache ou la calcule.
    pub fn get_or_compute(&mut self, input: Vec<f32>, runs: usize) -> Vec<usize> {
        let key: Vec<u32> = input.iter().map(|f| f.to_bits()).collect();
        if let Some(res) = self.map.get(&key) {
            return res.clone();
        }
        // Stub: utilise predictive allocator pour simuler
        let mut alloc = PredictiveAllocator::new();
        let mut result = Vec::new();
        for _ in 0..runs {
            if let Some(idx) = alloc.predictive_alloc() {
                result.push(idx);
            }
        }
        self.map.insert(key.clone(), result.clone());
        result
    }
}

#[cfg(test)]
mod tests {
    use super::Cache;

    #[test]
    fn test_cache_get_or_compute() {
        let mut cache = Cache::new();
        let input = vec![0.1, 0.2];
        let r1 = cache.get_or_compute(input.clone(), 3);
        let r2 = cache.get_or_compute(input.clone(), 3);
        assert_eq!(r1, r2);
    }
}
