use std::time::Instant;
use super::predictive::PredictiveAllocator;

/// Profile l’allocation prédictive sur `runs` itérations, renvoie le temps en ms.
pub fn profile_predictive(runs: usize) -> u128 {
    let mut alloc = PredictiveAllocator::new();
    let start = Instant::now();
    for _ in 0..runs {
        alloc.predictive_alloc();
    }
    start.elapsed().as_millis()
}

#[cfg(test)]
mod tests {
    use super::profile_predictive;

    #[test]
    fn test_profile_predictive() {
        let t = profile_predictive(10);
        assert!(t >= 0);
    }
}
