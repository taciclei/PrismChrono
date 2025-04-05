// src/cpu/execute.rs
// Point d'entrée pour l'exécution des instructions
// Ce fichier réexporte les fonctionnalités des modules spécialisés

// Réexporter les structures et erreurs principales
pub use crate::cpu::execute_core::{Cpu, ExecuteError};

// Réexporter les traits pour les différentes catégories d'instructions
pub use crate::cpu::execute_alu::AluOperations;
pub use crate::cpu::execute_branch::BranchOperations;
pub use crate::cpu::execute_mem::MemoryOperations;
pub use crate::cpu::execute_system::SystemOperations;

// Note: Toutes les implémentations ont été déplacées dans les modules spécialisés
// Ce fichier ne contient plus que des réexportations pour maintenir la compatibilité avec le code existant
