// src/core/mod.rs
pub mod types; // Rend le module 'types' public dans le crate

// Ré-exporte les types principaux pour un accès plus facile
pub use types::{Address, MAX_ADDRESS, Trit, Tryte, Word, is_valid_address};
