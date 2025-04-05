// src/cpu/execute_branch.rs
// Implémentation des instructions de branchement et saut pour l'architecture PrismChrono

use crate::alu::add_24_trits;
use crate::core::{Trit, Tryte, Word, is_valid_address};
use crate::cpu::execute::ExecuteError;
use crate::cpu::execute_core::Cpu;
use crate::cpu::isa::Condition;
use crate::cpu::registers::{Flags, Register};
use crate::cpu::state::CpuState;

// Le trait CpuState est maintenant importé depuis le module state

/// Trait pour les opérations de branchement et saut
pub trait BranchOperations {
    /// Exécute une instruction de branchement conditionnel
    fn execute_branch(
        &mut self,
        _rs1: Register,
        cond: Condition,
        offset: i8,
    ) -> Result<(), ExecuteError>;

    /// Exécute une instruction de saut (Jump)
    fn execute_jump(&mut self, rd: Register, offset: i16) -> Result<(), ExecuteError>;

    /// Exécute une instruction d'appel (Call)
    fn execute_call(&mut self, rd: Register, offset: i16) -> Result<(), ExecuteError>;

    /// Exécute une instruction de saut indirect (Jump and Link Register)
    fn execute_jalr(&mut self, rd: Register, rs1: Register, offset: i8)
    -> Result<(), ExecuteError>;
}

/// Implémentation des opérations de branchement pour le CPU
impl<T: CpuState> BranchOperations for T {
    /// Exécute une instruction de branchement conditionnel
    /// Format B: [opcode(3t) | cond(3t) | rs1(2t) | offset(4t)]
    fn execute_branch(
        &mut self,
        _rs1: Register,
        cond: Condition,
        offset: i8,
    ) -> Result<(), ExecuteError> {
        // Incrémenter le compteur de branchements totaux
        if let Some(cpu) = self.as_cpu_mut() {
            cpu.branches_total += 1;
        }
        
        // 1. Lire les flags actuels
        let flags = self.read_flags();

        // 2. Évaluer la condition
        let condition_met = match cond {
            Condition::Eq => flags.zf,              // Égal (ZF = 1)
            Condition::Ne => !flags.zf,             // Non égal (ZF = 0)
            Condition::Lt => flags.sf,              // Inférieur (SF = 1)
            Condition::Ge => !flags.sf || flags.zf, // Supérieur ou égal (SF = 0 ou ZF = 1)
            Condition::Ltu => flags.zf, // Inférieur non signé (utiliser ZF au lieu de CF)
            Condition::Geu => !flags.zf, // Supérieur ou égal non signé (utiliser ZF au lieu de CF)
            Condition::Special => flags.xf, // État spécial (XF = 1)
            Condition::Always => true,  // Toujours vrai
        };

        // 3. Si la condition est remplie, calculer la nouvelle adresse PC
        if condition_met {
            // Incrémenter le compteur de branchements pris
            if let Some(cpu) = self.as_cpu_mut() {
                cpu.branches_taken += 1;
            }
            
            // Lire le PC actuel
            let current_pc = self.read_pc();

            // Calculer l'offset multiplié par 4 (taille d'une instruction)
            let offset_word = Word::from_int((offset as i32) * 4);

            // Calculer PC = PC + offset * 4
            let (new_pc, _, _) = add_24_trits(current_pc, offset_word, Trit::Z);

            // Convertir Word en entier pour vérifier la validité de l'adresse
            // Nous allons calculer la valeur en utilisant les trytes individuels
            let mut addr_value: i32 = 0;
            let mut power: i32 = 1;

            for i in 0..8 {
                if let Some(tryte) = new_pc.tryte(i) {
                    match tryte {
                        Tryte::Digit(digit) => {
                            // Convertir le digit en valeur ternaire équilibrée (-13 à +13)
                            let val = *digit as i32 - 13;
                            // Ajouter la contribution de ce tryte (base 27)
                            addr_value += val * power;
                            power *= 27;
                        }
                        _ => return Err(ExecuteError::InvalidAddress), // Adresse invalide si ce n'est pas un digit
                    }
                }
            }

            // Convertir en usize pour la vérification d'adresse
            // S'assurer que l'adresse est positive
            if addr_value < 0 {
                return Err(ExecuteError::InvalidAddress); // Adresse négative invalide
            }

            let addr_value = addr_value as usize;

            // Vérifier que l'adresse est valide
            if !is_valid_address(addr_value) {
                return Err(ExecuteError::InvalidAddress);
            }

            // Vérifier que l'adresse est alignée (multiple de 4)
            if addr_value % 4 != 0 {
                return Err(ExecuteError::UnalignedAddress);
            }

            // Mettre à jour le PC
            self.write_pc(new_pc);
        }

        Ok(())
    }

    /// Exécute une instruction de saut (Jump)
    /// Format J: [opcode(3t) | rd(2t) | offset(7t)]
    fn execute_jump(&mut self, rd: Register, offset: i16) -> Result<(), ExecuteError> {
        // 1. Sauvegarder le PC actuel dans rd (si rd != R0)
        if rd != Register::R0 {
            let current_pc = self.read_pc();
            self.write_gpr(rd, current_pc);
        }

        // 2. Calculer le nouveau PC = PC + offset
        let current_pc = self.read_pc();
        let offset_word = Word::from_int(offset as i32);

        let (new_pc, _, _) = add_24_trits(current_pc, offset_word, Trit::Z);

        // 3. Mettre à jour le PC
        self.write_pc(new_pc);

        Ok(())
    }

    /// Exécute une instruction d'appel (Call)
    /// Format J: [opcode(3t) | rd(2t) | offset(7t)]
    fn execute_call(&mut self, rd: Register, offset: i16) -> Result<(), ExecuteError> {
        // Identique à Jump, mais avec une sémantique différente (appel de fonction)
        self.execute_jump(rd, offset)
    }

    /// Exécute une instruction de saut indirect (Jump and Link Register)
    /// Format I: [opcode(3t) | rd(2t) | rs1(2t) | offset(5t)]
    fn execute_jalr(
        &mut self,
        rd: Register,
        rs1: Register,
        offset: i8,
    ) -> Result<(), ExecuteError> {
        // 1. Sauvegarder le PC actuel dans rd (si rd != R0)
        if rd != Register::R0 {
            let current_pc = self.read_pc();
            self.write_gpr(rd, current_pc);
        }

        // 2. Calculer le nouveau PC = rs1 + offset
        let base_addr = self.read_gpr(rs1);
        let offset_word = Word::from_int(offset as i32);

        let (new_pc, _, _) = add_24_trits(base_addr, offset_word, Trit::Z);

        // 3. Mettre à jour le PC
        self.write_pc(new_pc);

        Ok(())
    }
}
