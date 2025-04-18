//! Crate `trifs24_allocator`
//!
//! Prototype d'allocateur ternaire pour TriFS-24.
//! Fournit une structure `Allocator` gérant l'état des triclusters.

/// Représentation d'un allocateur de triclusters en logique ternaire.
pub struct Allocator {
    /// Nombre total de triclusters.
    total: usize,
    /// Bitmap ternaire: 0=libre, 1=occupé, 2=réservé.
    map: Vec<u8>,
}

impl Allocator {
    /// Crée un nouvel allocateur avec `total` triclusters initiaux à l'état libre.
    pub fn new(total: usize) -> Self {
        Self { total, map: vec![0; total] }
    }

    /// Alloue un tricluster libre, retourne son index ou une erreur.
    pub fn allocate(&mut self) -> Result<usize, Error> {
        if let Some(i) = self.map.iter().position(|&s| s == 0) {
            self.map[i] = 1;
            log_predictive(&format!("allocate {}", i));
            inc_alloc();
            Ok(i)
        } else {
            log_predictive("allocate error: OutOfSpace");
            Err(Error::OutOfSpace)
        }
    }

    /// Réserve un tricluster pour métadonnées, retourne son index ou une erreur.
    pub fn reserve(&mut self) -> Result<usize, Error> {
        if let Some(i) = self.map.iter().position(|&s| s == 0) {
            self.map[i] = 2;
            log_predictive(&format!("reserve {}", i));
            Ok(i)
        } else {
            log_predictive("reserve error: OutOfSpace");
            Err(Error::OutOfSpace)
        }
    }

    /// Libère un tricluster à l'index donné, retourne une erreur si échec.
    pub fn free(&mut self, index: usize) -> Result<(), Error> {
        if index < self.total && self.map[index] != 0 {
            self.map[index] = 0;
            log_predictive(&format!("free {}", index));
            Ok(())
        } else {
            log_predictive("free error: InvalidIndex");
            Err(Error::InvalidIndex)
        }
    }

    /// Renvoie le statut global (counts de chaque état).
    pub fn status(&self) -> Status {
        let mut free = 0;
        let mut used = 0;
        let mut reserved = 0;
        for &s in &self.map {
            match s {
                0 => free += 1,
                1 => used += 1,
                2 => reserved += 1,
                _ => {}
            }
        }
        Status { free, used, reserved }
    }
}

/// Structure renvoyée par `status()`.
pub struct Status {
    pub free: usize,
    pub used: usize,
    pub reserved: usize,
}

mod metadata;
mod vector_index;
mod predictive;
mod preload;
mod checksum;
mod snapshot;
mod crypto;
mod vfs;
mod connectors;
mod profiler;
mod optimizer;
mod cache;
mod errors;
mod logging;
mod metrics;
mod journal;
mod snapshot;

use crate::logging::log_predictive;
use crate::metrics::inc_alloc;

pub use metadata::FNode;
pub use vector_index::VectorIndex;
pub use predictive::PredictiveAllocator;
pub use preload::PreloadPipeline;
pub use checksum::{compute_checksum, verify_checksum};
pub use snapshot::SnapshotManager;
pub use crypto::{encrypt_block, decrypt_block};
pub use vfs::Vfs;
pub use connectors::Connectors;
pub use profiler::profile_predictive;
pub use optimizer::optimize_predictive;
pub use cache::Cache;
pub use errors::Error;
pub use metrics::{get_alloc_total, reset_alloc_counter};

#[cfg(test)]
mod tests {
    use super::{Allocator, Error, Status};

    #[test]
    fn test_allocate_and_reserve() {
        let mut alloc = Allocator::new(3);
        assert_eq!(alloc.allocate(), Ok(0));
        assert_eq!(alloc.reserve(), Ok(1));
        assert_eq!(alloc.allocate(), Ok(2));
        assert_eq!(alloc.allocate(), Err(Error::OutOfSpace));
    }

    #[test]
    fn test_free_and_status() {
        let mut alloc = Allocator::new(3);
        // allouer et réserver
        alloc.allocate().unwrap();
        alloc.reserve().unwrap();
        // libération du premier
        assert_eq!(alloc.free(0), Ok(()));
        // statut
        let st = alloc.status();
        assert_eq!(st.free, 2);
        assert_eq!(st.used, 0);
        assert_eq!(st.reserved, 1);
        // erreur d'index
        assert_eq!(alloc.free(3), Err(Error::InvalidIndex));
    }
}
