// src/cpu/execute_alu.rs
// Implémentation des instructions ALU pour l'architecture PrismChrono

use crate::alu::{
    add_24_trits, compare_24_trits, div_24_trits, mod_24_trits, mul_24_trits, shl_24_trits,
    shr_24_trits, sub_24_trits,
};
use crate::alu::{trit_inv_word, trit_max_word, trit_min_word};
use crate::core::{Trit, Tryte, Word};
use crate::cpu::execute::ExecuteError;
use crate::cpu::isa::AluOp;
use crate::cpu::registers::{Flags, Register};

/// Trait pour les opérations ALU
pub trait AluOperations {
    /// Exécute une instruction ALU format R (registre-registre)
    fn execute_alu_reg(
        &mut self,
        op: AluOp,
        rs1: Register,
        rs2: Register,
        rd: Register,
    ) -> Result<(), ExecuteError>;

    /// Exécute une instruction ALU format I (avec immédiat)
    fn execute_alu_imm(
        &mut self,
        op: AluOp,
        rs1: Register,
        rd: Register,
        imm: i16,
    ) -> Result<(), ExecuteError>;
}

/// Implémentation des opérations ALU pour le CPU
impl<T: CpuState> AluOperations for T {
    /// Exécute une instruction ALU format R (registre-registre)
    /// Format R: [opcode(3t) | rd(2t) | rs1(2t) | rs2(2t) | func(3t)]
    fn execute_alu_reg(
        &mut self,
        op: AluOp,
        rs1: Register,
        rs2: Register,
        rd: Register,
    ) -> Result<(), ExecuteError> {
        // 1. Lire les valeurs des registres sources
        let val1 = self.read_gpr(rs1);
        let val2 = self.read_gpr(rs2);

        // 2. Effectuer l'opération ALU appropriée
        let (result, flags) = match op {
            AluOp::Add => {
                let (res, _, flags) = add_24_trits(val1, val2, Trit::Z);
                (res, flags)
            }
            AluOp::Sub => {
                let (res, _, flags) = sub_24_trits(val1, val2, Trit::Z);
                (res, flags)
            }
            AluOp::Mul => {
                let res = mul_24_trits(val1, val2);
                let mut flags = Flags::new();

                // Mettre à jour les flags
                flags.zf = res.trytes().iter().all(|t| match t {
                    Tryte::Digit(13) => true, // 13 = 0 en ternaire équilibré
                    _ => false,
                });

                // Vérifier le signe du résultat
                if let Some(msb_tryte) = res.tryte(7) {
                    if let Tryte::Digit(_) = msb_tryte {
                        let msb_trits = msb_tryte.to_trits();
                        flags.sf = msb_trits[2] == Trit::N; // Trit de poids fort = N?
                    }
                }

                (res, flags)
            }
            AluOp::Div => {
                // Vérifier la division par zéro
                let is_zero = val2.trytes().iter().all(|t| match t {
                    Tryte::Digit(13) => true, // 13 = 0 en ternaire équilibré
                    _ => false,
                });

                if is_zero {
                    return Err(ExecuteError::DivisionByZero);
                }

                let res = div_24_trits(val1, val2);
                let mut flags = Flags::new();

                // Mettre à jour les flags
                flags.zf = res.trytes().iter().all(|t| match t {
                    Tryte::Digit(13) => true, // 13 = 0 en ternaire équilibré
                    _ => false,
                });

                // Vérifier le signe du résultat
                if let Some(msb_tryte) = res.tryte(7) {
                    if let Tryte::Digit(_) = msb_tryte {
                        let msb_trits = msb_tryte.to_trits();
                        flags.sf = msb_trits[2] == Trit::N; // Trit de poids fort = N?
                    }
                }

                (res, flags)
            }
            AluOp::Mod => {
                // Vérifier la division par zéro
                let is_zero = val2.trytes().iter().all(|t| match t {
                    Tryte::Digit(13) => true, // 13 = 0 en ternaire équilibré
                    _ => false,
                });

                if is_zero {
                    return Err(ExecuteError::DivisionByZero);
                }

                let res = mod_24_trits(val1, val2);
                let mut flags = Flags::new();

                // Mettre à jour les flags
                flags.zf = res.trytes().iter().all(|t| match t {
                    Tryte::Digit(13) => true, // 13 = 0 en ternaire équilibré
                    _ => false,
                });

                // Vérifier le signe du résultat
                if let Some(msb_tryte) = res.tryte(7) {
                    if let Tryte::Digit(_) = msb_tryte {
                        let msb_trits = msb_tryte.to_trits();
                        flags.sf = msb_trits[2] == Trit::N; // Trit de poids fort = N?
                    }
                }

                (res, flags)
            }
            AluOp::TritInv => {
                let res = trit_inv_word(val1);
                let mut flags = Flags::new();

                // Mettre à jour les flags
                flags.zf = res.trytes().iter().all(|t| match t {
                    Tryte::Digit(13) => true, // 13 = 0 en ternaire équilibré
                    _ => false,
                });

                // Vérifier le signe du résultat
                if let Some(msb_tryte) = res.tryte(7) {
                    if let Tryte::Digit(_) = msb_tryte {
                        let msb_trits = msb_tryte.to_trits();
                        flags.sf = msb_trits[2] == Trit::N; // Trit de poids fort = N?
                    }
                }

                (res, flags)
            }
            AluOp::TritMin => {
                let res = trit_min_word(val1, val2);
                let mut flags = Flags::new();

                // Mettre à jour les flags
                flags.zf = res.trytes().iter().all(|t| match t {
                    Tryte::Digit(13) => true, // 13 = 0 en ternaire équilibré
                    _ => false,
                });

                // Vérifier le signe du résultat
                if let Some(msb_tryte) = res.tryte(7) {
                    if let Tryte::Digit(_) = msb_tryte {
                        let msb_trits = msb_tryte.to_trits();
                        flags.sf = msb_trits[2] == Trit::N; // Trit de poids fort = N?
                    }
                }

                (res, flags)
            }
            AluOp::TritMax => {
                let res = trit_max_word(val1, val2);
                let mut flags = Flags::new();

                // Mettre à jour les flags
                flags.zf = res.trytes().iter().all(|t| match t {
                    Tryte::Digit(13) => true, // 13 = 0 en ternaire équilibré
                    _ => false,
                });

                // Vérifier le signe du résultat
                if let Some(msb_tryte) = res.tryte(7) {
                    if let Tryte::Digit(_) = msb_tryte {
                        let msb_trits = msb_tryte.to_trits();
                        flags.sf = msb_trits[2] == Trit::N; // Trit de poids fort = N?
                    }
                }

                (res, flags)
            }
            AluOp::Shl => {
                let res = shl_24_trits(val1, val2);
                let mut flags = Flags::new();

                // Mettre à jour les flags
                flags.zf = res.trytes().iter().all(|t| match t {
                    Tryte::Digit(13) => true, // 13 = 0 en ternaire équilibré
                    _ => false,
                });

                // Vérifier le signe du résultat
                if let Some(msb_tryte) = res.tryte(7) {
                    if let Tryte::Digit(_) = msb_tryte {
                        let msb_trits = msb_tryte.to_trits();
                        flags.sf = msb_trits[2] == Trit::N; // Trit de poids fort = N?
                    }
                }

                (res, flags)
            }
            AluOp::Shr => {
                let res = shr_24_trits(val1, val2);
                let mut flags = Flags::new();

                // Mettre à jour les flags
                flags.zf = res.trytes().iter().all(|t| match t {
                    Tryte::Digit(13) => true, // 13 = 0 en ternaire équilibré
                    _ => false,
                });

                // Vérifier le signe du résultat
                if let Some(msb_tryte) = res.tryte(7) {
                    if let Tryte::Digit(_) = msb_tryte {
                        let msb_trits = msb_tryte.to_trits();
                        flags.sf = msb_trits[2] == Trit::N; // Trit de poids fort = N?
                    }
                }

                (res, flags)
            }
            AluOp::Cmp => {
                // Pour CMP, on effectue une soustraction mais on ne stocke pas le résultat
                let flags = compare_24_trits(val1, val2);
                // On retourne val1 comme résultat (qui ne sera pas utilisé)
                (val1, flags)
            }
        };

        // 3. Écrire le résultat dans le registre de destination (sauf pour CMP)
        if op != AluOp::Cmp && rd != Register::R0 {
            self.write_gpr(rd, result);
        }

        // 4. Mettre à jour les flags
        self.write_flags(flags);

        Ok(())
    }

    /// Exécute une instruction ALU format I (avec immédiat)
    /// Format I: [opcode(3t) | rd(2t) | rs1(2t) | immediate(5t)]
    fn execute_alu_imm(
        &mut self,
        op: AluOp,
        rs1: Register,
        rd: Register,
        imm: i16,
    ) -> Result<(), ExecuteError> {
        // 1. Lire la valeur du registre source
        let val1 = self.read_gpr(rs1);

        // 2. Convertir l'immédiat en Word
        let val2 = Word::from_int(imm as i32);

        // 3. Effectuer l'opération ALU appropriée (similaire à execute_alu_reg)
        let (result, flags) = match op {
            AluOp::Add => {
                let (res, _, flags) = add_24_trits(val1, val2, Trit::Z);
                (res, flags)
            }
            AluOp::Sub => {
                let (res, _, flags) = sub_24_trits(val1, val2, Trit::Z);
                (res, flags)
            }
            AluOp::Mul => {
                let res = mul_24_trits(val1, val2);
                let mut flags = Flags::new();

                // Mettre à jour les flags
                flags.zf = res.trytes().iter().all(|t| match t {
                    Tryte::Digit(13) => true, // 13 = 0 en ternaire équilibré
                    _ => false,
                });

                // Vérifier le signe du résultat
                if let Some(msb_tryte) = res.tryte(7) {
                    if let Tryte::Digit(_) = msb_tryte {
                        let msb_trits = msb_tryte.to_trits();
                        flags.sf = msb_trits[2] == Trit::N; // Trit de poids fort = N?
                    }
                }

                (res, flags)
            }
            AluOp::Div => {
                // Vérifier la division par zéro
                let is_zero = val2.trytes().iter().all(|t| match t {
                    Tryte::Digit(13) => true, // 13 = 0 en ternaire équilibré
                    _ => false,
                });

                if is_zero {
                    return Err(ExecuteError::DivisionByZero);
                }

                let res = div_24_trits(val1, val2);
                let mut flags = Flags::new();

                // Mettre à jour les flags
                flags.zf = res.trytes().iter().all(|t| match t {
                    Tryte::Digit(13) => true, // 13 = 0 en ternaire équilibré
                    _ => false,
                });

                // Vérifier le signe du résultat
                if let Some(msb_tryte) = res.tryte(7) {
                    if let Tryte::Digit(_) = msb_tryte {
                        let msb_trits = msb_tryte.to_trits();
                        flags.sf = msb_trits[2] == Trit::N; // Trit de poids fort = N?
                    }
                }

                (res, flags)
            }
            AluOp::Mod => {
                // Vérifier la division par zéro
                let is_zero = val2.trytes().iter().all(|t| match t {
                    Tryte::Digit(13) => true, // 13 = 0 en ternaire équilibré
                    _ => false,
                });

                if is_zero {
                    return Err(ExecuteError::DivisionByZero);
                }

                let res = mod_24_trits(val1, val2);
                let mut flags = Flags::new();

                // Mettre à jour les flags
                flags.zf = res.trytes().iter().all(|t| match t {
                    Tryte::Digit(13) => true, // 13 = 0 en ternaire équilibré
                    _ => false,
                });

                // Vérifier le signe du résultat
                if let Some(msb_tryte) = res.tryte(7) {
                    if let Tryte::Digit(_) = msb_tryte {
                        let msb_trits = msb_tryte.to_trits();
                        flags.sf = msb_trits[2] == Trit::N; // Trit de poids fort = N?
                    }
                }

                (res, flags)
            }
            AluOp::TritInv => {
                let res = trit_inv_word(val1);
                let mut flags = Flags::new();

                // Mettre à jour les flags
                flags.zf = res.trytes().iter().all(|t| match t {
                    Tryte::Digit(13) => true, // 13 = 0 en ternaire équilibré
                    _ => false,
                });

                // Vérifier le signe du résultat
                if let Some(msb_tryte) = res.tryte(7) {
                    if let Tryte::Digit(_) = msb_tryte {
                        let msb_trits = msb_tryte.to_trits();
                        flags.sf = msb_trits[2] == Trit::N; // Trit de poids fort = N?
                    }
                }

                (res, flags)
            }
            AluOp::TritMin => {
                let res = trit_min_word(val1, val2);
                let mut flags = Flags::new();

                // Mettre à jour les flags
                flags.zf = res.trytes().iter().all(|t| match t {
                    Tryte::Digit(13) => true, // 13 = 0 en ternaire équilibré
                    _ => false,
                });

                // Vérifier le signe du résultat
                if let Some(msb_tryte) = res.tryte(7) {
                    if let Tryte::Digit(_) = msb_tryte {
                        let msb_trits = msb_tryte.to_trits();
                        flags.sf = msb_trits[2] == Trit::N; // Trit de poids fort = N?
                    }
                }

                (res, flags)
            }
            AluOp::TritMax => {
                let res = trit_max_word(val1, val2);
                let mut flags = Flags::new();

                // Mettre à jour les flags
                flags.zf = res.trytes().iter().all(|t| match t {
                    Tryte::Digit(13) => true, // 13 = 0 en ternaire équilibré
                    _ => false,
                });

                // Vérifier le signe du résultat
                if let Some(msb_tryte) = res.tryte(7) {
                    if let Tryte::Digit(_) = msb_tryte {
                        let msb_trits = msb_tryte.to_trits();
                        flags.sf = msb_trits[2] == Trit::N; // Trit de poids fort = N?
                    }
                }

                (res, flags)
            }
            AluOp::Shl => {
                let res = shl_24_trits(val1, val2);
                let mut flags = Flags::new();

                // Mettre à jour les flags
                flags.zf = res.trytes().iter().all(|t| match t {
                    Tryte::Digit(13) => true, // 13 = 0 en ternaire équilibré
                    _ => false,
                });

                // Vérifier le signe du résultat
                if let Some(msb_tryte) = res.tryte(7) {
                    if let Tryte::Digit(_) = msb_tryte {
                        let msb_trits = msb_tryte.to_trits();
                        flags.sf = msb_trits[2] == Trit::N; // Trit de poids fort = N?
                    }
                }

                (res, flags)
            }
            AluOp::Shr => {
                let res = shr_24_trits(val1, val2);
                let mut flags = Flags::new();

                // Mettre à jour les flags
                flags.zf = res.trytes().iter().all(|t| match t {
                    Tryte::Digit(13) => true, // 13 = 0 en ternaire équilibré
                    _ => false,
                });

                // Vérifier le signe du résultat
                if let Some(msb_tryte) = res.tryte(7) {
                    if let Tryte::Digit(_) = msb_tryte {
                        let msb_trits = msb_tryte.to_trits();
                        flags.sf = msb_trits[2] == Trit::N; // Trit de poids fort = N?
                    }
                }

                (res, flags)
            }
            AluOp::Cmp => {
                // Pour CMP, on effectue une soustraction mais on ne stocke pas le résultat
                let flags = compare_24_trits(val1, val2);
                // On retourne val1 comme résultat (qui ne sera pas utilisé)
                (val1, flags)
            }
        };

        // 4. Écrire le résultat dans le registre de destination (sauf pour CMP)
        if op != AluOp::Cmp && rd != Register::R0 {
            self.write_gpr(rd, result);
        }

        // 5. Mettre à jour les flags
        self.write_flags(flags);

        Ok(())
    }
}

// Le trait CpuState est maintenant importé depuis le module state
use crate::cpu::state::CpuState;
