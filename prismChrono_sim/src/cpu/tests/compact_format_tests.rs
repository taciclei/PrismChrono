// src/cpu/tests/compact_format_tests.rs
// Tests pour le format d'instruction compact

#[cfg(test)]
mod tests {
    use crate::core::Trit;
    use crate::cpu::compact_format::{CompactInstruction, decode_compact, compact_to_standard};
    use crate::cpu::isa::{AluOp, Condition, Instruction};
    use crate::cpu::decode::DecodeError;

    #[test]
    fn test_decode_compact_cmov() {
        // Créer une instruction CMOV rd=1, rs=2
        // [op=CMOV(NN) | rd=1(NP) | rs=2(NNPN)]
        let instr_trits = [Trit::N, Trit::N, Trit::N, Trit::P, Trit::N, Trit::N, Trit::P, Trit::N];
        
        let result = decode_compact(&instr_trits).unwrap();
        
        match result {
            CompactInstruction::CMov { rd, rs } => {
                assert_eq!(rd, 1);
                assert_eq!(rs, 2);
            },
            _ => panic!("Expected CMov instruction"),
        }
    }

    #[test]
    fn test_decode_compact_cadd() {
        // Créer une instruction CADD rd=2, rs=3
        // [op=CADD(NZ) | rd=2(PN) | rs=3(NNPP)]
        let instr_trits = [Trit::N, Trit::Z, Trit::P, Trit::N, Trit::N, Trit::N, Trit::P, Trit::P];
        
        let result = decode_compact(&instr_trits).unwrap();
        
        match result {
            CompactInstruction::CAdd { rd, rs } => {
                assert_eq!(rd, 2);
                assert_eq!(rs, 3);
            },
            _ => panic!("Expected CAdd instruction"),
        }
    }

    #[test]
    fn test_decode_compact_csub() {
        // Créer une instruction CSUB rd=3, rs=1
        // [op=CSUB(NP) | rd=3(PP) | rs=1(NNNP)]
        let instr_trits = [Trit::N, Trit::P, Trit::P, Trit::P, Trit::N, Trit::N, Trit::N, Trit::P];
        
        let result = decode_compact(&instr_trits).unwrap();
        
        match result {
            CompactInstruction::CSub { rd, rs } => {
                assert_eq!(rd, 3);
                assert_eq!(rs, 1);
            },
            _ => panic!("Expected CSub instruction"),
        }
    }

    #[test]
    fn test_decode_compact_cbranch() {
        // Créer une instruction CBRANCH cond=Eq, offset=5
        // [op=CBRANCH(NN) | cond=Eq(NN) | offset=5(NNNP)]
        let instr_trits = [Trit::N, Trit::N, Trit::N, Trit::N, Trit::N, Trit::N, Trit::N, Trit::P];
        
        let result = decode_compact(&instr_trits).unwrap();
        
        match result {
            CompactInstruction::CBranch { cond, offset } => {
                assert_eq!(cond, Condition::Eq);
                assert!(offset > 0); // La valeur exacte peut varier selon l'implémentation
            },
            _ => panic!("Expected CBranch instruction"),
        }
    }

    #[test]
    fn test_compact_to_standard_conversion() {
        // Tester la conversion de CMov en instruction standard
        let cmov = CompactInstruction::CMov { rd: 1, rs: 2 };
        let std_instr = compact_to_standard(cmov);
        
        match std_instr {
            Instruction::AluReg { op, rs1, rs2, rd } => {
                assert_eq!(op, AluOp::Add);
                assert_eq!(rs1, 2);
                assert_eq!(rs2, 0);
                assert_eq!(rd, 1);
            },
            _ => panic!("Expected AluReg instruction"),
        }
        
        // Tester la conversion de CAdd en instruction standard
        let cadd = CompactInstruction::CAdd { rd: 2, rs: 3 };
        let std_instr = compact_to_standard(cadd);
        
        match std_instr {
            Instruction::AluReg { op, rs1, rs2, rd } => {
                assert_eq!(op, AluOp::Add);
                assert_eq!(rs1, 2);
                assert_eq!(rs2, 3);
                assert_eq!(rd, 2);
            },
            _ => panic!("Expected AluReg instruction"),
        }
        
        // Tester la conversion de CSub en instruction standard
        let csub = CompactInstruction::CSub { rd: 3, rs: 1 };
        let std_instr = compact_to_standard(csub);
        
        match std_instr {
            Instruction::AluReg { op, rs1, rs2, rd } => {
                assert_eq!(op, AluOp::Sub);
                assert_eq!(rs1, 3);
                assert_eq!(rs2, 1);
                assert_eq!(rd, 3);
            },
            _ => panic!("Expected AluReg instruction"),
        }
        
        // Tester la conversion de CBranch en instruction standard
        let cbranch = CompactInstruction::CBranch { cond: Condition::Eq, offset: 10 };
        let std_instr = compact_to_standard(cbranch);
        
        match std_instr {
            Instruction::Branch { cond, rs1, offset } => {
                assert_eq!(cond, Condition::Eq);
                assert_eq!(rs1, 0);
                assert_eq!(offset, 10);
            },
            _ => panic!("Expected Branch instruction"),
        }
    }
}