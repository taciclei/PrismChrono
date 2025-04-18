/// Stub d'un allocateur prédictif IA.
pub struct PredictiveAllocator {
    history: Vec<usize>,
}

use crate::logging::log_predictive;
use crate::metrics::inc_alloc;

impl PredictiveAllocator {
    /// Crée un nouveau PredictiveAllocator.
    pub fn new() -> Self {
        PredictiveAllocator { history: Vec::new() }
    }

    /// Alloue de façon prédictive, retourne un index basé sur l'historique.
    pub fn predictive_alloc(&mut self) -> Option<usize> {
        let idx = self.history.len();
        self.history.push(idx);
        log_predictive(&format!("predictive_alloc {}", idx));
        inc_alloc();
        Some(idx)
    }
}

#[cfg(test)]
mod tests {
    use super::PredictiveAllocator;
    use crate::logging::log_predictive;
    use crate::metrics::inc_alloc;

    #[test]
    fn test_predictive_alloc() {
        let mut pa = PredictiveAllocator::new();
        assert_eq!(pa.predictive_alloc(), Some(0));
        assert_eq!(pa.predictive_alloc(), Some(1));
    }
}
