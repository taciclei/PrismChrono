// src/cpu/execute_ternary.rs
// Implémentation des instructions ternaires spécialisées pour l'architecture PrismChrono

use crate::types::{Trit, Word, Address};
use crate::cpu::registers::RegisterFile;
use crate::memory::Memory;
use crate::cpu::execute_core::ExecuteError;
use crate::cpu::isa_extensions::{TernaryOp, TernaryShiftOp, SpecialStateOp, Base24Op};
use crate::cpu::isa_extensions::{execute_ternary_op, execute_ternary_shift, execute_special_state_op, execute_tsel, execute_base24_op};

/// Trait pour l'exécution des instructions ternaires spécialisées
pub trait ExecuteTernary {
    /// Exécute une instruction ternaire spécialisée (TMIN, TMAX, TSUM, TCMP3)
    fn execute_ternary_instruction(&mut self, op: TernaryOp, rs1: usize, rs2: usize, rd: usize) -> Result<(), ExecuteError>;
    
    /// Exécute une instruction de rotation ou décalage ternaire
    fn execute_ternary_shift(&mut self, op: TernaryShiftOp, rs1: usize, rd: usize, imm: i32) -> Result<(), ExecuteError>;
    
    /// Exécute une instruction de branchement ternaire (BRANCH3)
    fn execute_branch3(&mut self, rs1: usize, offset_neg: i32, offset_zero: i32, offset_pos: i32) -> Result<(), ExecuteError>;
    
    /// Exécute une instruction de chargement de 3 trytes consécutifs
    fn execute_load_t3(&mut self, rd: usize, rs1: usize, offset: i32) -> Result<(), ExecuteError>;
    
    /// Exécute une instruction de stockage de 3 trytes consécutifs
    fn execute_store_t3(&mut self, rs1: usize, rs2: usize, offset: i32) -> Result<(), ExecuteError>;
    
    /// Exécute une instruction de chargement avec masque de trytes
    fn execute_load_tm(&mut self, rd: usize, rs1: usize, mask: u8, offset: i32) -> Result<(), ExecuteError>;
    
    /// Exécute une instruction de stockage avec masque de trytes
    fn execute_store_tm(&mut self, rs1: usize, rs2: usize, mask: u8, offset: i32) -> Result<(), ExecuteError>;
    
    /// Exécute une instruction de copie mémoire ternaire
    fn execute_tmemcpy(&mut self, rd: usize, rs1: usize, rs2: usize) -> Result<(), ExecuteError>;
    
    /// Exécute une instruction d'initialisation mémoire ternaire
    fn execute_tmemset(&mut self, rd: usize, rs1: usize, rs2: usize) -> Result<(), ExecuteError>;
    
    /// Exécute une instruction multi-opération (multiplication-addition)
    fn execute_maddw(&mut self, rd: usize, rs1: usize, rs2: usize, rs3: usize) -> Result<(), ExecuteError>;
    
    /// Exécute une instruction multi-opération (multiplication-soustraction)
    fn execute_msubw(&mut self, rd: usize, rs1: usize, rs2: usize, rs3: usize) -> Result<(), ExecuteError>;
    
    /// Exécute une instruction pour les états spéciaux
    fn execute_special_state(&mut self, op: SpecialStateOp, rs1: usize, rd: usize) -> Result<(), ExecuteError>;
    
    /// Exécute une instruction de sélection ternaire
    fn execute_tsel(&mut self, rd: usize, rs1: usize, rs2: usize, rs3: usize) -> Result<(), ExecuteError>;
    
    /// Exécute une instruction arithmétique en base 24
    fn execute_base24(&mut self, op: Base24Op, rs1: usize, rs2: usize, rd: usize) -> Result<(), ExecuteError>;
}

/// Implémentation du trait ExecuteTernary pour le CPU
impl<M: Memory> ExecuteTernary for crate::cpu::CPU<M> {
    /// Exécute une instruction ternaire spécialisée (TMIN, TMAX, TSUM, TCMP3)
    fn execute_ternary_instruction(&mut self, op: TernaryOp, rs1: usize, rs2: usize, rd: usize) -> Result<(), ExecuteError> {
        // Vérifier la validité des registres
        if rs1 >= 8 || rs2 >= 8 || rd >= 8 {
            return Err(ExecuteError::InvalidRegister);
        }
        
        // Lire les valeurs des registres sources
        let a = self.registers.read(rs1);
        let b = self.registers.read(rs2);
        
        // Exécuter l'opération ternaire
        let result = execute_ternary_op(op, a, b);
        
        // Écrire le résultat dans le registre destination
        self.registers.write(rd, result);
        
        // Mettre à jour les flags si nécessaire
        self.update_flags_from_result(&result);
        
        // Incrémenter les compteurs de métriques
        self.metrics.ternary_ops += 1;
        
        Ok(())
    }
    
    /// Exécute une instruction de rotation ou décalage ternaire
    fn execute_ternary_shift(&mut self, op: TernaryShiftOp, rs1: usize, rd: usize, imm: i32) -> Result<(), ExecuteError> {
        // Vérifier la validité des registres
        if rs1 >= 8 || rd >= 8 {
            return Err(ExecuteError::InvalidRegister);
        }
        
        // Lire la valeur du registre source
        let a = self.registers.read(rs1);
        
        // Exécuter l'opération de rotation ou décalage
        let result = execute_ternary_shift(op, a, imm);
        
        // Écrire le résultat dans le registre destination
        self.registers.write(rd, result);
        
        // Mettre à jour les flags si nécessaire
        self.update_flags_from_result(&result);
        
        // Incrémenter les compteurs de métriques
        self.metrics.shift_ops += 1;
        
        Ok(())
    }
    
    /// Exécute une instruction de branchement ternaire (BRANCH3)
    fn execute_branch3(&mut self, rs1: usize, offset_neg: i32, offset_zero: i32, offset_pos: i32) -> Result<(), ExecuteError> {
        // Vérifier la validité du registre
        if rs1 >= 8 {
            return Err(ExecuteError::InvalidRegister);
        }
        
        // Lire la valeur du registre source
        let value = self.registers.read(rs1);
        
        // Déterminer l'offset en fonction de la valeur du premier trit
        let offset = match value.get_trit(0).value() {
            -1 => offset_neg,
            0 => offset_zero,
            1 => offset_pos,
            _ => 0, // Ne devrait jamais arriver
        };
        
        // Calculer la nouvelle adresse
        let pc = self.registers.read_pc();
        let new_pc = pc + (offset * 4) as u32; // 4 trytes par instruction
        
        // Mettre à jour le PC
        self.registers.write_pc(new_pc);
        
        // Incrémenter les compteurs de métriques
        self.metrics.branches_total += 1;
        self.metrics.branches_taken += 1;
        
        Ok(())
    }
    
    /// Exécute une instruction de chargement de 3 trytes consécutifs
    fn execute_load_t3(&mut self, rd: usize, rs1: usize, offset: i32) -> Result<(), ExecuteError> {
        // Vérifier la validité des registres
        if rs1 >= 8 || rd >= 8 {
            return Err(ExecuteError::InvalidRegister);
        }
        
        // Lire l'adresse de base
        let base_addr = self.registers.read(rs1).to_u32();
        
        // Calculer l'adresse effective
        let addr = base_addr.wrapping_add(offset as u32);
        
        // Créer un mot pour stocker le résultat
        let mut result = Word::new();
        
        // Charger 3 trytes consécutifs
        for i in 0..3 {
            let tryte = self.memory.read_tryte(addr.wrapping_add(i as u32))
                .map_err(|e| ExecuteError::MemoryError(e))?;
            
            result.set_tryte(i, tryte);
        }
        
        // Écrire le résultat dans le registre destination
        self.registers.write(rd, result);
        
        // Incrémenter les compteurs de métriques
        self.metrics.memory_reads += 3;
        
        Ok(())
    }
    
    /// Exécute une instruction de stockage de 3 trytes consécutifs
    fn execute_store_t3(&mut self, rs1: usize, rs2: usize, offset: i32) -> Result<(), ExecuteError> {
        // Vérifier la validité des registres
        if rs1 >= 8 || rs2 >= 8 {
            return Err(ExecuteError::InvalidRegister);
        }
        
        // Lire l'adresse de base et la valeur à stocker
        let base_addr = self.registers.read(rs1).to_u32();
        let value = self.registers.read(rs2);
        
        // Calculer l'adresse effective
        let addr = base_addr.wrapping_add(offset as u32);
        
        // Stocker 3 trytes consécutifs
        for i in 0..3 {
            let tryte = value.get_tryte(i);
            self.memory.write_tryte(addr.wrapping_add(i as u32), tryte)
                .map_err(|e| ExecuteError::MemoryError(e))?;
        }
        
        // Incrémenter les compteurs de métriques
        self.metrics.memory_writes += 3;
        
        Ok(())
    }
    
    /// Exécute une instruction de chargement avec masque de trytes
    fn execute_load_tm(&mut self, rd: usize, rs1: usize, mask: u8, offset: i32) -> Result<(), ExecuteError> {
        // Vérifier la validité des registres
        if rs1 >= 8 || rd >= 8 {
            return Err(ExecuteError::InvalidRegister);
        }
        
        // Lire l'adresse de base
        let base_addr = self.registers.read(rs1).to_u32();
        
        // Calculer l'adresse effective
        let addr = base_addr.wrapping_add(offset as u32);
        
        // Créer un mot pour stocker le résultat
        let mut result = Word::new();
        
        // Charger les trytes selon le masque
        let mut reads = 0;
        for i in 0..8 {
            if (mask & (1 << i)) != 0 {
                let tryte = self.memory.read_tryte(addr.wrapping_add(i as u32))
                    .map_err(|e| ExecuteError::MemoryError(e))?;
                
                result.set_tryte(i, tryte);
                reads += 1;
            }
        }
        
        // Écrire le résultat dans le registre destination
        self.registers.write(rd, result);
        
        // Incrémenter les compteurs de métriques
        self.metrics.memory_reads += reads;
        
        Ok(())
    }
    
    /// Exécute une instruction de stockage avec masque de trytes
    fn execute_store_tm(&mut self, rs1: usize, rs2: usize, mask: u8, offset: i32) -> Result<(), ExecuteError> {
        // Vérifier la validité des registres
        if rs1 >= 8 || rs2 >= 8 {
            return Err(ExecuteError::InvalidRegister);
        }
        
        // Lire l'adresse de base et la valeur à stocker
        let base_addr = self.registers.read(rs1).to_u32();
        let value = self.registers.read(rs2);
        
        // Calculer l'adresse effective
        let addr = base_addr.wrapping_add(offset as u32);
        
        // Stocker les trytes selon le masque
        let mut writes = 0;
        for i in 0..8 {
            if (mask & (1 << i)) != 0 {
                let tryte = value.get_tryte(i);
                self.memory.write_tryte(addr.wrapping_add(i as u32), tryte)
                    .map_err(|e| ExecuteError::MemoryError(e))?;
                
                writes += 1;
            }
        }
        
        // Incrémenter les compteurs de métriques
        self.metrics.memory_writes += writes;
        
        Ok(())
    }
    
    /// Exécute une instruction de copie mémoire ternaire
    fn execute_tmemcpy(&mut self, rd: usize, rs1: usize, rs2: usize) -> Result<(), ExecuteError> {
        // Vérifier la validité des registres
        if rd >= 8 || rs1 >= 8 || rs2 >= 8 {
            return Err(ExecuteError::InvalidRegister);
        }
        
        // Lire les adresses source et destination, et la taille
        let dest_addr = self.registers.read(rd).to_u32();
        let src_addr = self.registers.read(rs1).to_u32();
        let size = self.registers.read(rs2).to_u32();
        
        // Limiter la taille pour éviter les boucles infinies
        let max_size = 1024; // Limite arbitraire
        let size = std::cmp::min(size, max_size);
        
        // Copier les trytes un par un
        for i in 0..size {
            let tryte = self.memory.read_tryte(src_addr.wrapping_add(i))
                .map_err(|e| ExecuteError::MemoryError(e))?;
            
            self.memory.write_tryte(dest_addr.wrapping_add(i), tryte)
                .map_err(|e| ExecuteError::MemoryError(e))?;
        }
        
        // Incrémenter les compteurs de métriques
        self.metrics.memory_reads += size as u64;
        self.metrics.memory_writes += size as u64;
        
        Ok(())
    }
    
    /// Exécute une instruction d'initialisation mémoire ternaire
    fn execute_tmemset(&mut self, rd: usize, rs1: usize, rs2: usize) -> Result<(), ExecuteError> {
        // Vérifier la validité des registres
        if rd >= 8 || rs1 >= 8 || rs2 >= 8 {
            return Err(ExecuteError::InvalidRegister);
        }
        
        // Lire l'adresse de destination, la valeur et la taille
        let dest_addr = self.registers.read(rd).to_u32();
        let value = self.registers.read(rs1);
        let size = self.registers.read(rs2).to_u32();
        
        // Limiter la taille pour éviter les boucles infinies
        let max_size = 1024; // Limite arbitraire
        let size = std::cmp::min(size, max_size);
        
        // Initialiser les trytes un par un
        for i in 0..size {
            // Utiliser le premier tryte de la valeur comme valeur d'initialisation
            let tryte = value.get_tryte(0);
            
            self.memory.write_tryte(dest_addr.wrapping_add(i), tryte)
                .map_err(|e| ExecuteError::MemoryError(e))?;
        }
        
        // Incrémenter les compteurs de métriques
        self.metrics.memory_writes += size as u64;
        
        Ok(())
    }
    
    /// Exécute une instruction multi-opération (multiplication-addition)
    fn execute_maddw(&mut self, rd: usize, rs1: usize, rs2: usize, rs3: usize) -> Result<(), ExecuteError> {
        // Vérifier la validité des registres
        if rd >= 8 || rs1 >= 8 || rs2 >= 8 || rs3 >= 8 {
            return Err(ExecuteError::InvalidRegister);
        }
        
        // Lire les valeurs des registres sources
        let a = self.registers.read(rs1).to_i32();
        let b = self.registers.read(rs2).to_i32();
        let c = self.registers.read(rs3).to_i32();
        
        // Calculer le résultat (a * b + c)
        let result = a.wrapping_mul(b).wrapping_add(c);
        
        // Convertir le résultat en Word et l'écrire dans le registre destination
        let result_word = Word::from_i32(result);
        self.registers.write(rd, result_word);
        
        // Mettre à jour les flags si nécessaire
        self.update_flags_from_result(&result_word);
        
        // Incrémenter les compteurs de métriques
        self.metrics.alu_ops += 2; // Une multiplication et une addition
        
        Ok(())
    }
    
    /// Exécute une instruction multi-opération (multiplication-soustraction)
    fn execute_msubw(&mut self, rd: usize, rs1: usize, rs2: usize, rs3: usize) -> Result<(), ExecuteError> {
        // Vérifier la validité des registres
        if rd >= 8 || rs1 >= 8 || rs2 >= 8 || rs3 >= 8 {
            return Err(ExecuteError::InvalidRegister);
        }
        
        // Lire les valeurs des registres sources
        let a = self.registers.read(rs1).to_i32();
        let b = self.registers.read(rs2).to_i32();
        let c = self.registers.read(rs3).to_i32();
        
        // Calculer le résultat (a * b - c)
        let result = a.wrapping_mul(b).wrapping_sub(c);
        
        // Convertir le résultat en Word et l'écrire dans le registre destination
        let result_word = Word::from_i32(result);
        self.registers.write(rd, result_word);
        
        // Mettre à jour les flags si nécessaire
        self.update_flags_from_result(&result_word);
        
        // Incrémenter les compteurs de métriques
        self.metrics.alu_ops += 2; // Une multiplication et une soustraction
        
        Ok(())
    }
    
    /// Exécute une instruction pour les états spéciaux
    fn execute_special_state(&mut self, op: SpecialStateOp, rs1: usize, rd: usize) -> Result<(), ExecuteError> {
        // Vérifier la validité des registres
        if rs1 >= 8 || rd >= 8 {
            return Err(ExecuteError::InvalidRegister);
        }
        
        // Lire la valeur du registre source
        let a = self.registers.read(rs1);
        
        // Exécuter l'opération pour les états spéciaux
        let result = execute_special_state_op(op, a, &mut self.registers);
        
        // Écrire le résultat dans le registre destination
        self.registers.write(rd, result);
        
        // Incrémenter les compteurs de métriques
        self.metrics.alu_ops += 1;
        
        Ok(())
    }
    
    /// Exécute une instruction de sélection ternaire
    fn execute_tsel(&mut self, rd: usize, rs1: usize, rs2: usize, rs3: usize) -> Result<(), ExecuteError> {
        // Vérifier la validité des registres
        if rd >= 8 || rs1 >= 8 || rs2 >= 8 || rs3 >= 8 {
            return Err(ExecuteError::InvalidRegister);
        }
        
        // Lire les valeurs des registres sources
        let a = self.registers.read(rs1);
        let b = self.registers.read(rs2);
        let c = self.registers.read(rs3);
        
        // Exécuter l'opération de sélection ternaire
        let result = execute_tsel(a, b, c);
        
        // Écrire le résultat dans le registre destination
        self.registers.write(rd, result);
        
        // Mettre à jour les flags si nécessaire
        self.update_flags_from_result(&result);
        
        // Incrémenter les compteurs de métriques
        self.metrics.alu_ops += 1;
        self.metrics.branches_total += 1; // Considéré comme un branchement implicite
        
        Ok(())
    }
    
    /// Exécute une instruction arithmétique en base 24
    fn execute_base24(&mut self, op: Base24Op, rs1: usize, rs2: usize, rd: usize) -> Result<(), ExecuteError> {
        // Vérifier la validité des registres
        if rs1 >= 8 || rs2 >= 8 || rd >= 8 {
            return Err(ExecuteError::InvalidRegister);
        }
        
        // Lire les valeurs des registres sources
        let a = self.registers.read(rs1);
        let b = self.registers.read(rs2);
        
        // Exécuter l'opération arithmétique en base 24
        let result = execute_base24_op(op, a, b);
        
        // Écrire le résultat dans le registre destination
        self.registers.write(rd, result);
        
        // Mettre à jour les flags si nécessaire
        self.update_flags_from_result(&result);
        
        // Incrémenter les compteurs de métriques
        self.metrics.alu_ops += 1;
        
        Ok(())
    }
}

/// Méthode auxiliaire pour mettre à jour les flags en fonction du résultat
impl<M: Memory> crate::cpu::CPU<M> {
    fn update_flags_from_result(&mut self, result: &Word) -> () {
        // Vérifier si le résultat est zéro
        let is_zero = result.is_zero();
        
        // Vérifier le signe du résultat (premier trit)
        let is_negative = result.get_trit(23).value() < 0;
        
        // Vérifier si le résultat contient un état spécial
        let has_special = (0..8).any(|i| {
            let tryte = result.get_tryte(i);
            tryte.is_special() // Méthode à implémenter dans la structure Tryte
        });
        
        // Mettre à jour les flags
        self.registers.set_flag_z(is_zero);
        self.registers.set_flag_s(is_negative);
        self.registers.set_flag_x(has_special);
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::memory::SimpleMemory;
    use crate::cpu::CPU;
    
    #[test]
    fn test_ternary_instruction() {
        let mut memory = SimpleMemory::new(1024);
        let mut cpu = CPU::new(memory);
        
        // Initialiser les registres
        let a = Word::from_i32(5);
        let b = Word::from_i32(3);
        cpu.registers.write(1, a);
        cpu.registers.write(2, b);
        
        // Exécuter l'instruction TMIN
        cpu.execute_ternary_instruction(TernaryOp::TMIN, 1, 2, 3).unwrap();
        
        // Vérifier le résultat
        let result = cpu.registers.read(3);
        assert_eq!(result.to_i32(), 3); // min(5, 3) = 3
        
        // Exécuter l'instruction TMAX
        cpu.execute_ternary_instruction(TernaryOp::TMAX, 1, 2, 3).unwrap();
        
        // Vérifier le résultat
        let result = cpu.registers.read(3);
        assert_eq!(result.to_i32(), 5); // max(5, 3) = 5
    }
    
    #[test]
    fn test_branch3() {
        let mut memory = SimpleMemory::new(1024);
        let mut cpu = CPU::new(memory);
        
        // Initialiser le PC
        cpu.registers.write_pc(100);
        
        // Cas 1: Valeur négative
        let neg_value = Word::from_i32(-1);
        cpu.registers.write(1, neg_value);
        cpu.execute_branch3(1, 10, 20, 30).unwrap();
        assert_eq!(cpu.registers.read_pc(), 100 + 10 * 4);
        
        // Cas 2: Valeur zéro
        let zero_value = Word::from_i32(0);
        cpu.registers.write(1, zero_value);
        cpu.registers.write_pc(100); // Réinitialiser le PC
        cpu.execute_branch3(1, 10, 20, 30).unwrap();
        assert_eq!(cpu.registers.read_pc(), 100 + 20 * 4);
        
        // Cas 3: Valeur positive
        let pos_value = Word::from_i32(1);
        cpu.registers.write(1, pos_value);
        cpu.registers.write_pc(100); // Réinitialiser le PC
        cpu.execute_branch3(1, 10, 20, 30).unwrap();
        assert_eq!(cpu.registers.read_pc(), 100 + 30 * 4);
    }
    
    // Autres tests pour les instructions ternaires spécialisées...
}