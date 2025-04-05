//! Module de lexer pour l'assembleur PrismChrono
//!
//! Ce module est responsable de la tokenisation du code source assembleur
//! en une séquence de tokens qui seront ensuite analysés par le parser.

use crate::error::{AssemblerError, LexerError};

/// Types de tokens reconnus par le lexer
#[derive(Debug, Clone, PartialEq)]
pub enum TokenType {
    /// Mnémonique d'instruction (ex: NOP, HALT, ADDI)
    Mnemonic(String),
    /// Registre (ex: R0, R1, R2)
    Register(u8),
    /// Nombre (décimal ou ternaire)
    Number(i32),
    /// Définition de label (ex: "label:")
    LabelDef(String),
    /// Référence à un label (ex: "label" dans "JAL label")
    LabelRef(String),
    /// Directive (ex: .org, .tryte, .word, .align)
    Directive(String),
    /// Virgule séparant les opérandes
    Comma,
    /// Commentaire (ex: # Ceci est un commentaire)
    Comment(String),
    /// Fin de ligne
    EOL,
    /// Fin de fichier
    EOF,
}

/// Structure représentant un token avec sa position dans le code source
#[derive(Debug, Clone)]
pub struct Token {
    /// Type du token
    pub token_type: TokenType,
    /// Numéro de ligne dans le fichier source
    pub line: usize,
    /// Position dans la ligne
    pub column: usize,
}

/// Structure du lexer
pub struct Lexer {
    /// Lignes du code source
    lines: Vec<String>,
    /// Ligne courante
    current_line: usize,
    /// Position dans la ligne courante
    current_column: usize,
    /// Tokens générés
    tokens: Vec<Token>,
}

impl Lexer {
    /// Crée un nouveau lexer à partir du code source
    pub fn new(source: &str) -> Self {
        let lines: Vec<String> = source.lines().map(|s| s.to_string()).collect();
        Lexer {
            lines,
            current_line: 0,
            current_column: 0,
            tokens: Vec::new(),
        }
    }

    /// Tokenise le code source et retourne les tokens
    pub fn tokenize(&mut self) -> Result<Vec<Token>, AssemblerError> {
        while self.current_line < self.lines.len() {
            self.tokenize_line()?;
            self.current_line += 1;
            self.current_column = 0;
        }

        // Ajouter un token EOF à la fin
        self.tokens.push(Token {
            token_type: TokenType::EOF,
            line: self.current_line,
            column: 0,
        });

        Ok(self.tokens.clone())
    }

    /// Tokenise une ligne du code source
    fn tokenize_line(&mut self) -> Result<(), AssemblerError> {
        let line = &self.lines[self.current_line];
        let mut chars = line.chars().peekable();

        while let Some(&c) = chars.peek() {
            match c {
                // Ignorer les espaces
                ' ' | '\t' => {
                    chars.next();
                    self.current_column += 1;
                }

                // Commentaire
                '#' => {
                    chars.next(); // Consommer le '#'
                    let comment: String = chars.collect();
                    self.tokens.push(Token {
                        token_type: TokenType::Comment(comment.trim().to_string()),
                        line: self.current_line,
                        column: self.current_column,
                    });
                    self.current_column = line.len();
                    break;
                }

                // Virgule
                ',' => {
                    chars.next();
                    self.tokens.push(Token {
                        token_type: TokenType::Comma,
                        line: self.current_line,
                        column: self.current_column,
                    });
                    self.current_column += 1;
                }

                // Directive
                '.' => {
                    let start_column = self.current_column;
                    chars.next(); // Consommer le '.'
                    let directive = self.read_identifier(&mut chars);
                    self.tokens.push(Token {
                        token_type: TokenType::Directive(directive),
                        line: self.current_line,
                        column: start_column,
                    });
                }

                // Nombre
                '0'..='9' | '-' | '+' => {
                    let start_column = self.current_column;
                    let number = self.read_number(&mut chars)?;
                    self.tokens.push(Token {
                        token_type: TokenType::Number(number),
                        line: self.current_line,
                        column: start_column,
                    });
                }

                // Identifiant (mnémonique, registre ou label)
                'a'..='z' | 'A'..='Z' | '_' => {
                    let start_column = self.current_column;
                    let identifier = self.read_identifier(&mut chars);

                    // Vérifier si c'est une définition de label (se termine par ':')
                    if chars.peek() == Some(&':') {
                        chars.next(); // Consommer le ':'
                        self.tokens.push(Token {
                            token_type: TokenType::LabelDef(identifier),
                            line: self.current_line,
                            column: start_column,
                        });
                        self.current_column += 1;
                    } else if identifier.starts_with('R') && identifier.len() > 1 {
                        // Registre (ex: R0, R1, ...)
                        if let Ok(reg_num) = identifier[1..].parse::<u8>() {
                            if reg_num <= 7 { // PrismChrono a 8 registres (R0-R7)
                                self.tokens.push(Token {
                                    token_type: TokenType::Register(reg_num),
                                    line: self.current_line,
                                    column: start_column,
                                });
                            } else {
                                return Err(AssemblerError::LexerError {
                                    line: self.current_line + 1,
                                    message: format!("Registre invalide: R{}", reg_num),
                                });
                            }
                        } else {
                            // Considérer comme un label si ce n'est pas un registre valide
                            self.tokens.push(Token {
                                token_type: TokenType::LabelRef(identifier),
                                line: self.current_line,
                                column: start_column,
                            });
                        }
                    } else {
                        // Vérifier si c'est un mnémonique ou une référence à un label
                        let upper_id = identifier.to_uppercase();
                        match upper_id.as_str() {
                            "NOP" | "HALT" | "ADDI" | "LUI" | "JAL" | "STOREW" | "STORET" | "BRANCH" | "ADD" | "SUB" | 
                            "ECALL" | "EBREAK" | "MRET_T" | "CSRRW_T" | "CSRRS_T" => {
                                self.tokens.push(Token {
                                    token_type: TokenType::Mnemonic(upper_id),
                                    line: self.current_line,
                                    column: start_column,
                                });
                            }
                            _ => {
                                // Si ce n'est pas un mnémonique reconnu, c'est une référence à un label
                                self.tokens.push(Token {
                                    token_type: TokenType::LabelRef(identifier),
                                    line: self.current_line,
                                    column: start_column,
                                });
                            }
                        }
                    }
                }

                // Caractère non reconnu
                _ => {
                    return Err(AssemblerError::LexerError {
                        line: self.current_line + 1,
                        message: format!("Caractère non reconnu: {}", c),
                    });
                }
            }
        }

        // Ajouter un token EOL à la fin de chaque ligne
        self.tokens.push(Token {
            token_type: TokenType::EOL,
            line: self.current_line,
            column: line.len(),
        });

        Ok(())
    }

    /// Lit un identifiant (mnémonique, registre ou label)
    fn read_identifier<I>(&mut self, chars: &mut std::iter::Peekable<I>) -> String
    where
        I: Iterator<Item = char>,
    {
        let mut identifier = String::new();
        while let Some(&c) = chars.peek() {
            if c.is_alphanumeric() || c == '_' {
                identifier.push(c);
                chars.next();
                self.current_column += 1;
            } else {
                break;
            }
        }
        identifier
    }

    /// Lit un nombre (décimal ou ternaire)
    fn read_number<I>(&mut self, chars: &mut std::iter::Peekable<I>) -> Result<i32, AssemblerError>
    where
        I: Iterator<Item = char>,
    {
        let mut number_str = String::new();
        let mut is_hex = false;

        // Gérer le signe
        if let Some(&c) = chars.peek() {
            if c == '-' || c == '+' {
                number_str.push(c);
                chars.next();
                self.current_column += 1;
            }
        }

        // Vérifier si c'est un nombre hexadécimal
        if chars.peek() == Some(&'0') {
            number_str.push('0');
            chars.next();
            self.current_column += 1;

            if chars.peek() == Some(&'x') || chars.peek() == Some(&'X') {
                number_str.push('x');
                chars.next();
                self.current_column += 1;
                is_hex = true;
            }
        }

        // Lire les chiffres
        while let Some(&c) = chars.peek() {
            if (is_hex && c.is_digit(16)) || (!is_hex && c.is_digit(10)) {
                number_str.push(c);
                chars.next();
                self.current_column += 1;
            } else {
                break;
            }
        }

        // Convertir la chaîne en nombre
        if is_hex {
            i32::from_str_radix(&number_str[2..], 16).map_err(|_| {
                AssemblerError::LexerError {
                    line: self.current_line + 1,
                    message: format!("Nombre hexadécimal invalide: {}", number_str),
                }
            })
        } else {
            number_str.parse::<i32>().map_err(|_| {
                AssemblerError::LexerError {
                    line: self.current_line + 1,
                    message: format!("Nombre décimal invalide: {}", number_str),
                }
            })
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_tokenize_simple_instruction() {
        let source = "NOP";
        let mut lexer = Lexer::new(source);
        let tokens = lexer.tokenize().unwrap();

        assert_eq!(tokens.len(), 3); // NOP, EOL, EOF
        assert_eq!(tokens[0].token_type, TokenType::Mnemonic("NOP".to_string()));
        assert_eq!(tokens[1].token_type, TokenType::EOL);
        assert_eq!(tokens[2].token_type, TokenType::EOF);
    }

    #[test]
    fn test_tokenize_instruction_with_operands() {
        let source = "ADDI R1, R2, 10";
        let mut lexer = Lexer::new(source);
        let tokens = lexer.tokenize().unwrap();

        assert_eq!(tokens.len(), 8); // ADDI, R1, comma, R2, comma, 10, EOL, EOF
        assert_eq!(tokens[0].token_type, TokenType::Mnemonic("ADDI".to_string()));
        assert_eq!(tokens[1].token_type, TokenType::Register(1));
        assert_eq!(tokens[2].token_type, TokenType::Comma);
        assert_eq!(tokens[3].token_type, TokenType::Register(2));
        assert_eq!(tokens[4].token_type, TokenType::Comma);
        assert_eq!(tokens[5].token_type, TokenType::Number(10));
        assert_eq!(tokens[6].token_type, TokenType::EOL);
        assert_eq!(tokens[7].token_type, TokenType::EOF);
    }

    #[test]
    fn test_tokenize_label_definition() {
        let source = "start: NOP";
        let mut lexer = Lexer::new(source);
        let tokens = lexer.tokenize().unwrap();

        assert_eq!(tokens.len(), 4); // start:, NOP, EOL, EOF
        assert_eq!(tokens[0].token_type, TokenType::LabelDef("start".to_string()));
        assert_eq!(tokens[1].token_type, TokenType::Mnemonic("NOP".to_string()));
        assert_eq!(tokens[2].token_type, TokenType::EOL);
        assert_eq!(tokens[3].token_type, TokenType::EOF);
    }

    #[test]
    fn test_tokenize_directive() {
        let source = ".org 0x100";
        let mut lexer = Lexer::new(source);
        let tokens = lexer.tokenize().unwrap();

        assert_eq!(tokens.len(), 4); // .org, 0x100, EOL, EOF
        assert_eq!(tokens[0].token_type, TokenType::Directive("org".to_string()));
        assert_eq!(tokens[1].token_type, TokenType::Number(256)); // 0x100 = 256
        assert_eq!(tokens[2].token_type, TokenType::EOL);
        assert_eq!(tokens[3].token_type, TokenType::EOF);
    }

    #[test]
    fn test_tokenize_comment() {
        let source = "NOP # No operation";
        let mut lexer = Lexer::new(source);
        let tokens = lexer.tokenize().unwrap();

        assert_eq!(tokens.len(), 4); // NOP, comment, EOL, EOF
        assert_eq!(tokens[0].token_type, TokenType::Mnemonic("NOP".to_string()));
        assert_eq!(tokens[1].token_type, TokenType::Comment("No operation".to_string()));
        assert_eq!(tokens[2].token_type, TokenType::EOL);
        assert_eq!(tokens[3].token_type, TokenType::EOF);
    }
}