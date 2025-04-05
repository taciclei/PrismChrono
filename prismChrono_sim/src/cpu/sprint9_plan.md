# Plan d'implémentation du Sprint 9 - RV32I Base Equivalence

Ce document détaille les modifications nécessaires pour implémenter les instructions du Sprint 9 dans le simulateur PrismChrono.

## 1. Modifications de l'ISA (isa.rs)

### Nouveaux Opcodes à ajouter

```rust
// Dans l'enum Opcode
Lui,    // Load Upper Immediate (Format U)
Auipc,  // Add Upper Immediate to PC (Format U)
Jalr,   // Jump And Link Register (Format I)
```

### Nouvelles instructions à ajouter

```rust
// Dans l'enum Instruction
// Format U: opérations avec immédiat supérieur
Lui {
    rd: Register,
    imm: i16,     // Immédiat 7 trits
},

Auipc {
    rd: Register,
    imm: i16,     // Immédiat 7 trits
},

// Format I: saut indirect
Jalr {
    rd: Register,
    rs1: Register,
    offset: i8,   // Offset 5 trits
},
```

### Modifications des fonctions de conversion

```rust
// Dans la fonction trits_to_opcode
-5 => Some(Opcode::Lui),
-4 => Some(Opcode::Auipc),
-3 => Some(Opcode::Jalr),
```

## 2. Modifications du décodeur (decode.rs)

### Nouvelles fonctions de décodage

```rust
/// Décode une instruction LUI format U
/// [opcode(3) | rd(3) | imm(6)]
fn decode_lui(instr_trits: &[Trit; 12]) -> Result<Instruction, DecodeError> {
    // Extraire les champs
    let rd_trits = [instr_trits[3], instr_trits[4], instr_trits[5]];
    let imm_trits = [
        instr_trits[6], instr_trits[7], instr_trits[8],
        instr_trits[9], instr_trits[10], instr_trits[11]
    ];
    
    // Convertir en valeurs
    let rd = trits_to_register(rd_trits).ok_or(DecodeError::InvalidRegister)?;
    let imm = trits_to_imm6(imm_trits);
    
    Ok(Instruction::Lui { rd, imm })
}

/// Décode une instruction AUIPC format U
/// [opcode(3) | rd(3) | imm(6)]
fn decode_auipc(instr_trits: &[Trit; 12]) -> Result<Instruction, DecodeError> {
    // Extraire les champs
    let rd_trits = [instr_trits[3], instr_trits[4], instr_trits[5]];
    let imm_trits = [
        instr_trits[6], instr_trits[7], instr_trits[8],
        instr_trits[9], instr_trits[10], instr_trits[11]
    ];
    
    // Convertir en valeurs
    let rd = trits_to_register(rd_trits).ok_or(DecodeError::InvalidRegister)?;
    let imm = trits_to_imm6(imm_trits);
    
    Ok(Instruction::Auipc { rd, imm })
}

/// Décode une instruction JALR format I
/// [opcode(3) | rd(3) | rs1(3) | offset(3)]
fn decode_jalr(instr_trits: &[Trit; 12]) -> Result<Instruction, DecodeError> {
    // Extraire les champs
    let rd_trits = [instr_trits[3], instr_trits[4], instr_trits[5]];
    let rs1_trits = [instr_trits[6], instr_trits[7], instr_trits[8]];
    let offset_trits = [instr_trits[9], instr_trits[10], instr_trits[11]];
    
    // Convertir en valeurs
    let rd = trits_to_register(rd_trits).ok_or(DecodeError::InvalidRegister)?;
    let rs1 = trits_to_register(rs1_trits).ok_or(DecodeError::InvalidRegister)?;
    let offset = trits_to_imm3(offset_trits);
    
    Ok(Instruction::Jalr { rd, rs1, offset })
}
```

### Modifications de la fonction decode

```rust
// Dans la fonction decode
match opcode {
    // Ajouter ces cas
    Opcode::Lui => decode_lui(&instr_trits),
    Opcode::Auipc => decode_auipc(&instr_trits),
    Opcode::Jalr => decode_jalr(&instr_trits),
    // Cas existants...
}
```

## 3. Modifications de l'exécution (execute.rs)

### Nouvelles fonctions d'exécution

```rust
/// Exécute une instruction LUI (Load Upper Immediate)
fn execute_lui(&mut self, rd: Register, imm: i16) -> Result<(), ExecuteError> {
    // Créer un Word avec l'immédiat dans les trits supérieurs
    let mut result = Word::zero(); // Tous les trits à Z
    
    // Placer l'immédiat dans les trits supérieurs (t23..t17)
    // TODO: Implémenter la conversion de i16 en trits et le placement dans Word
    
    // Écrire le résultat dans le registre de destination
    self.state.write_gpr(rd, result);
    
    Ok(())
}

/// Exécute une instruction AUIPC (Add Upper Immediate to PC)
fn execute_auipc(&mut self, rd: Register, imm: i16) -> Result<(), ExecuteError> {
    // Lire le PC actuel
    let pc = self.state.read_pc();
    
    // Créer un Word avec l'immédiat dans les trits supérieurs
    let mut imm_word = Word::zero(); // Tous les trits à Z
    
    // Placer l'immédiat dans les trits supérieurs (t23..t17)
    // TODO: Implémenter la conversion de i16 en trits et le placement dans Word
    
    // Ajouter le PC et l'immédiat
    let (result, _, _) = add_24_trits(pc, imm_word, Trit::Z);
    
    // Écrire le résultat dans le registre de destination
    self.state.write_gpr(rd, result);
    
    Ok(())
}

/// Exécute une instruction JALR (Jump And Link Register)
fn execute_jalr(&mut self, rd: Register, rs1: Register, offset: i8) -> Result<(), ExecuteError> {
    // Lire l'adresse de base depuis le registre source
    let base_addr = self.state.read_gpr(rs1);
    
    // Lire le PC actuel
    let pc = self.state.read_pc();
    
    // Calculer PC + 4 (adresse de retour)
    let return_addr = Word::from_address(self.state.pc_value() + 4);
    
    // Calculer l'adresse cible (base + offset)
    // TODO: Implémenter le calcul d'adresse (base + offset)
    let target_addr = base_addr; // Temporaire
    
    // Forcer l'alignement sur 4 trytes (effacer les 2 trits de poids faible)
    // TODO: Implémenter l'alignement
    let aligned_target = target_addr; // Temporaire
    
    // Sauvegarder l'adresse de retour dans rd (si rd != R0)
    if rd != Register::R0 {
        self.state.write_gpr(rd, return_addr);
    }
    
    // Mettre à jour le PC
    self.state.write_pc(aligned_target);
    
    Ok(())
}
```

### Modifications de la fonction execute

```rust
// Dans la fonction execute
match instruction {
    // Ajouter ces cas
    Instruction::Lui { rd, imm } => {
        self.execute_lui(rd, imm)
    },
    Instruction::Auipc { rd, imm } => {
        self.execute_auipc(rd, imm)
    },
    Instruction::Jalr { rd, rs1, offset } => {
        self.execute_jalr(rd, rs1, offset)
    },
    // Cas existants...
}
```

## 4. Modifications des tests

### Nouveaux tests pour le décodeur

```rust
#[test]
fn test_decode_lui() {
    // Créer une instruction LUI
    // Opcode LUI = [N,P,N] (-5)
    // rd = R5 = [N,P,N] (-8)
    // imm = [Z,P,Z,N,P,Z] (valeur à calculer)
    let instr_trits = [
        Trit::N, Trit::P, Trit::N,  // Opcode LUI
        Trit::N, Trit::P, Trit::N,  // rd = R5
        Trit::Z, Trit::P, Trit::Z,  // imm[5:3]
        Trit::N, Trit::P, Trit::Z,  // imm[2:0]
    ];
    
    let result = create_instruction(instr_trits);
    assert!(result.is_ok());
    
    if let Ok(Instruction::Lui { rd, imm }) = result {
        assert_eq!(rd, Register::R5);
        // Vérifier que l'immédiat est correct (valeur à calculer)
    } else {
        panic!("Expected Lui instruction");
    }
}
```

## 5. Prochaines étapes

1. Implémenter les fonctions de conversion entre types numériques et Word/Tryte/Trit
2. Compléter les fonctions d'exécution avec la logique manquante
3. Ajouter des tests pour toutes les nouvelles instructions
4. Mettre à jour la documentation