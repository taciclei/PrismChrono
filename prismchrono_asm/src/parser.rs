//! Module de parser pour l'assembleur PrismChrono
//!
//! Ce module est responsable de l'analyse syntaxique des tokens générés par le lexer
//! et de leur transformation en une structure AST (Abstract Syntax Tree).

use crate::ast::{AstNode, Directive, Instruction, Operand, Program};
use crate::error::AssemblerError;
use crate::lexer::{Token, TokenType};
use crate::core_types::Address;

/// Structure du parser
pub struct Parser {
    /// Tokens à analyser
    tokens: Vec<Token>,
    /// Position courante dans le vecteur de tokens
    current: usize,
}

impl Parser {
    /// Crée un nouveau parser à partir des tokens
    pub fn new(tokens: Vec<Token>) -> Self {
        Parser {
            tokens,
            current: 0,
        }
    }

    /// Analyse les tokens et retourne un programme AST
    pub fn parse(&mut self) -> Result<Program, AssemblerError> {
        let mut program = Program::new();

        while !self.is_at_end() {
            let line_number = self.current_token().line + 1;
            let node = self.parse_line()?;
            program.add_line(line_number, node);
        }

        Ok(program)
    }

    /// Analyse une ligne de code
    fn parse_line(&mut self) -> Result<AstNode, AssemblerError> {
        // Ignorer les commentaires
        while self.check_type(|t| matches!(t, TokenType::Comment(_))) {
            self.advance(); // Consommer le commentaire
        }
        
        // Ignorer les lignes vides
        if self.check(TokenType::EOL) {
            self.advance(); // Consommer EOL
            return Ok(AstNode::Empty);
        }

        // Vérifier s'il y a une définition de label
        if let TokenType::LabelDef(label) = &self.current_token().token_type {
            let label_name = label.clone();
            self.advance(); // Consommer le label

            // Ignorer les commentaires après le label
            while self.check_type(|t| matches!(t, TokenType::Comment(_))) {
                self.advance(); // Consommer le commentaire
            }

            // Si la ligne ne contient que le label, retourner un nœud Label
            if self.check(TokenType::EOL) {
                self.advance(); // Consommer EOL
                return Ok(AstNode::Label(label_name));
            }

            // Sinon, traiter le reste de la ligne et retourner un nœud Label
            let _node = self.parse_line()?;
            return Ok(AstNode::Label(label_name));
        }

        // Vérifier s'il y a une directive
        if let TokenType::Directive(directive) = &self.current_token().token_type {
            let directive_node = self.parse_directive(directive.clone())?;
            
            // Ignorer les commentaires après la directive
            while self.check_type(|t| matches!(t, TokenType::Comment(_))) {
                self.advance(); // Consommer le commentaire
            }
            
            self.consume(TokenType::EOL, "Attendu fin de ligne après directive")?;
            return Ok(AstNode::Directive(directive_node));
        }

        // Vérifier s'il y a une instruction
        if let TokenType::Mnemonic(mnemonic) = &self.current_token().token_type {
            let instruction_node = self.parse_instruction(mnemonic.clone())?;
            
            // Ignorer les commentaires après l'instruction
            while self.check_type(|t| matches!(t, TokenType::Comment(_))) {
                self.advance(); // Consommer le commentaire
            }
            
            self.consume(TokenType::EOL, "Attendu fin de ligne après instruction")?;
            return Ok(AstNode::Instruction(instruction_node));
        }

        // Si on arrive ici, c'est une erreur de syntaxe
        Err(AssemblerError::ParserError {
            line: self.current_token().line + 1,
            message: format!("Syntaxe invalide: {:?}", self.current_token().token_type),
        })
    }

    /// Analyse une directive
    fn parse_directive(&mut self, directive: String) -> Result<Directive, AssemblerError> {
        self.advance(); // Consommer la directive

        match directive.as_str() {
            "org" => {
                // .org <address>
                let address = self.parse_number()?;
                Ok(Directive::Org(address as Address))
            }
            "align" => {
                // .align <alignment>
                let alignment = self.parse_number()?;
                if alignment <= 0 {
                    return Err(AssemblerError::ParserError {
                        line: self.current_token().line + 1,
                        message: format!("Alignement invalide: {}", alignment),
                    });
                }
                Ok(Directive::Align(alignment as u32))
            }
            "tryte" => {
                // .tryte <value>
                let value = self.parse_number()?;
                Ok(Directive::Tryte(value))
            }
            "word" => {
                // .word <value>
                let value = self.parse_number()?;
                Ok(Directive::Word(value))
            }
            _ => Err(AssemblerError::ParserError {
                line: self.current_token().line + 1,
                message: format!("Directive inconnue: .{}", directive),
            }),
        }
    }

    /// Analyse une instruction
    fn parse_instruction(&mut self, mnemonic: String) -> Result<Instruction, AssemblerError> {
        self.advance(); // Consommer le mnémonique

        match mnemonic.as_str() {
            "NOP" => Ok(Instruction::Nop),
            "HALT" => Ok(Instruction::Halt),
            "ADDI" => {
                // ADDI rd, rs1, imm
                let rd = self.parse_register()?;
                self.consume(TokenType::Comma, "Attendu ',' après rd")?;
                let rs1 = self.parse_register()?;
                self.consume(TokenType::Comma, "Attendu ',' après rs1")?;
                let imm = self.parse_number()?;
                Ok(Instruction::Addi { rd, rs1, imm })
            }
            "LUI" => {
                // LUI rd, imm
                let rd = self.parse_register()?;
                self.consume(TokenType::Comma, "Attendu ',' après rd")?;
                let imm = self.parse_number()?;
                Ok(Instruction::Lui { rd, imm })
            }
            "JAL" => {
                // JAL rd, label
                let rd = self.parse_register()?;
                self.consume(TokenType::Comma, "Attendu ',' après rd")?;
                let label = self.parse_label()?;
                Ok(Instruction::Jal { rd, label })
            }
            "STOREW" => {
                // STOREW rs1, rs2, imm (Format S)
                let rs1 = self.parse_register()?;
                self.consume(TokenType::Comma, "Attendu ',' après rs1")?;
                let rs2 = self.parse_register()?;
                self.consume(TokenType::Comma, "Attendu ',' après rs2")?;
                let imm = self.parse_number()?;
                Ok(Instruction::Storew { rs1, rs2, imm })
            }
            "STORET" => {
                // STORET rs1, rs2, imm (Format S)
                let rs1 = self.parse_register()?;
                self.consume(TokenType::Comma, "Attendu ',' après rs1")?;
                let rs2 = self.parse_register()?;
                self.consume(TokenType::Comma, "Attendu ',' après rs2")?;
                let imm = self.parse_number()?;
                Ok(Instruction::Storet { rs1, rs2, imm })
            }
            "BRANCH" => {
                // BRANCH rs1, rs2, condition, label (Format B)
                let rs1 = self.parse_register()?;
                self.consume(TokenType::Comma, "Attendu ',' après rs1")?;
                let rs2 = self.parse_register()?;
                self.consume(TokenType::Comma, "Attendu ',' après rs2")?;
                
                // Lire la condition (EQ, NE, LT, GE, etc.)
                if let TokenType::LabelRef(condition) = &self.current_token().token_type {
                    let condition_str = condition.clone();
                    self.advance(); // Consommer la condition
                    
                    // Vérifier que la condition est valide
                    match condition_str.to_uppercase().as_str() {
                        "EQ" | "NE" | "LT" | "LE" | "GT" | "GE" => {
                            self.consume(TokenType::Comma, "Attendu ',' après condition")?;
                            let label = self.parse_label()?;
                            Ok(Instruction::Branch {
                                rs1,
                                rs2,
                                condition: condition_str.to_uppercase(),
                                label,
                            })
                        },
                        _ => Err(AssemblerError::ParserError {
                            line: self.current_token().line + 1,
                            message: format!("Condition de branchement invalide: {}", condition_str),
                        }),
                    }
                } else {
                    Err(AssemblerError::ParserError {
                        line: self.current_token().line + 1,
                        message: "Attendu une condition de branchement".to_string(),
                    })
                }
            }
            "ADD" => {
                // ADD rd, rs1, rs2 (Format R)
                let rd = self.parse_register()?;
                self.consume(TokenType::Comma, "Attendu ',' après rd")?;
                let rs1 = self.parse_register()?;
                self.consume(TokenType::Comma, "Attendu ',' après rs1")?;
                let rs2 = self.parse_register()?;
                Ok(Instruction::Add { rd, rs1, rs2 })
            }
            "SUB" => {
                // SUB rd, rs1, rs2 (Format R)
                let rd = self.parse_register()?;
                self.consume(TokenType::Comma, "Attendu ',' après rd")?;
                let rs1 = self.parse_register()?;
                self.consume(TokenType::Comma, "Attendu ',' après rs1")?;
                let rs2 = self.parse_register()?;
                Ok(Instruction::Sub { rd, rs1, rs2 })
            }
            "ECALL" => {
                // ECALL (Format System)
                Ok(Instruction::Ecall)
            }
            "EBREAK" => {
                // EBREAK (Format System)
                Ok(Instruction::Ebreak)
            }
            "MRET_T" => {
                // MRET_T (Format System)
                Ok(Instruction::Mret)
            }
            "CSRRW_T" => {
                // CSRRW_T rd, csr_code, rs1 (Format CSR)
                let rd = self.parse_register()?;
                self.consume(TokenType::Comma, "Attendu ',' après rd")?;
                let csr_code = self.parse_label()?;
                self.consume(TokenType::Comma, "Attendu ',' après csr_code")?;
                let rs1 = self.parse_register()?;
                Ok(Instruction::Csrrw { rd, csr_code, rs1 })
            }
            "CSRRS_T" => {
                // CSRRS_T rd, csr_code, rs1 (Format CSR)
                let rd = self.parse_register()?;
                self.consume(TokenType::Comma, "Attendu ',' après rd")?;
                let csr_code = self.parse_label()?;
                self.consume(TokenType::Comma, "Attendu ',' après csr_code")?;
                let rs1 = self.parse_register()?;
                Ok(Instruction::Csrrs { rd, csr_code, rs1 })
            }
            _ => Err(AssemblerError::ParserError {
                line: self.current_token().line + 1,
                message: format!("Instruction inconnue: {}", mnemonic),
            }),
        }
    }

    /// Parse un registre
    fn parse_register(&mut self) -> Result<u8, AssemblerError> {
        if let TokenType::Register(reg) = self.current_token().token_type {
            self.advance(); // Consommer le registre
            Ok(reg)
        } else {
            Err(AssemblerError::ParserError {
                line: self.current_token().line + 1,
                message: format!("Attendu un registre, trouvé: {:?}", self.current_token().token_type),
            })
        }
    }

    /// Parse un nombre
    fn parse_number(&mut self) -> Result<i32, AssemblerError> {
        if let TokenType::Number(num) = self.current_token().token_type {
            self.advance(); // Consommer le nombre
            Ok(num)
        } else {
            Err(AssemblerError::ParserError {
                line: self.current_token().line + 1,
                message: format!("Attendu un nombre, trouvé: {:?}", self.current_token().token_type),
            })
        }
    }

    /// Parse un label
    fn parse_label(&mut self) -> Result<String, AssemblerError> {
        if let TokenType::LabelRef(label) = &self.current_token().token_type {
            let label_name = label.clone();
            self.advance(); // Consommer le label
            Ok(label_name)
        } else {
            Err(AssemblerError::ParserError {
                line: self.current_token().line + 1,
                message: format!("Attendu un label, trouvé: {:?}", self.current_token().token_type),
            })
        }
    }

    /// Vérifie si le token courant est du type spécifié
    fn check(&self, token_type: TokenType) -> bool {
        if self.is_at_end() {
            return false;
        }
        match (&self.current_token().token_type, &token_type) {
            (TokenType::EOL, TokenType::EOL) => true,
            (TokenType::EOF, TokenType::EOF) => true,
            (TokenType::Comma, TokenType::Comma) => true,
            _ => false,
        }
    }

    /// Vérifie si le token courant correspond à un prédicat donné
    fn check_type<F>(&self, predicate: F) -> bool
    where
        F: Fn(&TokenType) -> bool,
    {
        if self.is_at_end() {
            return false;
        }
        predicate(&self.current_token().token_type)
    }

    /// Consomme le token courant s'il est du type spécifié, sinon génère une erreur
    fn consume(&mut self, token_type: TokenType, message: &str) -> Result<(), AssemblerError> {
        if self.check(token_type) {
            self.advance();
            Ok(())
        } else {
            Err(AssemblerError::ParserError {
                line: self.current_token().line + 1,
                message: message.to_string(),
            })
        }
    }

    /// Avance au token suivant
    fn advance(&mut self) -> Token {
        if !self.is_at_end() {
            self.current += 1;
        }
        self.previous_token()
    }

    /// Retourne le token courant
    fn current_token(&self) -> Token {
        self.tokens[self.current].clone()
    }

    /// Retourne le token précédent
    fn previous_token(&self) -> Token {
        self.tokens[self.current - 1].clone()
    }

    /// Vérifie si on est à la fin des tokens
    fn is_at_end(&self) -> bool {
        matches!(self.current_token().token_type, TokenType::EOF)
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::lexer::Lexer;

    #[test]
    fn test_parse_nop() {
        let source = "NOP";
        let mut lexer = Lexer::new(source);
        let tokens = lexer.tokenize().unwrap();
        let mut parser = Parser::new(tokens);
        let program = parser.parse().unwrap();

        assert_eq!(program.lines.len(), 1);
        assert!(matches!(program.lines[0].node, AstNode::Instruction(Instruction::Nop)));
    }

    #[test]
    fn test_parse_addi() {
        let source = "ADDI R1, R2, 10";
        let mut lexer = Lexer::new(source);
        let tokens = lexer.tokenize().unwrap();
        let mut parser = Parser::new(tokens);
        let program = parser.parse().unwrap();

        assert_eq!(program.lines.len(), 1);
        if let AstNode::Instruction(Instruction::Addi { rd, rs1, imm }) = &program.lines[0].node {
            assert_eq!(*rd, 1);
            assert_eq!(*rs1, 2);
            assert_eq!(*imm, 10);
        } else {
            panic!("Expected ADDI instruction");
        }
    }

    #[test]
    fn test_parse_label() {
        let source = "start: NOP";
        let mut lexer = Lexer::new(source);
        let tokens = lexer.tokenize().unwrap();
        let mut parser = Parser::new(tokens);
        let program = parser.parse().unwrap();

        assert_eq!(program.lines.len(), 1);
        if let AstNode::Label(label) = &program.lines[0].node {
            assert_eq!(label, "start");
        } else {
            panic!("Expected label");
        }
    }

    #[test]
    fn test_parse_directive() {
        let source = ".org 0x100";
        let mut lexer = Lexer::new(source);
        let tokens = lexer.tokenize().unwrap();
        let mut parser = Parser::new(tokens);
        let program = parser.parse().unwrap();

        assert_eq!(program.lines.len(), 1);
        if let AstNode::Directive(Directive::Org(addr)) = &program.lines[0].node {
            assert_eq!(*addr, 0x100);
        } else {
            panic!("Expected .org directive");
        }
    }

    #[test]
    fn test_parse_storew() {
        let source = "STOREW R1, R2, 10";
        let mut lexer = Lexer::new(source);
        let tokens = lexer.tokenize().unwrap();
        let mut parser = Parser::new(tokens);
        let program = parser.parse().unwrap();

        assert_eq!(program.lines.len(), 1);
        if let AstNode::Instruction(Instruction::Storew { rs1, rs2, imm }) = &program.lines[0].node {
            assert_eq!(*rs1, 1);
            assert_eq!(*rs2, 2);
            assert_eq!(*imm, 10);
        } else {
            panic!("Expected STOREW instruction");
        }
    }

    #[test]
    fn test_parse_storet() {
        let source = "STORET R3, R4, -5";
        let mut lexer = Lexer::new(source);
        let tokens = lexer.tokenize().unwrap();
        let mut parser = Parser::new(tokens);
        let program = parser.parse().unwrap();

        assert_eq!(program.lines.len(), 1);
        if let AstNode::Instruction(Instruction::Storet { rs1, rs2, imm }) = &program.lines[0].node {
            assert_eq!(*rs1, 3);
            assert_eq!(*rs2, 4);
            assert_eq!(*imm, -5);
        } else {
            panic!("Expected STORET instruction");
        }
    }

    #[test]
    fn test_parse_branch() {
        let source = "BRANCH R1, R2, EQ, loop";
        let mut lexer = Lexer::new(source);
        let tokens = lexer.tokenize().unwrap();
        let mut parser = Parser::new(tokens);
        let program = parser.parse().unwrap();

        assert_eq!(program.lines.len(), 1);
        if let AstNode::Instruction(Instruction::Branch { rs1, rs2, condition, label }) = &program.lines[0].node {
            assert_eq!(*rs1, 1);
            assert_eq!(*rs2, 2);
            assert_eq!(condition, "EQ");
            assert_eq!(label, "loop");
        } else {
            panic!("Expected BRANCH instruction");
        }
    }

    #[test]
    fn test_parse_add() {
        let source = "ADD R1, R2, R3";
        let mut lexer = Lexer::new(source);
        let tokens = lexer.tokenize().unwrap();
        let mut parser = Parser::new(tokens);
        let program = parser.parse().unwrap();

        assert_eq!(program.lines.len(), 1);
        if let AstNode::Instruction(Instruction::Add { rd, rs1, rs2 }) = &program.lines[0].node {
            assert_eq!(*rd, 1);
            assert_eq!(*rs1, 2);
            assert_eq!(*rs2, 3);
        } else {
            panic!("Expected ADD instruction");
        }
    }

    #[test]
    fn test_parse_sub() {
        let source = "SUB R5, R6, R7";
        let mut lexer = Lexer::new(source);
        let tokens = lexer.tokenize().unwrap();
        let mut parser = Parser::new(tokens);
        let program = parser.parse().unwrap();

        assert_eq!(program.lines.len(), 1);
        if let AstNode::Instruction(Instruction::Sub { rd, rs1, rs2 }) = &program.lines[0].node {
            assert_eq!(*rd, 5);
            assert_eq!(*rs1, 6);
            assert_eq!(*rs2, 7);
        } else {
            panic!("Expected SUB instruction");
        }
    }
}