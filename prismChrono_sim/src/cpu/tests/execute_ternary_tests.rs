// src/cpu/tests/execute_ternary_tests.rs
// Tests pour les instructions ternaires spécialisées

#[cfg(test)]
mod tests {
    use crate::types::{Trit, Word};
    use crate::memory::SimpleMemory;
    use crate::cpu::CPU;
    use crate::cpu::isa_extensions::TernaryOp;
    use crate::cpu::execute_ternary::ExecuteTernary;

    #[test]
    fn test_tmin_instruction() {
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
    }

    #[test]
    fn test_tmax_instruction() {
        let mut memory = SimpleMemory::new(1024);
        let mut cpu = CPU::new(memory);
        
        // Initialiser les registres
        let a = Word::from_i32(5);
        let b = Word::from_i32(3);
        cpu.registers.write(1, a);
        cpu.registers.write(2, b);
        
        // Exécuter l'instruction TMAX
        cpu.execute_ternary_instruction(TernaryOp::TMAX, 1, 2, 3).unwrap();
        
        // Vérifier le résultat
        let result = cpu.registers.read(3);
        assert_eq!(result.to_i32(), 5); // max(5, 3) = 5
    }

    #[test]
    fn test_tsum_instruction() {
        let mut memory = SimpleMemory::new(1024);
        let mut cpu = CPU::new(memory);
        
        // Cas 1: Somme simple
        let a = Word::from_i32(1);  // Représentation ternaire: ...001
        let b = Word::from_i32(1);  // Représentation ternaire: ...001
        cpu.registers.write(1, a);
        cpu.registers.write(2, b);
        
        // Exécuter l'instruction TSUM
        cpu.execute_ternary_instruction(TernaryOp::TSUM, 1, 2, 3).unwrap();
        
        // Vérifier le résultat (sans propagation: 1+1=2 -> trit P)
        let result = cpu.registers.read(3);
        assert_eq!(result.to_i32(), 1); // Le résultat devrait être 1 (P) car TSUM fait la somme sans propagation
        
        // Cas 2: Somme avec valeurs négatives
        let a = Word::from_i32(-1); // Représentation ternaire: ...00N
        let b = Word::from_i32(-1); // Représentation ternaire: ...00N
        cpu.registers.write(1, a);
        cpu.registers.write(2, b);
        
        // Exécuter l'instruction TSUM
        cpu.execute_ternary_instruction(TernaryOp::TSUM, 1, 2, 3).unwrap();
        
        // Vérifier le résultat (sans propagation: -1+-1=-2 -> trit N)
        let result = cpu.registers.read(3);
        assert_eq!(result.to_i32(), -1); // Le résultat devrait être -1 (N) car TSUM fait la somme sans propagation
    }

    #[test]
    fn test_tcmp3_instruction() {
        let mut memory = SimpleMemory::new(1024);
        let mut cpu = CPU::new(memory);
        
        // Cas 1: Premier opérande plus petit
        let a = Word::from_i32(3);
        let b = Word::from_i32(5);
        cpu.registers.write(1, a);
        cpu.registers.write(2, b);
        
        // Exécuter l'instruction TCMP3
        cpu.execute_ternary_instruction(TernaryOp::TCMP3, 1, 2, 3).unwrap();
        
        // Vérifier le résultat (3 < 5 -> N)
        let result = cpu.registers.read(3);
        // Le résultat devrait avoir tous les trits à N (-1)
        for i in 0..24 {
            assert_eq!(result.get_trit(i), Trit::N);
        }
        
        // Cas 2: Opérandes égaux
        let a = Word::from_i32(5);
        let b = Word::from_i32(5);
        cpu.registers.write(1, a);
        cpu.registers.write(2, b);
        
        // Exécuter l'instruction TCMP3
        cpu.execute_ternary_instruction(TernaryOp::TCMP3, 1, 2, 3).unwrap();
        
        // Vérifier le résultat (5 = 5 -> Z)
        let result = cpu.registers.read(3);
        // Le résultat devrait avoir tous les trits à Z (0)
        for i in 0..24 {
            assert_eq!(result.get_trit(i), Trit::Z);
        }
        
        // Cas 3: Premier opérande plus grand
        let a = Word::from_i32(7);
        let b = Word::from_i32(5);
        cpu.registers.write(1, a);
        cpu.registers.write(2, b);
        
        // Exécuter l'instruction TCMP3
        cpu.execute_ternary_instruction(TernaryOp::TCMP3, 1, 2, 3).unwrap();
        
        // Vérifier le résultat (7 > 5 -> P)
        let result = cpu.registers.read(3);
        // Le résultat devrait avoir tous les trits à P (1)
        for i in 0..24 {
            assert_eq!(result.get_trit(i), Trit::P);
        }
    }
}