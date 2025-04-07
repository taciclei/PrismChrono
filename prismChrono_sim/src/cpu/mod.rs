// src/cpu/mod.rs

// Déclare les sous-modules du CPU
pub mod decode;
pub mod isa;
pub mod registers;
pub mod state;
pub mod supervisor_privilege;
pub mod isa_extensions;

// Modules d'exécution par catégorie d'instructions
pub mod execute_alu;
pub mod execute_branch;
pub mod execute_core;
pub mod execute_mem;
pub mod execute_system;
pub mod execute_ternary;
pub mod compact_format;

// Module d'exécution principal (pour compatibilité)
pub mod execute;

// Module de tests (uniquement compilé en mode test)
#[cfg(test)]
mod tests;

// Re-exporte les types et structures importantes pour faciliter l'accès
pub use registers::{Flags, ProcessorState, Register};
