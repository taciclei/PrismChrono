// src/cpu/execute_ternary.rs
// Implémentation des instructions ternaires spécialisées pour l'architecture PrismChrono

use crate::core::{Trit, Word};
use crate::cpu::registers::Register;
use crate::cpu::execute_core::ExecuteError;
use crate::cpu::state::CpuState;
use crate::cpu::isa_extensions::{TernaryOp, TernaryShiftOp, SpecialStateOp, Base24Op};
use crate::cpu::isa_extensions::{execute_ternary_op as ext_execute_ternary_op, 
                               execute_ternary_shift as ext_execute_ternary_shift, 
                               execute_special_state_op as ext_execute_special_state_op, 
                               execute_tsel as ext_execute_tsel, 
                               execute_base24_op as ext_execute_base24_op};
use crate::alu::{add_24_trits, sub_24_trits, mul_24_trits};

/// Trait pour l'exécution des instructions ternaires spécialisées
pub trait ExecuteTernary {
    /// Exécute une instruction ternaire spécialisée (TMIN, TMAX, TSUM, TCMP3)
    fn execute_ternary(&mut self, op: TernaryOp, rs1: Register, rs2: Register, rd: Register) -> Result<(), ExecuteError>;
    
    /// Exécute une instruction de rotation ou décalage ternaire
    fn execute_ternary_shift(&mut self, op: TernaryShiftOp, rs1: Register, rd: Register, imm: i32) -> Result<(), ExecuteError>;
    
    /// Exécute une instruction de branchement ternaire (BRANCH3)
    fn execute_branch3(&mut self, rs1: Register, offset_n: i32, offset_z: i32, offset_p: i32) -> Result<(), ExecuteError>;
    
    /// Charge 3 trytes consécutifs depuis la mémoire
    fn execute_load_tryte3(&mut self, rd: Register, rs1: Register, offset: i32) -> Result<(), ExecuteError>;
    
    /// Stocke 3 trytes consécutifs en mémoire
    fn execute_store_tryte3(&mut self, rs1: Register, rs2: Register, offset: i32) -> Result<(), ExecuteError>;
    
    /// Exécute une instruction de chargement avec masque de trytes
    fn execute_load_tm(&mut self, rd: Register, rs1: Register, mask: u8, offset: i32) -> Result<(), ExecuteError>;
    
    /// Exécute une instruction de stockage avec masque de trytes
    fn execute_store_tm(&mut self, rs1: Register, rs2: Register, mask: u8, offset: i32) -> Result<(), ExecuteError>;
    
    /// Exécute une instruction de copie mémoire ternaire
    fn execute_tmemcpy(&mut self, rd: Register, rs1: Register, rs2: Register) -> Result<(), ExecuteError>;
    
    /// Exécute une instruction d'initialisation mémoire ternaire
    fn execute_tmemset(&mut self, rd: Register, rs1: Register, rs2: Register) -> Result<(), ExecuteError>;
    
    /// Exécute une instruction multi-opération (multiplication-addition)
    fn execute_maddw(&mut self, rd: Register, rs1: Register, rs2: Register, rs3: Register) -> Result<(), ExecuteError>;
    
    /// Exécute une instruction multi-opération (multiplication-soustraction)
    fn execute_msubw(&mut self, rd: Register, rs1: Register, rs2: Register, rs3: Register) -> Result<(), ExecuteError>;
    
    /// Exécute une instruction pour les états spéciaux
    fn execute_special_state(&mut self, op: SpecialStateOp, rs1: Register, rd: Register) -> Result<(), ExecuteError>;
    
    /// Exécute une instruction de sélection ternaire
    fn execute_tsel(&mut self, rd: Register, rs1: Register, rs2: Register, rs3: Register) -> Result<(), ExecuteError>;
    
    /// Exécute une instruction de base 24
    fn execute_base24(&mut self, op: Base24Op, rs1: Register, rs2: Register, rd: Register) -> Result<(), ExecuteError>;
}

/// Implémentation des instructions ternaires pour le CPU
impl<T: CpuState> ExecuteTernary for T {
    /// Exécute une instruction ternaire spécialisée (TMIN, TMAX, TSUM, TCMP3)
    fn execute_ternary(&mut self, op: TernaryOp, rs1: Register, rs2: Register, rd: Register) -> Result<(), ExecuteError> {
        // Lire les valeurs des registres
        let a = self.read_gpr(rs1);
        let b = self.read_gpr(rs2);
        
        // Exécuter l'opération ternaire
        let result = ext_execute_ternary_op(op, a, b);
        
        // Écrire le résultat
        self.write_gpr(rd, result);
        Ok(())
    }
    
    /// Exécute une instruction de rotation ou décalage ternaire
    fn execute_ternary_shift(&mut self, op: TernaryShiftOp, rs1: Register, rd: Register, imm: i32) -> Result<(), ExecuteError> {
        // Lire la valeur du registre
        let a = self.read_gpr(rs1);
        
        // Exécuter l'opération de décalage
        let result = ext_execute_ternary_shift(op, a, imm);
        
        // Écrire le résultat
        self.write_gpr(rd, result);
        Ok(())
    }
    
    /// Exécute un branchement ternaire à 3 voies
    fn execute_branch3(&mut self, rs1: Register, offset_n: i32, offset_z: i32, offset_p: i32) -> Result<(), ExecuteError> {
        // Lire la valeur du registre
        let value = self.read_gpr(rs1);
        
        // Déterminer l'offset en fonction de la valeur du registre
        let offset = if value.is_negative() {
            offset_n
        } else if value == Word::zero() {
            offset_z
        } else {
            offset_p
        };
        
        // Mettre à jour le PC
        let pc = self.read_pc();
        let new_pc = Word::from_i32((pc.to_i32() + offset) as i32);
        self.write_pc(new_pc);
        
        Ok(())
    }
    
    /// Charge 3 trytes consécutifs depuis la mémoire
    fn execute_load_tryte3(&mut self, rd: Register, rs1: Register, offset: i32) -> Result<(), ExecuteError> {
        // Calculer l'adresse de base
        let base = self.read_gpr(rs1).to_i32();
        let addr = (base + offset) as u32;
        
        // Créer un nouveau mot pour stocker les trytes chargés
        let mut result = Word::zero();
        
        // Charger 3 trytes consécutifs
        for i in 0..3 {
            // Lire le tryte depuis la mémoire
            let loaded_tryte = self.read_tryte(addr as usize + i as usize)?;
            
            // Stocker le tryte dans le mot résultat
            if let Some(tryte) = result.tryte_mut(i) {
                *tryte = loaded_tryte;
            }
        }
        
        // Écrire le résultat dans le registre de destination
        self.write_gpr(rd, result);
        Ok(())
    }
    
    /// Stocke 3 trytes consécutifs en mémoire
    fn execute_store_tryte3(&mut self, rs1: Register, rs2: Register, offset: i32) -> Result<(), ExecuteError> {
        // Calculer l'adresse de base
        let base = self.read_gpr(rs1).to_i32();
        let addr = (base + offset) as usize;
        
        // Lire la valeur à stocker
        let value = self.read_gpr(rs2);
        
        // Stocker 3 trytes consécutifs
        for i in 0..3 {
            if let Some(tryte) = value.tryte(i) {
                let tryte_addr = addr + i;
                self.write_tryte(tryte_addr, *tryte)?;
            }
        }
        
        Ok(())
    }
    
    /// Exécute une instruction de chargement avec masque de trytes
    fn execute_load_tm(&mut self, rd: Register, rs1: Register, mask: u8, offset: i32) -> Result<(), ExecuteError> {
        // Lire l'adresse de base
        let base = self.read_gpr(rs1).to_i32();
        let addr = (base + offset) as usize;
        
        // Créer un nouveau mot pour stocker les trytes chargés
        let mut result = Word::zero();
        
        // Charger les trytes selon le masque
        for i in 0..8 {
            if (mask >> i) & 1 == 1 {
                // Le bit i du masque est actif, charger le tryte
                let tryte_addr = addr + i;
                let loaded_tryte = self.read_tryte(tryte_addr)?;
                
                // Stocker le tryte dans le mot résultat
                if let Some(tryte) = result.tryte_mut(i) {
                    *tryte = loaded_tryte;
                }
            }
        }
        
        // Écrire le résultat dans le registre destination
        self.write_gpr(rd, result);
        Ok(())
    }
    
    /// Exécute une instruction de stockage avec masque de trytes
    fn execute_store_tm(&mut self, rs1: Register, rs2: Register, mask: u8, offset: i32) -> Result<(), ExecuteError> {
        // Lire l'adresse de base
        let base = self.read_gpr(rs1).to_i32();
        let addr = (base + offset) as usize;
        
        // Lire la valeur à stocker
        let value = self.read_gpr(rs2);
        
        // Stocker les trytes selon le masque
        for i in 0..8 {
            if (mask >> i) & 1 == 1 {
                // Le bit i du masque est actif, stocker le tryte
                if let Some(tryte) = value.tryte(i) {
                    let tryte_addr = addr + i;
                    self.write_tryte(tryte_addr, *tryte)?;
                }
            }
        }
        
        Ok(())
    }
    
    /// Exécute une instruction de copie mémoire ternaire
    fn execute_tmemcpy(&mut self, rd: Register, rs1: Register, rs2: Register) -> Result<(), ExecuteError> {
        // Lire l'adresse source
        let src_addr = self.read_gpr(rs1).to_i32() as usize;
        
        // Lire l'adresse destination
        let dst_addr = self.read_gpr(rd).to_i32() as usize;
        
        // Lire la taille à copier (en trytes)
        let size = self.read_gpr(rs2).to_i32() as usize;
        
        // Copier les trytes
        for i in 0..size {
            let tryte = self.read_tryte(src_addr + i)?;
            self.write_tryte(dst_addr + i, tryte)?;
        }
        
        Ok(())
    }
    
    /// Exécute une instruction d'initialisation mémoire ternaire
    fn execute_tmemset(&mut self, rd: Register, rs1: Register, rs2: Register) -> Result<(), ExecuteError> {
        // Lire l'adresse destination
        let dst_addr = self.read_gpr(rd).to_i32() as usize;
        
        // Lire la valeur à écrire
        let value = self.read_gpr(rs1);
        
        // Lire la taille à initialiser (en trytes)
        let size = self.read_gpr(rs2).to_i32() as usize;
        
        // Initialiser les trytes
        for i in 0..size {
            // Utiliser le premier tryte de la valeur pour initialiser
            if let Some(tryte) = value.tryte(0) {
                self.write_tryte(dst_addr + i, *tryte)?;
            }
        }
        
        Ok(())
    }
    
    /// Exécute une instruction multi-opération (multiplication-addition)
    fn execute_maddw(&mut self, rd: Register, rs1: Register, rs2: Register, rs3: Register) -> Result<(), ExecuteError> {
        // Lire les valeurs des registres
        let a = self.read_gpr(rs1);
        let b = self.read_gpr(rs2);
        let c = self.read_gpr(rs3);
        
        // Calculer a * b + c
        let product = mul_24_trits(a, b);
        let (result, _, _) = add_24_trits(product, c, Trit::Z);
        
        // Écrire le résultat dans le registre destination
        self.write_gpr(rd, result);
        Ok(())
    }
    
    /// Exécute une instruction multi-opération (multiplication-soustraction)
    fn execute_msubw(&mut self, rd: Register, rs1: Register, rs2: Register, rs3: Register) -> Result<(), ExecuteError> {
        // Lire les valeurs des registres
        let a = self.read_gpr(rs1);
        let b = self.read_gpr(rs2);
        let c = self.read_gpr(rs3);
        
        // Calculer a * b - c
        let product = mul_24_trits(a, b);
        let (result, _, _) = sub_24_trits(product, c, Trit::Z);
        
        // Écrire le résultat dans le registre destination
        self.write_gpr(rd, result);
        Ok(())
    }
    
    /// Exécute une instruction pour les états spéciaux
    fn execute_special_state(&mut self, op: SpecialStateOp, rs1: Register, rd: Register) -> Result<(), ExecuteError> {
        // Lire la valeur du registre
        let a = self.read_gpr(rs1);
        
        // Exécuter l'opération sur les états spéciaux
        let result = ext_execute_special_state_op(op, a, &mut Register::R0);
        
        // Écrire le résultat
        self.write_gpr(rd, result);
        Ok(())
    }
    
    /// Exécute une instruction de sélection ternaire
    fn execute_tsel(&mut self, rd: Register, rs1: Register, rs2: Register, rs3: Register) -> Result<(), ExecuteError> {
        // Lire les valeurs des registres
        let a = self.read_gpr(rs1); // Sélecteur
        let b = self.read_gpr(rs2); // Valeur si négatif
        let c = self.read_gpr(rs3); // Valeur si positif
        
        // Sélectionner en fonction de la valeur de a
        let result = ext_execute_tsel(a, b, c);
        
        // Écrire le résultat dans le registre destination
        self.write_gpr(rd, result);
        Ok(())
    }
    
    /// Exécute une instruction de base 24
    fn execute_base24(&mut self, op: Base24Op, rs1: Register, rs2: Register, rd: Register) -> Result<(), ExecuteError> {
        // Lire les valeurs des registres
        let a = self.read_gpr(rs1);
        let b = self.read_gpr(rs2);
        
        // Exécuter l'opération en base 24
        let result = ext_execute_base24_op(op, a, b);
        
        // Écrire le résultat dans le registre destination
        self.write_gpr(rd, result);
        Ok(())
    }
}

/// Implémentation des méthodes spécifiques pour le CPU
impl crate::cpu::execute::Cpu {
    /// Exécute une instruction de manipulation de vecteur ternaire
    pub fn execute_tvpu_instruction(&mut self, _opcode: u8, _rs1: Register, _rs2: Register, _rd: Register) -> Result<(), ExecuteError> {
        // Implémentation à venir
        Ok(())
    }
    
    /// Met à jour les flags en fonction du résultat d'une opération
    fn update_flags_from_result(&mut self, _result: Word) {
        // Implémentation à venir
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::memory::SimpleMemory;
    use crate::cpu::CPU;
    
    // Fonction utilitaire pour convertir un Word en i32
    fn word_to_i32(word: Word) -> i32 {
        word.trytes().iter().enumerate().fold(0, |acc, (i, tryte)| {
            let val = tryte.bal3_value() as i32;
            acc + val * 27i32.pow(i as u32)
        })
    }
    
    #[test]
    fn test_ternary_instruction() {
        let mut memory = SimpleMemory::new(1024);
        let mut cpu = CPU::new(memory);
        
        // Initialiser les registres
        let a = Word::from_int(5);
        let b = Word::from_int(3);
        cpu.registers.write(1, a);
        cpu.registers.write(2, b);
        
        // Exécuter l'instruction TMIN
        cpu.execute_ternary(TernaryOp::TMIN, 1, 2, 3).unwrap();
        
        // Vérifier le résultat
        let result = cpu.registers.read(3);
        assert_eq!(word_to_i32(result), 3); // min(5, 3) = 3
        
        // Exécuter l'instruction TMAX
        cpu.execute_ternary(TernaryOp::TMAX, 1, 2, 3).unwrap();
        
        // Vérifier le résultat
        let result = cpu.registers.read(3);
        assert_eq!(word_to_i32(result), 5); // max(5, 3) = 5
    }
    
    #[test]
    fn test_branch3() {
        let mut memory = SimpleMemory::new(1024);
        let mut cpu = CPU::new(memory);
        
        // Initialiser le PC
        cpu.registers.write_pc(100);
        
        // Cas 1: Valeur négative
        let neg_value = Word::from_int(-1);
        cpu.registers.write(1, neg_value);
        cpu.execute_branch3(1, 10, 20, 30).unwrap();
        let pc_val = word_to_i32(cpu.registers.read_pc());
        assert_eq!(pc_val, 100 + 10 * 4);
        
        // Cas 2: Valeur zéro
        let zero_value = Word::from_int(0);
        cpu.registers.write(1, zero_value);
        cpu.registers.write_pc(100); // Réinitialiser le PC
        cpu.execute_branch3(1, 10, 20, 30).unwrap();
        let pc_val = word_to_i32(cpu.registers.read_pc());
        assert_eq!(pc_val, 100 + 20 * 4);
        
        // Cas 3: Valeur positive
        let pos_value = Word::from_int(1);
        cpu.registers.write(1, pos_value);
        cpu.registers.write_pc(100); // Réinitialiser le PC
        cpu.execute_branch3(1, 10, 20, 30).unwrap();
        let pc_val = word_to_i32(cpu.registers.read_pc());
        assert_eq!(pc_val, 100 + 30 * 4);
    }
    
    // Autres tests pour les instructions ternaires spécialisées...
}