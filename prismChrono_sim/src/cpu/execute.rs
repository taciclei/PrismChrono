// src/cpu/execute.rs
// Point d'entrée pour l'exécution des instructions
// Ce fichier réexporte les fonctionnalités des modules spécialisés

// Réexporter les structures et erreurs principales
pub use crate::cpu::execute_core::{Cpu, ExecuteError};

// Réexporter les traits pour les différentes catégories d'instructions

// Note: Toutes les implémentations ont été déplacées dans les modules spécialisés
// Ce fichier ne contient plus que des réexportations pour maintenir la compatibilité avec le code existant
