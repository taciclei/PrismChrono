// src/bin/test_branch.rs
// Programme de test pour les instructions de branchement conditionnel

use prismchrono_sim::core::is_valid_address;
use prismchrono_sim::core::{Trit, Tryte, Word};
use prismchrono_sim::cpu::decode::decode;
use prismchrono_sim::cpu::execute::ExecuteError;
use prismchrono_sim::cpu::execute_branch::BranchOperations;
use prismchrono_sim::cpu::isa::{AluOp, Condition, Instruction};
use prismchrono_sim::cpu::registers::Register;
use prismchrono_sim::memory::Memory;

fn main() {
    println!("Test des instructions de branchement conditionnel");

    // Créer une instance du CPU avec une mémoire de taille suffisante
    let mut cpu = prismchrono_sim::cpu::Cpu::new();

    // Programme de test pour les instructions de branchement
    // Ce programme teste toutes les conditions de branchement
    let program = [
        // Initialiser R3 à 100 (adresse de base pour les branchements)
        Instruction::AluImm {
            op: AluOp::Add,
            rs1: Register::R0,
            rd: Register::R3,
            imm: 100,
        },
        // 1. Test de BRANCH EQ (égalité)
        // Initialiser R1 à 10
        Instruction::AluImm {
            op: AluOp::Add,
            rs1: Register::R0,
            rd: Register::R1,
            imm: 10,
        },
        // Initialiser R2 à 10 aussi
        Instruction::AluImm {
            op: AluOp::Add,
            rs1: Register::R0,
            rd: Register::R2,
            imm: 10,
        },
        // Comparer R1 et R2 (devrait mettre ZF à 1)
        Instruction::AluReg {
            op: AluOp::Cmp,
            rs1: Register::R1,
            rs2: Register::R2,
            rd: Register::R0,
        },
        // BRANCH EQ, offset: 2 (devrait sauter à R3+2*4)
        Instruction::Branch {
            rs1: Register::R3,
            cond: Condition::Eq,
            offset: 2,
        },
        // Si le branchement n'est pas pris, on met R4 à 1 (ne devrait pas être exécuté)
        Instruction::AluImm {
            op: AluOp::Add,
            rs1: Register::R0,
            rd: Register::R4,
            imm: 1,
        },
        // Si le branchement est pris, on arrive ici et on met R5 à 1
        Instruction::AluImm {
            op: AluOp::Add,
            rs1: Register::R0,
            rd: Register::R5,
            imm: 1,
        },
        // 2. Test de BRANCH NE (non-égalité)
        // Initialiser R1 à 10
        Instruction::AluImm {
            op: AluOp::Add,
            rs1: Register::R0,
            rd: Register::R1,
            imm: 10,
        },
        // Initialiser R2 à 20 (différent de R1)
        Instruction::AluImm {
            op: AluOp::Add,
            rs1: Register::R0,
            rd: Register::R2,
            imm: 20,
        },
        // Comparer R1 et R2 (devrait mettre ZF à 0)
        Instruction::AluReg {
            op: AluOp::Cmp,
            rs1: Register::R1,
            rs2: Register::R2,
            rd: Register::R0,
        },
        // BRANCH NE, offset: 2 (devrait sauter à R3+2*4)
        Instruction::Branch {
            rs1: Register::R3,
            cond: Condition::Ne,
            offset: 2,
        },
        // Si le branchement n'est pas pris, on met R6 à 1 (ne devrait pas être exécuté)
        Instruction::AluImm {
            op: AluOp::Add,
            rs1: Register::R0,
            rd: Register::R6,
            imm: 1,
        },
        // Si le branchement est pris, on arrive ici et on met R7 à 1
        Instruction::AluImm {
            op: AluOp::Add,
            rs1: Register::R0,
            rd: Register::R7,
            imm: 1,
        },
        // 3. Test de BRANCH LT (inférieur à)
        // Initialiser R1 à 5
        Instruction::AluImm {
            op: AluOp::Add,
            rs1: Register::R0,
            rd: Register::R1,
            imm: 5,
        },
        // Initialiser R2 à 10 (R1 < R2)
        Instruction::AluImm {
            op: AluOp::Add,
            rs1: Register::R0,
            rd: Register::R2,
            imm: 10,
        },
        // Comparer R1 et R2 (devrait mettre SF à 1 car R1 < R2)
        Instruction::AluReg {
            op: AluOp::Cmp,
            rs1: Register::R1,
            rs2: Register::R2,
            rd: Register::R0,
        },
        // BRANCH LT, offset: 2 (devrait sauter à R3+2*4)
        Instruction::Branch {
            rs1: Register::R3,
            cond: Condition::Lt,
            offset: 2,
        },
        // Si le branchement n'est pas pris, on met R1 à 100 (ne devrait pas être exécuté)
        Instruction::AluImm {
            op: AluOp::Add,
            rs1: Register::R0,
            rd: Register::R1,
            imm: 100,
        },
        // Si le branchement est pris, on arrive ici et on met R1 à 200
        Instruction::AluImm {
            op: AluOp::Add,
            rs1: Register::R0,
            rd: Register::R1,
            imm: 200,
        },
        // 4. Test de BRANCH GE (supérieur ou égal à)
        // Initialiser R1 à 20
        Instruction::AluImm {
            op: AluOp::Add,
            rs1: Register::R0,
            rd: Register::R1,
            imm: 20,
        },
        // Initialiser R2 à 10 (R1 > R2)
        Instruction::AluImm {
            op: AluOp::Add,
            rs1: Register::R0,
            rd: Register::R2,
            imm: 10,
        },
        // Comparer R1 et R2 (devrait mettre SF à 0 car R1 > R2)
        Instruction::AluReg {
            op: AluOp::Cmp,
            rs1: Register::R1,
            rs2: Register::R2,
            rd: Register::R0,
        },
        // BRANCH GE, offset: 2 (devrait sauter à R3+2*4)
        Instruction::Branch {
            rs1: Register::R3,
            cond: Condition::Ge,
            offset: 2,
        },
        // Si le branchement n'est pas pris, on met R2 à 100 (ne devrait pas être exécuté)
        Instruction::AluImm {
            op: AluOp::Add,
            rs1: Register::R0,
            rd: Register::R2,
            imm: 100,
        },
        // Si le branchement est pris, on arrive ici et on met R2 à 200
        Instruction::AluImm {
            op: AluOp::Add,
            rs1: Register::R0,
            rd: Register::R2,
            imm: 200,
        },
        // 5. Test de BRANCH LTU (inférieur à, non signé)
        // Initialiser R1 à 5
        Instruction::AluImm {
            op: AluOp::Add,
            rs1: Register::R0,
            rd: Register::R1,
            imm: 5,
        },
        // Initialiser R2 à 10 (R1 < R2)
        Instruction::AluImm {
            op: AluOp::Add,
            rs1: Register::R0,
            rd: Register::R2,
            imm: 10,
        },
        // Comparer R1 et R2 (devrait mettre ZF à 1 pour LTU)
        Instruction::AluReg {
            op: AluOp::Cmp,
            rs1: Register::R1,
            rs2: Register::R2,
            rd: Register::R0,
        },
        // BRANCH LTU, offset: 2 (devrait sauter à R3+2*4)
        Instruction::Branch {
            rs1: Register::R3,
            cond: Condition::Ltu,
            offset: 2,
        },
        // Si le branchement n'est pas pris, on met R1 à 50 (ne devrait pas être exécuté)
        Instruction::AluImm {
            op: AluOp::Add,
            rs1: Register::R0,
            rd: Register::R1,
            imm: 50,
        },
        // Si le branchement est pris, on arrive ici et on met R1 à 55
        Instruction::AluImm {
            op: AluOp::Add,
            rs1: Register::R0,
            rd: Register::R1,
            imm: 55,
        },
        // 6. Test de BRANCH GEU (supérieur ou égal à, non signé)
        // Initialiser R1 à 20
        Instruction::AluImm {
            op: AluOp::Add,
            rs1: Register::R0,
            rd: Register::R1,
            imm: 20,
        },
        // Initialiser R2 à 10 (R1 > R2)
        Instruction::AluImm {
            op: AluOp::Add,
            rs1: Register::R0,
            rd: Register::R2,
            imm: 10,
        },
        // Comparer R1 et R2 (devrait mettre ZF à 0 pour GEU)
        Instruction::AluReg {
            op: AluOp::Cmp,
            rs1: Register::R1,
            rs2: Register::R2,
            rd: Register::R0,
        },
        // BRANCH GEU, offset: 2 (devrait sauter à R3+2*4)
        Instruction::Branch {
            rs1: Register::R3,
            cond: Condition::Geu,
            offset: 2,
        },
        // Si le branchement n'est pas pris, on met R2 à 50 (ne devrait pas être exécuté)
        Instruction::AluImm {
            op: AluOp::Add,
            rs1: Register::R0,
            rd: Register::R2,
            imm: 50,
        },
        // Si le branchement est pris, on arrive ici et on met R2 à 55
        Instruction::AluImm {
            op: AluOp::Add,
            rs1: Register::R0,
            rd: Register::R2,
            imm: 55,
        },
        // 7. Test de BRANCH SPECIAL (XF=1)
        // Initialiser le flag XF à 1 (on utilise une opération spéciale qui met XF à 1)
        // Pour ce test, on va simplement utiliser une opération ALU qui met XF à 1
        // Note: Dans un cas réel, XF serait défini par une opération spécifique
        Instruction::AluImm {
            op: AluOp::TritInv,
            rs1: Register::R0,
            rd: Register::R0,
            imm: 0,
        },
        // BRANCH SPECIAL, offset: 2 (devrait sauter à R3+2*4 si XF=1)
        Instruction::Branch {
            rs1: Register::R3,
            cond: Condition::Special,
            offset: 2,
        },
        // Si le branchement n'est pas pris, on met R1 à 60 (ne devrait pas être exécuté si XF=1)
        Instruction::AluImm {
            op: AluOp::Add,
            rs1: Register::R0,
            rd: Register::R1,
            imm: 60,
        },
        // Si le branchement est pris, on arrive ici et on met R1 à 65
        Instruction::AluImm {
            op: AluOp::Add,
            rs1: Register::R0,
            rd: Register::R1,
            imm: 65,
        },
        // 8. Test de BRANCH ALWAYS (toujours pris)
        // BRANCH ALWAYS, offset: 2 (devrait toujours sauter à R3+2*4)
        Instruction::Branch {
            rs1: Register::R3,
            cond: Condition::Always,
            offset: 2,
        },
        // Si le branchement n'est pas pris, on met R2 à 60 (ne devrait jamais être exécuté)
        Instruction::AluImm {
            op: AluOp::Add,
            rs1: Register::R0,
            rd: Register::R2,
            imm: 60,
        },
        // Si le branchement est pris, on arrive ici et on met R2 à 65
        Instruction::AluImm {
            op: AluOp::Add,
            rs1: Register::R0,
            rd: Register::R2,
            imm: 65,
        },
        // Arrêter le CPU
        Instruction::Halt,
    ];

    // Charger le programme en mémoire
    let mut addr = 0;
    for instr in program.iter() {
        // Encoder l'instruction en trits
        let trits = encode_instruction(instr);

        // Écrire les trits en mémoire
        for i in 0..4 {
            let tryte = Tryte::from_trits([trits[i * 3], trits[i * 3 + 1], trits[i * 3 + 2]]);
            cpu.memory.write_tryte(addr + i, tryte).unwrap();
        }

        addr += 4; // Passer à l'instruction suivante (4 trytes par instruction)
    }

    // Exécuter le programme
    println!("Exécution du programme...");
    let mut step_count = 0;
    while !cpu.halted && step_count < 100 {
        // Limite de sécurité
        match cpu.step() {
            Ok(_) => {
                step_count += 1;
                println!(
                    "Étape {}: PC = {}, R1 = {}, R2 = {}, R3 = {}, R4 = {}, R5 = {}, R6 = {}, R7 = {}, Flags = {}",
                    step_count,
                    cpu.state.read_pc(),
                    cpu.state.read_gpr(Register::R1),
                    cpu.state.read_gpr(Register::R2),
                    cpu.state.read_gpr(Register::R3),
                    cpu.state.read_gpr(Register::R4),
                    cpu.state.read_gpr(Register::R5),
                    cpu.state.read_gpr(Register::R6),
                    cpu.state.read_gpr(Register::R7),
                    cpu.state.read_flags()
                );

                // Afficher des informations supplémentaires sur l'instruction en cours
                // Convertir le PC (Word) en entier
                let pc_word = cpu.state.read_pc();
                let mut current_pc: usize = 0;
                for i in 0..8 {
                    if let Some(tryte) = pc_word.tryte(i) {
                        match tryte {
                            Tryte::Digit(digit) => {
                                // Convertir le digit en valeur ternaire équilibrée (-13 à +13)
                                let val = (*digit as i32 - 13) as i32;
                                // Ajouter la contribution de ce tryte (base 27)
                                current_pc = current_pc.wrapping_add(
                                    (val as usize).wrapping_mul(27usize.pow(i as u32)),
                                );
                            }
                            _ => break, // Ignorer les trytes non-digit
                        }
                    }
                }
                if current_pc % 4 == 0 && current_pc < addr {
                    let mut instr_trits = [Trit::Z; 12];
                    for i in 0..4 {
                        if let Ok(tryte) = cpu.memory.read_tryte(current_pc + i) {
                            if let Tryte::Digit(digit) = tryte {
                                instr_trits[i * 3] =
                                    Trit::from_value((digit as i8 - 13) / 9).unwrap_or(Trit::Z);
                                instr_trits[i * 3 + 1] =
                                    Trit::from_value(((digit as i8 - 13) % 9) / 3)
                                        .unwrap_or(Trit::Z);
                                instr_trits[i * 3 + 2] =
                                    Trit::from_value((digit as i8 - 13) % 3).unwrap_or(Trit::Z);
                            }
                        }
                    }

                    if let Ok(decoded) = decode(instr_trits) {
                        println!("  Instruction décodée: {:?}", decoded);
                    }
                }
            }
            Err(e) => {
                println!("Erreur lors de l'exécution: {:?}", e);
                break;
            }
        }
    }

    // Vérifier les résultats
    println!("\nRésultats des tests:");
    println!(
        "Test BRANCH EQ: {}",
        if cpu.state.read_gpr(Register::R5) == Word::from_int(1)
            && cpu.state.read_gpr(Register::R4) == Word::from_int(0)
        {
            "RÉUSSI"
        } else {
            "ÉCHOUÉ"
        }
    );
    println!(
        "Test BRANCH NE: {}",
        if cpu.state.read_gpr(Register::R7) == Word::from_int(1)
            && cpu.state.read_gpr(Register::R6) == Word::from_int(0)
        {
            "RÉUSSI"
        } else {
            "ÉCHOUÉ"
        }
    );
    println!(
        "Test BRANCH LT: {}",
        if cpu.state.read_gpr(Register::R1) == Word::from_int(200) {
            "RÉUSSI"
        } else {
            "ÉCHOUÉ"
        }
    );
    println!(
        "Test BRANCH GE: {}",
        if cpu.state.read_gpr(Register::R2) == Word::from_int(200) {
            "RÉUSSI"
        } else {
            "ÉCHOUÉ"
        }
    );
    println!(
        "Test BRANCH LTU: {}",
        if cpu.state.read_gpr(Register::R1) == Word::from_int(55) {
            "RÉUSSI"
        } else {
            "ÉCHOUÉ"
        }
    );
    println!(
        "Test BRANCH GEU: {}",
        if cpu.state.read_gpr(Register::R2) == Word::from_int(55) {
            "RÉUSSI"
        } else {
            "ÉCHOUÉ"
        }
    );
    println!(
        "Test BRANCH SPECIAL: {}",
        if cpu.state.read_gpr(Register::R1) == Word::from_int(65) {
            "RÉUSSI"
        } else {
            "ÉCHOUÉ"
        }
    );
    println!(
        "Test BRANCH ALWAYS: {}",
        if cpu.state.read_gpr(Register::R2) == Word::from_int(65) {
            "RÉUSSI"
        } else {
            "ÉCHOUÉ"
        }
    );
    println!(
        "Valeur finale de R3 (adresse de base): {}",
        cpu.state.read_gpr(Register::R3)
    );
}

// Fonction simplifiée pour encoder une instruction en trits
// Note: Cette fonction est une version simplifiée et ne couvre pas tous les cas
fn encode_instruction(instr: &Instruction) -> [Trit; 12] {
    let mut trits = [Trit::Z; 12];

    match instr {
        Instruction::AluReg { op, rs1, rs2, rd } => {
            // Opcode ALU (format R)
            trits[0] = Trit::N;
            trits[1] = Trit::N;
            trits[2] = Trit::N;

            // Fonction ALU
            match op {
                AluOp::Add => {
                    trits[3] = Trit::N;
                    trits[4] = Trit::N;
                    trits[5] = Trit::N;
                }
                AluOp::Sub => {
                    trits[3] = Trit::N;
                    trits[4] = Trit::N;
                    trits[5] = Trit::Z;
                }
                AluOp::TritMin => {
                    trits[3] = Trit::N;
                    trits[4] = Trit::N;
                    trits[5] = Trit::P;
                }
                AluOp::TritMax => {
                    trits[3] = Trit::N;
                    trits[4] = Trit::Z;
                    trits[5] = Trit::N;
                }
                AluOp::Cmp => {
                    trits[3] = Trit::N;
                    trits[4] = Trit::Z;
                    trits[5] = Trit::P;
                }
                AluOp::TritInv => {
                    trits[3] = Trit::N;
                    trits[4] = Trit::Z;
                    trits[5] = Trit::Z;
                }
                _ => { /* Non implémenté */ }
            }

            // Registres
            let rd_idx = rd.to_index() as i8;
            let rs1_idx = rs1.to_index() as i8;
            let rs2_idx = rs2.to_index() as i8;

            // Encoder rd (2 trits)
            trits[6] = match rd_idx & 0b11 {
                0 => Trit::N,
                1 => Trit::Z,
                2 => Trit::P,
                _ => Trit::N,
            };
            trits[7] = if rd_idx & 0b100 != 0 {
                Trit::P
            } else {
                Trit::N
            };

            // Encoder rs1 (2 trits)
            trits[8] = match rs1_idx & 0b11 {
                0 => Trit::N,
                1 => Trit::Z,
                2 => Trit::P,
                _ => Trit::N,
            };
            trits[9] = if rs1_idx & 0b100 != 0 {
                Trit::P
            } else {
                Trit::N
            };

            // Encoder rs2 (2 trits)
            trits[10] = match rs2_idx & 0b11 {
                0 => Trit::N,
                1 => Trit::Z,
                2 => Trit::P,
                _ => Trit::N,
            };
            trits[11] = if rs2_idx & 0b100 != 0 {
                Trit::P
            } else {
                Trit::N
            };
        }
        Instruction::AluImm { op, rs1, rd, imm } => {
            // Opcode ALUI (format I)
            trits[0] = Trit::N;
            trits[1] = Trit::N;
            trits[2] = Trit::Z;

            // Fonction ALU
            match op {
                AluOp::Add => {
                    trits[3] = Trit::N;
                    trits[4] = Trit::N;
                    trits[5] = Trit::N;
                }
                AluOp::Sub => {
                    trits[3] = Trit::N;
                    trits[4] = Trit::N;
                    trits[5] = Trit::Z;
                }
                AluOp::TritMin => {
                    trits[3] = Trit::N;
                    trits[4] = Trit::N;
                    trits[5] = Trit::P;
                }
                AluOp::TritMax => {
                    trits[3] = Trit::N;
                    trits[4] = Trit::Z;
                    trits[5] = Trit::N;
                }
                AluOp::Cmp => {
                    trits[3] = Trit::N;
                    trits[4] = Trit::Z;
                    trits[5] = Trit::P;
                }
                _ => { /* Non implémenté */ }
            }

            // Registres
            let rd_idx = rd.to_index() as i8;
            let rs1_idx = rs1.to_index() as i8;

            // Encoder rd (2 trits)
            trits[6] = match rd_idx & 0b11 {
                0 => Trit::N,
                1 => Trit::Z,
                2 => Trit::P,
                _ => Trit::N,
            };
            trits[7] = if rd_idx & 0b100 != 0 {
                Trit::P
            } else {
                Trit::N
            };

            // Encoder rs1 (2 trits)
            trits[8] = match rs1_idx & 0b11 {
                0 => Trit::N,
                1 => Trit::Z,
                2 => Trit::P,
                _ => Trit::N,
            };
            trits[9] = if rs1_idx & 0b100 != 0 {
                Trit::P
            } else {
                Trit::N
            };

            // Encoder imm (2 trits)
            // Simplification: on ne prend que les 2 bits de poids faible
            let imm_val = *imm as i8;
            trits[10] = match imm_val & 0b11 {
                0 => Trit::N,
                1 => Trit::Z,
                2 => Trit::P,
                _ => Trit::N,
            };
            trits[11] = if imm_val & 0b100 != 0 {
                Trit::P
            } else {
                Trit::N
            };
        }
        Instruction::Branch { rs1, cond, offset } => {
            // Opcode BRANCH (format B)
            trits[0] = Trit::N;
            trits[1] = Trit::Z;
            trits[2] = Trit::N;

            // Condition
            match cond {
                Condition::Eq => {
                    trits[3] = Trit::N;
                    trits[4] = Trit::N;
                    trits[5] = Trit::N;
                }
                Condition::Ne => {
                    trits[3] = Trit::N;
                    trits[4] = Trit::N;
                    trits[5] = Trit::Z;
                }
                Condition::Lt => {
                    trits[3] = Trit::N;
                    trits[4] = Trit::N;
                    trits[5] = Trit::P;
                }
                Condition::Ge => {
                    trits[3] = Trit::N;
                    trits[4] = Trit::Z;
                    trits[5] = Trit::N;
                }
                Condition::Ltu => {
                    trits[3] = Trit::N;
                    trits[4] = Trit::Z;
                    trits[5] = Trit::Z;
                }
                Condition::Geu => {
                    trits[3] = Trit::N;
                    trits[4] = Trit::Z;
                    trits[5] = Trit::P;
                }
                Condition::Special => {
                    trits[3] = Trit::N;
                    trits[4] = Trit::P;
                    trits[5] = Trit::N;
                }
                Condition::Always => {
                    trits[3] = Trit::N;
                    trits[4] = Trit::P;
                    trits[5] = Trit::Z;
                }
            }

            // Registre rs1
            let rs1_idx = rs1.to_index() as i8;
            trits[6] = match rs1_idx & 0b11 {
                0 => Trit::N,
                1 => Trit::Z,
                2 => Trit::P,
                _ => Trit::N,
            };
            trits[7] = if rs1_idx & 0b100 != 0 {
                Trit::P
            } else {
                Trit::N
            };

            // Offset (4 trits)
            // Simplification: on ne prend que les 4 bits de poids faible
            let offset_val = *offset;
            trits[8] = match offset_val & 0b11 {
                0 => Trit::N,
                1 => Trit::Z,
                2 => Trit::P,
                _ => Trit::N,
            };
            trits[9] = if offset_val & 0b100 != 0 {
                Trit::P
            } else {
                Trit::N
            };
            trits[10] = if offset_val & 0b1000 != 0 {
                Trit::P
            } else {
                Trit::N
            };
            trits[11] = if offset_val & 0b10000 != 0 {
                Trit::P
            } else {
                Trit::N
            };
        }
        Instruction::Halt => {
            // Opcode SYSTEM (format I)
            trits[0] = Trit::P;
            trits[1] = Trit::P;
            trits[2] = Trit::P;

            // Fonction HALT
            trits[3] = Trit::Z;
            trits[4] = Trit::Z;
            trits[5] = Trit::Z;
            trits[6] = Trit::Z;
            trits[7] = Trit::Z;
            trits[8] = Trit::Z;
            trits[9] = Trit::Z;
            trits[10] = Trit::Z;
            trits[11] = Trit::Z;
        }
        _ => {
            // Non implémenté
        }
    }

    trits
}
