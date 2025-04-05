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
pub use crate::cpu::{
    AluOp, Condition, DecodeError, Instruction, InstructionFormat, Opcode, decode,
};
pub use crate::cpu::{Cpu, ExecuteError};
pub use crate::cpu::{Flags, ProcessorState, Register};
pub use crate::memory::{Memory, MemoryError};
