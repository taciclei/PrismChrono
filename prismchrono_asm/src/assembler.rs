//! Module d'assemblage pour l'assembleur PrismChrono
//!
//! Ce module implémente le processus d'assemblage en deux passes :
//! - Passe 1 : Calcul des adresses et construction de la table des symboles
//! - Passe 2 : Résolution des références et encodage des instructions

use crate::ast::{AstNode, Directive, Instruction, Program, SourceLine};
use crate::core_types::Address;
use crate::encoder::{self, EncodedData, encode_nop, encode_halt, encode_addi, encode_lui, encode_jal, encode_tryte, encode_word, encode_storew, encode_storet, encode_branch, encode_add, encode_sub, encode_ecall, encode_ebreak, encode_mret, encode_csrrw, encode_csrrs};
use crate::error::AssemblerError;
use crate::isa_defs::{INSTRUCTION_SIZE_BYTES, cond};
use crate::operand::calculate_jal_offset;
use crate::symbol::SymbolTable;

/// Structure représentant le résultat de l'assemblage
pub struct AssemblyResult {
    /// Données encodées avec leurs adresses
    pub encoded_data: Vec<(Address, EncodedData)>,
    /// Table des symboles
    pub symbol_table: SymbolTable,
}

/// Structure de l'assembleur
pub struct Assembler {
    /// Programme à assembler
    program: Program,
}

impl Assembler {
    /// Crée un nouvel assembleur à partir d'un programme
    pub fn new(program: Program) -> Self {
        Assembler { program }
    }

    /// Exécute le processus d'assemblage en deux passes
    pub fn assemble(&self) -> Result<AssemblyResult, AssemblerError> {
        // Passe 1 : Calcul des adresses et construction de la table des symboles
        let symbol_table = self.run_pass1()?;

        // Passe 2 : Résolution des références et encodage des instructions
        let encoded_data = self.run_pass2(&symbol_table)?;

        Ok(AssemblyResult {
            encoded_data,
            symbol_table,
        })
    }

    /// Exécute la première passe de l'assemblage
    fn run_pass1(&self) -> Result<SymbolTable, AssemblerError> {
        let mut symbol_table = SymbolTable::new();
        let mut current_address: Address = 0;

        for line in &self.program.lines {
            match &line.node {
                AstNode::Label(label) => {
                    // Définir le label avec l'adresse courante
                    symbol_table.define(label, current_address).map_err(|e| {
                        AssemblerError::Pass1Error(format!(
                            "Ligne {}: {}",
                            line.line_number, e
                        ))
                    })?;
                }
                AstNode::Directive(directive) => {
                    // Traiter les directives qui affectent l'adresse
                    match directive {
                        Directive::Org(address) => {
                            current_address = *address;
                        }
                        Directive::Align(alignment) => {
                            // Aligner l'adresse courante
                            let align = *alignment as Address;
                            if align > 0 {
                                current_address = (current_address + align - 1) / align * align;
                            }
                        }
                        Directive::Tryte(_) => {
                            // Un tryte occupe 1 octet
                            current_address += 1;
                        }
                        Directive::Word(_) => {
                            // Un mot occupe 8 trytes = 8 octets
                            current_address += 8;
                        }
                    }
                }
                AstNode::Instruction(_) => {
                    // Chaque instruction occupe INSTRUCTION_SIZE_BYTES octets
                    current_address += INSTRUCTION_SIZE_BYTES;
                }
                AstNode::Empty => {
                    // Les lignes vides n'affectent pas l'adresse
                }
            }
        }

        Ok(symbol_table)
    }

    /// Exécute la deuxième passe de l'assemblage
    fn run_pass2(&self, symbol_table: &SymbolTable) -> Result<Vec<(Address, EncodedData)>, AssemblerError> {
        let mut encoded_data = Vec::new();
        let mut current_address: Address = 0;

        for line in &self.program.lines {
            match &line.node {
                AstNode::Instruction(instruction) => {
                    // Encoder l'instruction
                    let encoded = self.encode_instruction(instruction, current_address, symbol_table, line.line_number)?;
                    encoded_data.push((current_address, encoded));
                    current_address += INSTRUCTION_SIZE_BYTES;
                }
                AstNode::Directive(directive) => {
                    // Traiter les directives
                    match directive {
                        Directive::Org(address) => {
                            current_address = *address;
                        }
                        Directive::Align(alignment) => {
                            // Aligner l'adresse courante
                            let align = *alignment as Address;
                            if align > 0 {
                                current_address = (current_address + align - 1) / align * align;
                            }
                        }
                        Directive::Tryte(value) => {
                            // Encoder un tryte
                            let trytes = encode_tryte(*value).map_err(|e| {
                                AssemblerError::Pass2Error(format!(
                                    "Ligne {}: {}",
                                    line.line_number, e
                                ))
                            })?;
                            encoded_data.push((current_address, EncodedData::Data(trytes)));
                            current_address += 1;
                        }
                        Directive::Word(value) => {
                            // Encoder un mot
                            let trytes = encode_word(*value).map_err(|e| {
                                AssemblerError::Pass2Error(format!(
                                    "Ligne {}: {}",
                                    line.line_number, e
                                ))
                            })?;
                            encoded_data.push((current_address, EncodedData::Data(trytes)));
                            current_address += 8;
                        }
                    }
                }
                AstNode::Label(_) | AstNode::Empty => {
                    // Les labels et les lignes vides ont déjà été traités dans la passe 1
                }
            }
        }

        Ok(encoded_data)
    }

    /// Encode une instruction
    fn encode_instruction(
        &self,
        instruction: &Instruction,
        current_address: Address,
        symbol_table: &SymbolTable,
        line_number: usize,
    ) -> Result<EncodedData, AssemblerError> {
        match instruction {
            Instruction::Nop => {
                let trits = encode_nop().map_err(|e| {
                    AssemblerError::Pass2Error(format!("Ligne {}: {}", line_number, e))
                })?;
                Ok(EncodedData::Instruction(trits))
            }
            Instruction::Halt => {
                let trits = encode_halt().map_err(|e| {
                    AssemblerError::Pass2Error(format!("Ligne {}: {}", line_number, e))
                })?;
                Ok(EncodedData::Instruction(trits))
            }
            Instruction::Addi { rd, rs1, imm } => {
                let trits = encode_addi(*rd, *rs1, *imm, line_number).map_err(|e| {
                    AssemblerError::Pass2Error(format!("Ligne {}: {}", line_number, e))
                })?;
                Ok(EncodedData::Instruction(trits))
            }
            Instruction::Lui { rd, imm } => {
                let trits = encode_lui(*rd, *imm, line_number).map_err(|e| {
                    AssemblerError::Pass2Error(format!("Ligne {}: {}", line_number, e))
                })?;
                Ok(EncodedData::Instruction(trits))
            }
            Instruction::Jal { rd, label } => {
                // Résoudre l'adresse du label
                let target_address = symbol_table.resolve(label).map_err(|e| {
                    AssemblerError::Pass2Error(format!("Ligne {}: {}", line_number, e))
                })?;

                // Calculer l'offset pour JAL
                let offset = calculate_jal_offset(target_address, current_address).map_err(|e| {
                    AssemblerError::Pass2Error(format!("Ligne {}: {}", line_number, e))
                })?;

                // Encoder l'instruction JAL
                let trits = encode_jal(*rd, offset, line_number).map_err(|e| {
                    AssemblerError::Pass2Error(format!("Ligne {}: {}", line_number, e))
                })?;

                Ok(EncodedData::Instruction(trits))
            }
            Instruction::Storew { rs1, rs2, imm } => {
                let trits = encode_storew(*rs1, *rs2, *imm, line_number).map_err(|e| {
                    AssemblerError::Pass2Error(format!("Ligne {}: {}", line_number, e))
                })?;
                Ok(EncodedData::Instruction(trits))
            }
            Instruction::Storet { rs1, rs2, imm } => {
                let trits = encode_storet(*rs1, *rs2, *imm, line_number).map_err(|e| {
                    AssemblerError::Pass2Error(format!("Ligne {}: {}", line_number, e))
                })?;
                Ok(EncodedData::Instruction(trits))
            }
            Instruction::Branch { rs1, rs2, condition, label } => {
                // Résoudre l'adresse du label
                let target_address = symbol_table.resolve(label).map_err(|e| {
                    AssemblerError::Pass2Error(format!("Ligne {}: {}", line_number, e))
                })?;

                // Calculer l'offset pour BRANCH (similaire à JAL mais avec des limites différentes)
                let pc_after_branch = current_address + 4;
                let diff = target_address as i64 - pc_after_branch as i64;
                
                // Vérifier si la différence est un multiple de 4 (alignement des instructions)
                if diff % 4 != 0 {
                    return Err(AssemblerError::Pass2Error(format!(
                        "Ligne {}: L'adresse cible n'est pas alignée sur 4 octets: 0x{:X}",
                        line_number, target_address
                    )));
                }
                
                // Convertir en nombre d'instructions (diviser par 4)
                let offset = (diff / 4) as i32;
                
                // Déterminer la condition de branchement
                let condition_trits = match condition.as_str() {
                    "eq" => cond::EQ,
                    "ne" => cond::NE,
                    "lt" => cond::LT,
                    "ge" => cond::GE,
                    "gt" => cond::GT,
                    "le" => cond::LE,
                    _ => return Err(AssemblerError::Pass2Error(format!(
                        "Ligne {}: Condition de branchement invalide: {}",
                        line_number, condition
                    ))),
                };

                // Encoder l'instruction BRANCH
                let trits = encode_branch(*rs1, *rs2, condition_trits, offset, line_number).map_err(|e| {
                    AssemblerError::Pass2Error(format!("Ligne {}: {}", line_number, e))
                })?;

                Ok(EncodedData::Instruction(trits))
            }
            Instruction::Add { rd, rs1, rs2 } => {
                let trits = encode_add(*rd, *rs1, *rs2, line_number).map_err(|e| {
                    AssemblerError::Pass2Error(format!("Ligne {}: {}", line_number, e))
                })?;
                Ok(EncodedData::Instruction(trits))
            }
            Instruction::Sub { rd, rs1, rs2 } => {
                let trits = encode_sub(*rd, *rs1, *rs2, line_number).map_err(|e| {
                    AssemblerError::Pass2Error(format!("Ligne {}: {}", line_number, e))
                })?;
                Ok(EncodedData::Instruction(trits))
            }
            Instruction::Ecall => {
                let trits = encode_ecall(line_number).map_err(|e| {
                    AssemblerError::Pass2Error(format!("Ligne {}: {}", line_number, e))
                })?;
                Ok(EncodedData::Instruction(trits))
            }
            Instruction::Ebreak => {
                let trits = encode_ebreak(line_number).map_err(|e| {
                    AssemblerError::Pass2Error(format!("Ligne {}: {}", line_number, e))
                })?;
                Ok(EncodedData::Instruction(trits))
            }
            Instruction::Mret => {
                let trits = encode_mret(line_number).map_err(|e| {
                    AssemblerError::Pass2Error(format!("Ligne {}: {}", line_number, e))
                })?;
                Ok(EncodedData::Instruction(trits))
            }
            Instruction::Csrrw { rd, csr_code, rs1 } => {
                let trits = encode_csrrw(*rd, &csr_code, *rs1, line_number).map_err(|e| {
                    AssemblerError::Pass2Error(format!("Ligne {}: {}", line_number, e))
                })?;
                Ok(EncodedData::Instruction(trits))
            }
            Instruction::Csrrs { rd, csr_code, rs1 } => {
                let trits = encode_csrrs(*rd, &csr_code, *rs1, line_number).map_err(|e| {
                    AssemblerError::Pass2Error(format!("Ligne {}: {}", line_number, e))
                })?;
                Ok(EncodedData::Instruction(trits))
            }
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::ast::{AstNode, Directive, Instruction, Program, SourceLine};
    use crate::core_types::Address;

    #[test]
    fn test_pass1_simple() {
        // Créer un programme simple
        let mut program = Program::new();
        program.add_line(1, AstNode::Label("start".to_string()));
        program.add_line(2, AstNode::Instruction(Instruction::Nop));
        program.add_line(3, AstNode::Label("loop".to_string()));
        program.add_line(4, AstNode::Instruction(Instruction::Halt));

        // Exécuter la passe 1
        let assembler = Assembler::new(program);
        let symbol_table = assembler.run_pass1().unwrap();

        // Vérifier que les labels ont été définis avec les bonnes adresses
        assert_eq!(symbol_table.resolve("start").unwrap(), 0);
        assert_eq!(symbol_table.resolve("loop").unwrap(), 4); // Après NOP (4 octets)
    }

    #[test]
    fn test_pass1_with_directives() {
        // Créer un programme avec des directives
        let mut program = Program::new();
        program.add_line(1, AstNode::Directive(Directive::Org(0x100)));
        program.add_line(2, AstNode::Label("start".to_string()));
        program.add_line(3, AstNode::Instruction(Instruction::Nop));
        program.add_line(4, AstNode::Directive(Directive::Align(8)));
        program.add_line(5, AstNode::Label("aligned".to_string()));

        // Exécuter la passe 1
        let assembler = Assembler::new(program);
        let symbol_table = assembler.run_pass1().unwrap();

        // Vérifier que les labels ont été définis avec les bonnes adresses
        assert_eq!(symbol_table.resolve("start").unwrap(), 0x100);
        assert_eq!(symbol_table.resolve("aligned").unwrap(), 0x108); // Aligné sur 8 octets
    }

    #[test]
    fn test_pass2_simple() {
        // Créer un programme simple
        let mut program = Program::new();
        program.add_line(1, AstNode::Label("start".to_string()));
        program.add_line(2, AstNode::Instruction(Instruction::Nop));
        program.add_line(3, AstNode::Instruction(Instruction::Halt));

        // Exécuter l'assemblage
        let assembler = Assembler::new(program);
        let result = assembler.assemble().unwrap();

        // Vérifier que les instructions ont été encodées
        assert_eq!(result.encoded_data.len(), 2);
        assert_eq!(result.encoded_data[0].0, 0); // Adresse de NOP
        assert_eq!(result.encoded_data[1].0, 4); // Adresse de HALT
    }
}