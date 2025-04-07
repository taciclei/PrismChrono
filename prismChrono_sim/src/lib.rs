// src/lib.rs

// Déclare les modules que nous allons utiliser
pub mod alu;
pub mod core;
pub mod cpu;
pub mod memory;

// Réexporte les types et fonctions importantes pour faciliter l'accès
pub use crate::alu::{ternary_full_adder, trit_inv_word, trit_max_word, trit_min_word};
pub use crate::core::{Address, Trit, Tryte, Word, is_valid_address};
pub use crate::cpu::registers::RegisterError;
pub use crate::cpu::isa::{AluOp, Condition, Instruction, InstructionFormat, Opcode};
pub use crate::cpu::decode::{DecodeError, decode};
pub use crate::cpu::execute::{Cpu, ExecuteError};
pub use crate::cpu::registers::{Flags, ProcessorState, Register};
pub use crate::memory::{Memory, MemoryError};

// Nouveaux modules pour les améliorations avancées
pub mod tvpu;            // Unité de traitement vectoriel ternaire
pub mod branch_predictor; // Prédicteur de branchement ternaire avancé
pub mod crypto;           // Instructions cryptographiques ternaires
pub mod pipeline;         // Pipeline superscalaire ternaire
pub mod cache;            // Cache prédictif ternaire
pub mod neural;           // Support pour l'intelligence artificielle

// Réexporte les nouvelles fonctionnalités
pub use crate::tvpu::TernaryVector;
pub use crate::branch_predictor::TernaryBranchPredictor;
pub use crate::pipeline::SuperscalarPipeline;
pub use crate::cache::TernaryPredictiveCache;
pub use crate::neural::TernaryMatrix;
