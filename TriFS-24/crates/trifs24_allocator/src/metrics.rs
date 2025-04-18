use prometheus::{IntCounter, register_int_counter};
use lazy_static::lazy_static;

lazy_static! {
    /// Compteur Prometheus pour le nombre total d'allocations.
    static ref ALLOC_COUNTER: IntCounter = register_int_counter!(
        "allocator_alloc_total",
        "Nombre total d'allocations de triclusters"
    )
    .unwrap();
}

/// Incrémente le compteur d'allocations.
pub fn inc_alloc() {
    ALLOC_COUNTER.inc();
}

/// Retourne la valeur actuelle du compteur d'allocations.
pub fn get_alloc_total() -> u64 {
    ALLOC_COUNTER.get()
}

/// Reset the allocation counter (pour tests BDD).
pub fn reset_alloc_counter() {
    ALLOC_COUNTER.reset();
}

#[cfg(test)]
mod tests {
    use super::{inc_alloc, get_alloc_total, reset_alloc_counter};

    #[test]
    fn test_metrics_alloc_counter() {
        let initial = get_alloc_total();
        inc_alloc();
        inc_alloc();
        inc_alloc();
        assert_eq!(get_alloc_total() - initial, 3);
    }
}
