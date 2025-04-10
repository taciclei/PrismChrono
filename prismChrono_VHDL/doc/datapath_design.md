# Documentation du Datapath pour PrismChrono

## Introduction

Le datapath est la partie du processeur PrismChrono qui effectue les opérations de traitement des données. Il est composé de plusieurs modules interconnectés (ALU, banc de registres, PC, etc.) qui sont contrôlés par l'unité de contrôle. Cette documentation décrit l'organisation du datapath et les signaux de contrôle utilisés pour coordonner les opérations.

## Architecture Générale

Le datapath du processeur PrismChrono est organisé autour des composants suivants :

1. **PC (Program Counter)** : Registre qui contient l'adresse de l'instruction courante.
2. **IR (Instruction Register)** : Registre qui stocke l'instruction en cours d'exécution.
3. **Décodeur d'Instructions** : Module qui extrait les différents champs de l'instruction (opcode, registres, immédiat).
4. **Banc de Registres** : Module qui stocke les valeurs des registres généraux.
5. **ALU (Arithmetic Logic Unit)** : Module qui effectue les opérations arithmétiques et logiques.
6. **Multiplexeurs** : Composants qui sélectionnent les sources de données en fonction des signaux de contrôle.

## Schéma du Datapath

```
+-------+     +----------------+     +-------------------+
|  PC   | --> | Mémoire Instr. | --> | Instruction Reg.  |
+-------+     +----------------+     +-------------------+
    ^                                          |
    |                                          v
    |                                 +------------------+
    |                                 | Décodeur Instr.  |
    |                                 +------------------+
    |                                     |       |
    |                                     |       v
    |                                     |   +-------------+
    |                                     |   | Immédiat    |
    |                                     |   +-------------+
    |                                     |       |
    |                                     v       v
    |                                 +------------------+
    |                                 | Banc de Registres|
    |                                 +------------------+
    |                                     |       |
    |                                     v       v
    |                                 +------------------+
    |                                 |       ALU       |
    |                                 +------------------+
    |                                     |    |
    |                                     |    v
    |                                     |  +-------------+
    |                                     |  | Flags (ZF,SF)|
    |                                     |  +-------------+
    |                                     |       |
    |                                     v       v
    |                             +----------------------+
    |                             | Évaluation Condition |
    |                             +----------------------+
    |                                     |       |
    |                                     v       v
    |                             +----------------------+
    |                             | Calcul Adresse Cible |
    |                             +----------------------+
    |                                          |
    |                                          v
    |                                 +------------------+
    +-------------------------------- |  Multiplexeur   |
                                      +------------------+
```

## Composants du Datapath

### PC (Program Counter)

Le PC est un registre qui contient l'adresse de l'instruction courante. Il est mis à jour à chaque cycle d'instruction en fonction des signaux de contrôle :
- `pc_inc` : Incrémente le PC (PC = PC + 1).
- `pc_load` : Charge une nouvelle valeur dans le PC.
- `pc_src` : Sélectionne la source de la nouvelle valeur du PC :
  - "00" : PC+1 (incrémentation normale)
  - "01" : Adresse cible JALR ((Rs1 + offset) & AlignMask(4))
  - "10" : Adresse cible JAL (PC + offset*4)
  - "11" : Adresse cible BRANCH (PC + offset*4)

### IR (Instruction Register)

L'IR est un registre qui stocke l'instruction en cours d'exécution. Il est mis à jour pendant la phase de fetch lorsque le signal `mem_read` est actif.

### Décodeur d'Instructions

Le décodeur d'instructions extrait les différents champs de l'instruction :
- `opcode` : Code d'opération (3 trits).
- `rd_addr` : Adresse du registre destination (3 bits).
- `rs1_addr` : Adresse du registre source 1 (3 bits).
- `rs2_addr` : Adresse du registre source 2 (3 bits).
- `immediate` : Valeur immédiate (étendue à 24 trits).

### Banc de Registres

Le banc de registres contient 8 registres généraux de 24 trits chacun. Il possède deux ports de lecture et un port d'écriture :
- `rd_addr1`, `rd_addr2` : Adresses des registres à lire.
- `rd_data1`, `rd_data2` : Données lues.
- `wr_addr` : Adresse du registre à écrire.
- `wr_data` : Données à écrire.
- `wr_en` : Signal d'activation de l'écriture.

### ALU (Arithmetic Logic Unit)

L'ALU effectue les opérations arithmétiques et logiques sur les opérandes. Elle est contrôlée par les signaux suivants :
- `alu_op` : Opération à effectuer (ADD, SUB, TMIN, TMAX, TINV).
- `alu_src_a` : Source de l'opérande A (registre source 1 ou PC).
- `alu_src_b` : Source de l'opérande B (registre source 2 ou immédiat).

### Calcul d'Adresse Cible

Le module de calcul d'adresse cible est responsable de calculer les adresses de saut et de branchement :
- **JAL** : Calcule l'adresse cible comme PC + offset*4, où offset est extrait de l'instruction et multiplié par 4 pour aligner sur les limites d'instruction.
- **JALR** : Calcule l'adresse cible comme (Rs1 + offset) & AlignMask(4), où Rs1 est le contenu du registre source 1, offset est extrait de l'instruction, et l'opération & AlignMask(4) assure l'alignement sur les limites d'instruction.
- **BRANCH** : Calcule l'adresse cible comme PC + offset*4, similaire à JAL mais avec un format d'offset différent.

### Évaluation des Conditions de Branchement

Le module d'évaluation des conditions de branchement prend les flags de l'ALU (ZF, SF, etc.) et la condition de branchement extraite de l'instruction pour déterminer si le branchement doit être pris ou non :
- **EQ (Equal)** : Branchement pris si ZF = 1 (résultat égal à zéro).
- **NE (Not Equal)** : Branchement pris si ZF = 0 (résultat différent de zéro).
- **LT (Less Than)** : Branchement pris si SF = 1 et ZF = 0 (résultat négatif et non nul).
- **GE (Greater or Equal)** : Branchement pris si SF = 0 ou ZF = 1 (résultat positif ou nul).
- **B (Branch Always)** : Branchement toujours pris.

### Multiplexeurs

Les multiplexeurs sélectionnent les sources de données en fonction des signaux de contrôle :
- Multiplexeur pour l'opérande A de l'ALU : Sélectionne entre le registre source 1 et le PC.
- Multiplexeur pour l'opérande B de l'ALU : Sélectionne entre le registre source 2 et la valeur immédiate.
- Multiplexeur pour les données d'écriture du banc de registres : Sélectionne entre le résultat de l'ALU, les données de la mémoire et PC+1 (pour JAL/JALR).
- Multiplexeur pour l'adresse d'écriture du banc de registres : Sélectionne entre le registre destination et le registre ra (pour les appels de fonction).
- Multiplexeur pour le prochain PC : Sélectionne entre PC+1 (incrémentation normale) et l'adresse cible calculée (pour JAL, JALR, BRANCH).

## Signaux de Contrôle

Les signaux de contrôle générés par l'unité de contrôle et utilisés par le datapath sont regroupés dans le type `ControlSignalsType` :

### Signaux pour le PC
- `pc_inc` : Incrémenter le PC.
- `pc_load` : Charger une nouvelle valeur dans le PC.
- `pc_src` : Source pour le PC (00: PC+1, 01: ALU, 10: immédiat).

### Signaux pour l'ALU
- `alu_op` : Opération ALU (ADD, SUB, TMIN, TMAX, TINV).
- `alu_src_a` : Source A pour l'ALU (0: rs1, 1: PC).
- `alu_src_b` : Source B pour l'ALU (0: rs2, 1: immédiat).

### Signaux pour le banc de registres
- `reg_write` : Activer l'écriture dans le banc de registres.
- `reg_dst` : Destination pour l'écriture (00: rd, 01: ra).
- `reg_src` : Source pour l'écriture (00: ALU, 01: mémoire, 10: PC+1).

### Signaux pour la mémoire
- `mem_read` : Activer la lecture mémoire.
- `mem_write` : Activer l'écriture mémoire.

### Signaux divers
- `halted` : CPU arrêté.

## Flux de Données pour les Instructions Implémentées

### NOP (No Operation)
1. Fetch : L'instruction est chargée dans l'IR.
2. Decode : L'opcode est décodé comme NOP.
3. Execute : Aucune opération n'est effectuée, le PC est incrémenté.

### ADDI (Add Immediate)
1. Fetch : L'instruction est chargée dans l'IR.
2. Decode : L'opcode est décodé comme ADDI, les adresses des registres et la valeur immédiate sont extraites.
3. Execute : L'ALU additionne le contenu du registre source et la valeur immédiate.
4. Write-back : Le résultat de l'ALU est écrit dans le registre destination, le PC est incrémenté.

### JAL (Jump And Link)
1. Fetch : L'instruction est chargée dans l'IR.
2. Decode : L'opcode est décodé comme JAL, l'adresse du registre destination et l'offset sont extraits.
3. Execute : L'adresse cible est calculée (PC + offset*4) et le PC est chargé avec cette valeur.
4. Write-back : L'adresse de retour (PC+1) est écrite dans le registre destination.

### JALR (Jump And Link Register)
1. Fetch : L'instruction est chargée dans l'IR.
2. Decode : L'opcode est décodé comme JALR, les adresses des registres et l'offset sont extraits.
3. Execute : L'adresse cible est calculée ((Rs1 + offset) & AlignMask(4)) et le PC est chargé avec cette valeur.
4. Write-back : L'adresse de retour (PC+1) est écrite dans le registre destination.

### BRANCH (Branchement Conditionnel)
1. Fetch : L'instruction est chargée dans l'IR.
2. Decode : L'opcode est décodé comme BRANCH, la condition et l'offset sont extraits.
3. Execute : 
   - La condition est évaluée en fonction des flags de l'ALU (généralement mis à jour par une instruction CMP précédente).
   - Si la condition est vraie, l'adresse cible est calculée (PC + offset*4) et le PC est chargé avec cette valeur.
   - Si la condition est fausse, le PC est simplement incrémenté.

### CMP (Compare)
1. Fetch : L'instruction est chargée dans l'IR.
2. Decode : L'opcode est décodé comme CMP, les adresses des registres sont extraites.
3. Execute : L'ALU soustrait le contenu du registre source 2 du contenu du registre source 1 et met à jour les flags (ZF, SF, etc.) en fonction du résultat.
4. Write-back : Aucune écriture n'est effectuée dans le banc de registres, le PC est incrémenté.

### HALT (Halt)
1. Fetch : L'instruction est chargée dans l'IR.
2. Decode : L'opcode est décodé comme HALT.
3. Execute : Le signal `halted` est activé, le PC n'est pas incrémenté.

## Conclusion

Le datapath du processeur PrismChrono est conçu de manière modulaire et extensible, permettant d'implémenter facilement de nouvelles instructions. Avec l'ajout des instructions de saut inconditionnel (JAL, JALR) et de branchement conditionnel (BRANCH), le processeur est maintenant capable d'exécuter des programmes complexes avec des boucles et des conditions, le rendant Turing-complet.

L'organisation des composants et les signaux de contrôle sont optimisés pour le jeu d'instructions ternaire spécifique à PrismChrono. La logique de calcul d'adresse cible et d'évaluation des conditions de branchement est conçue pour tirer parti des caractéristiques uniques de l'architecture ternaire, offrant une flexibilité et une efficacité accrues pour le contrôle de flux.