# PrismChrono Simulator

## Présentation

PrismChrono Simulator est un simulateur pour l'architecture ternaire PrismChrono. Cette architecture unique utilise une logique ternaire (à trois états) au lieu de la logique binaire traditionnelle, offrant des possibilités de calcul différentes et innovantes.

## Caractéristiques de l'Architecture

- **Type**: Architecture Logic GPR Base-24 Ternaire +
- **Taille de mot**: 24 Trits (8 Trytes)
- **Mémoire adressable**: 16 MTrytes
- **Endianness**: Little-Endian
- **Registres**: 8 registres généraux (R0-R7)
- **Système de privilèges**: 3 niveaux (Machine, Supervisor, User)
- **Format d'instructions**: Standard (12 Trits) et Compact (8 Trits)
- **Pipeline**: 5 étages avec prédiction de branchement

## Structure du Projet

```
prismChrono_sim/
├── src/
│   ├── alu.rs                # Implémentation de l'ALU (Arithmetic Logic Unit)
│   ├── branch_predictor.rs   # Prédicteur de branchement
│   ├── cache.rs              # Implémentation du cache
│   ├── core/
│   │   ├── mod.rs            # Module principal pour les types de base
│   │   └── types.rs          # Définition des types ternaires (Trit, Tryte, Word)
│   ├── cpu/
│   │   ├── decode.rs                # Décodage des instructions
│   │   ├── execute_core.rs          # Cœur d'exécution des instructions
│   │   ├── execute_alu.rs           # Exécution des instructions ALU
│   │   ├── execute_branch.rs        # Exécution des instructions de branchement
│   │   ├── execute_load_store.rs    # Exécution des instructions mémoire
│   │   ├── execute_system.rs        # Exécution des instructions système
│   │   ├── execute_ternary.rs       # Exécution des instructions ternaires spécialisées
│   │   ├── isa.rs                   # Définition de l'ISA (Instruction Set Architecture)
│   │   ├── isa_extensions.rs        # Extensions de l'ISA
│   │   ├── mod.rs                   # Module principal pour le CPU
│   │   ├── registers.rs             # Gestion des registres
│   │   ├── state.rs                 # Gestion de l'état du CPU
│   │   └── supervisor_privilege.rs  # Gestion des privilèges superviseur
│   ├── memory.rs             # Implémentation de la mémoire
│   ├── neural.rs             # Fonctionnalités pour le calcul neuronal ternaire
│   ├── pipeline.rs           # Implémentation du pipeline
│   ├── lib.rs                # Bibliothèque pour l'exportation des fonctionnalités
│   └── main.rs               # Point d'entrée du simulateur
└── bin/                      # Programmes de test
```

## Types de Données Ternaires

### Trit

Le Trit est l'unité fondamentale de l'architecture ternaire, équivalent au bit dans les systèmes binaires. Il peut prendre trois valeurs :

- **N** : -1 (Négatif)
- **Z** : 0 (Zéro)
- **P** : +1 (Positif)

### Tryte

Un Tryte est composé de 3 Trits et peut représenter :

- **Digit** : Une valeur numérique de 0 à 23 (équivalent à -13 à +10 en ternaire équilibré)
- **Undefined** : Valeur spéciale (Bal3 +11)
- **Null** : Valeur spéciale (Bal3 +12)
- **NaN** : Valeur spéciale (Bal3 +13)

### Word

Un Word est composé de 8 Trytes (24 Trits) et représente la taille standard des données manipulées par le processeur.

## Avantages de l'Architecture Ternaire

- **Densité d'information** : 3^24 (≈ 282 trillion) états possibles par mot vs 2^32 (≈ 4 milliard) en binaire 32-bit
- **Efficacité énergétique** : Meilleure utilisation théorique du rapport signal/bruit
- **Logique naturelle** : Représentation directe des concepts vrai/faux/inconnu ou positif/zéro/négatif
- **Arithmétique équilibrée** : Représentation symétrique des nombres positifs et négatifs

## Formats d'Instructions

Les instructions PrismChrono utilisent deux formats principaux :

### Format Standard (12 Trits)

- **Format R** : `[opcode(3t) | rd(2t) | rs1(2t) | rs2(2t) | func(3t)]`
  - Utilisé pour les opérations registre-registre

- **Format I** : `[opcode(3t) | rd(2t) | rs1(2t) | immediate(5t)]`
  - Utilisé pour les opérations avec immédiat

- **Format S** : `[opcode(3t) | src(2t) | base(2t) | offset(5t)]`
  - Utilisé pour les opérations de stockage

- **Format B** : `[opcode(3t) | cond(3t) | rs1(2t) | offset(4t)]`
  - Utilisé pour les opérations de branchement

- **Format U** : `[opcode(3t) | rd(2t) | immediate(7t)]`
  - Utilisé pour les opérations avec immédiat étendu

- **Format J** : `[opcode(3t) | rd(2t) | offset(7t)]`
  - Utilisé pour les opérations de saut

- **Format C** : `[opcode(3t) | rd(2t) | rs1(2t) | csr(5t)]`
  - Utilisé pour les opérations sur les registres de contrôle et de statut (CSR)

### Format Compact (8 Trits)

- **Format C** : `[op(2t) | rd/cond(2t) | rs/offset(4t)]`
  - Format optimisé pour réduire la taille du code
  - Supporte un sous-ensemble d'instructions fréquemment utilisées
  - Améliore la densité de code et l'efficacité du cache

## Jeu d'Instructions

### Instructions Spéciales

- **NOP** : Aucune opération
- **HALT** : Arrête l'exécution du processeur

### Instructions ALU (Format R)

Opérations registre-registre avec les opérations suivantes :

- **ADD** : Addition (rd = rs1 + rs2)
- **SUB** : Soustraction (rd = rs1 - rs2)
- **MUL** : Multiplication (rd = rs1 * rs2)
- **DIV** : Division (rd = rs1 / rs2)
- **MOD** : Modulo (rd = rs1 % rs2)
- **AND** : ET logique (rd = rs1 & rs2)
- **OR** : OU logique (rd = rs1 | rs2)
- **XOR** : OU exclusif (rd = rs1 ^ rs2)
- **SHL** : Décalage à gauche (rd = rs1 << rs2)
- **SHR** : Décalage à droite (rd = rs1 >> rs2)
- **CMP** : Comparaison (met à jour les flags)

### Instructions ALU avec Immédiat (Format I)

Opérations similaires aux instructions ALU mais avec une valeur immédiate au lieu d'un second registre.

### Instructions de Chargement/Stockage

- **LOAD** : Charge un mot (24 trits) depuis la mémoire vers un registre
- **LOADT** : Charge un tryte avec extension de signe
- **LOADTU** : Charge un tryte sans extension de signe
- **STORE** : Stocke un mot (24 trits) depuis un registre vers la mémoire
- **STORET** : Stocke un tryte

### Instructions de Branchement (Format B)

Branchement conditionnel basé sur les flags :

- **BEQ** : Branche si égal (ZF = 1)
- **BNE** : Branche si non égal (ZF = 0)
- **BLT** : Branche si inférieur (SF = 1)
- **BGE** : Branche si supérieur ou égal (SF = 0)
- **BLTU** : Branche si inférieur non signé
- **BGEU** : Branche si supérieur ou égal non signé
- **BOF** : Branche si débordement (OF = 1)
- **BCF** : Branche si retenue (CF = 1)
- **BSPEC** : Branche si état spécial (XF = 1)
- **B** : Branche toujours

### Instructions de Saut (Format J)

- **JUMP** : Saut inconditionnel
- **CALL** : Appel de sous-routine
- **JALR** : Saut et lien vers registre (Format I)

### Instructions avec Immédiat Supérieur (Format U)

- **LUI** : Charge l'immédiat supérieur
- **AUIPC** : Ajoute l'immédiat supérieur au PC

### Instructions Système et CSR (Format C)

- **CSRRW** : CSR Read & Write - Lit la valeur actuelle d'un CSR et écrit une nouvelle valeur
- **CSRRS** : CSR Read & Set - Lit la valeur actuelle d'un CSR et active des bits spécifiques
- **CSRRC** : CSR Read & Clear - Lit la valeur actuelle d'un CSR et désactive des bits spécifiques
- **MRET** : Machine Return - Retourne d'une exception en mode Machine
- **SRET** : Supervisor Return - Retourne d'une exception en mode Supervisor
- **ECALL** : Environment Call - Appel système
- **EBREAK** : Environment Break - Point d'arrêt pour débogage

### Instructions Ternaires Spécialisées

#### Manipulation de Trits
- **TRITINV Rd, Rs1** : Inverseur logique trit-à-trit (N→P, P→N, Z→Z)
- **TMIN Rd, Rs1, Rs2** : Minimum ternaire (par trit) - Pour chaque trit i: Rd[i] = min(Rs1[i], Rs2[i])
- **TMAX Rd, Rs1, Rs2** : Maximum ternaire (par trit) - Pour chaque trit i: Rd[i] = max(Rs1[i], Rs2[i])
- **TSUM Rd, Rs1, Rs2** : Somme ternaire (par trit) - Pour chaque trit i: Rd[i] = Rs1[i] + Rs2[i] (sans propagation)
- **TCMP3 Rd, Rs1, Rs2** : Comparaison ternaire à 3 états - Pour chaque trit i: Rd[i] = -1 si Rs1[i] < Rs2[i], 0 si Rs1[i] = Rs2[i], 1 si Rs1[i] > Rs2[i]

#### Rotation et Décalage Ternaires
- **TROTL/TROTR Rd, Rs1, imm** : Rotation ternaire à gauche/droite
- **TSHIFTL/TSHIFTR Rd, Rs1, imm** : Décalage ternaire à gauche/droite

#### Branchement Ternaire
- **BRANCH3 Rs1, offset_neg, offset_zero, offset_pos** : Branchement basé sur une condition ternaire (-1, 0, +1)

#### Accès Mémoire Optimisés
- **LOADT3 Rd, imm(Rs1)** : Chargement optimisé de 3 trytes consécutifs
- **STORET3 Rs2, imm(Rs1)** : Stockage optimisé de 3 trytes consécutifs
- **LOADTM Rd, mask, imm(Rs1)** : Chargement avec masque de trytes
- **STORETM Rs2, mask, imm(Rs1)** : Stockage avec masque de trytes
- **TMEMCPY Rd, Rs1, Rs2** : Copie mémoire ternaire optimisée
- **TMEMSET Rd, Rs1, Rs2** : Initialisation mémoire ternaire

#### Opérations Multi-Cycle
- **MADDW/MSUBW Rd, Rs1, Rs2, Rs3** : Multiplication-addition/soustraction
- **TSEL Rd, Rs1, Rs2, Rs3** : Sélection ternaire (équivalent à un multiplexeur à 3 entrées)

#### Extensions pour Calcul Neuronal Ternaire
- **TNNMUL Rd, Rs1, Rs2** : Multiplication matricielle ternaire pour réseaux neuronaux
- **TNNACT Rd, Rs1** : Fonction d'activation ternaire
- **TNNPOOL Rd, Rs1, Rs2** : Opération de pooling ternaire

### Instructions Format Compact

#### Format C (8 Trits)
- **CMOV Rd, Rs** : Copie registre (format compact) - Rd = Rs
- **CADD Rd, Rs** : Addition (format compact) - Rd = Rd + Rs
- **CSUB Rd, Rs** : Soustraction (format compact) - Rd = Rd - Rs
- **CBRANCH cond, offset** : Branchement conditionnel (format compact) - Si condition vraie: PC += offset*4

#### Avantages du Format Compact
- **Densité de code** : Réduit la taille du code de 33% (8 trits vs 12 trits)
- **Efficacité du cache** : Améliore le taux de succès du cache d'instructions
- **Performance** : Réduit le temps de chargement des instructions
- **Consommation** : Diminue la bande passante mémoire requise

## Pipeline et Exécution

PrismChrono utilise un pipeline à 5 étages :

1. **IF** (Instruction Fetch) : Récupération de l'instruction depuis la mémoire
2. **ID** (Instruction Decode) : Décodage de l'instruction et lecture des registres
3. **EX** (Execute) : Exécution de l'instruction dans l'ALU ou autre unité fonctionnelle
4. **MEM** (Memory Access) : Accès à la mémoire pour les chargements/stockages
5. **WB** (Write Back) : Écriture des résultats dans les registres

### Prédiction de Branchement

Le simulateur implémente plusieurs stratégies de prédiction de branchement :

- **Statique** : Toujours prédire pris/non pris
- **Local** : Prédiction basée sur l'historique local du branchement
- **Global** : Prédiction basée sur l'historique global de tous les branchements
- **Tournament** : Combinaison des prédicteurs locaux et globaux
- **Tri-directional** : Prédiction ternaire spécialisée pour les branchements à 3 voies

### Système de Cache

Le simulateur inclut un système de cache configurable :

- **Cache L1** : Cache d'instructions et de données de premier niveau
- **Cache unifié** : Cache partagé entre instructions et données
- **Politique de remplacement** : LRU (Least Recently Used)
- **Politique d'écriture** : Write-back et write-allocate
- **Préchargement** : Préchargement basé sur les motifs d'accès

## Système de Privilèges

L'architecture PrismChrono implémente trois niveaux de privilège :

| Niveau | Nom | Description |
|--------|-----|-------------|
| 2 | Machine (M-mode) | Mode le plus privilégié, accès complet au matériel et aux CSRs |
| 1 | Supervisor (S-mode) | Mode intermédiaire, utilisé par le système d'exploitation |
| 0 | User (U-mode) | Mode non privilégié, utilisé par les applications |

Le système de privilèges est géré par des CSRs (Control and Status Registers) ternaires spécifiques :

- **mstatus_t, sstatus_t** : Registres d'état pour chaque niveau de privilège
- **mtvec_t, stvec_t** : Vecteurs de trap pour chaque niveau
- **mepc_t, sepc_t** : Compteurs de programme d'exception
- **mcause_t, scause_t** : Registres de cause d'exception
- **medeleg_t, mideleg_t** : Registres de délégation d'exception et d'interruption

## Flags et État du Processeur

Le processeur maintient plusieurs flags qui sont mis à jour par les opérations ALU :

- **ZF** : Zero Flag (1 si le résultat est zéro)
- **SF** : Sign Flag (1 si le résultat est négatif)
- **OF** : Overflow Flag (1 si un débordement s'est produit)
- **CF** : Carry Flag (1 si une retenue s'est produite)
- **XF** : Extended Flag (1 pour des conditions spéciales)

## Extensions Matérielles

### Accélération des Calculs Neuronaux Ternaires

Le simulateur inclut des extensions matérielles pour accélérer les calculs neuronaux en ternaire :

- Multiplication matricielle ternaire optimisée
- Fonctions d'activation ternaires natives
- Opérations de pooling et convolution ternaires
- Compression de poids ternaires pour réduire l'empreinte mémoire

### Compression de Données Ternaires

Des algorithmes natifs de compression/décompression ternaire sont implémentés :

- **Huffman Ternaire** : Compression adaptative basée sur la fréquence des symboles
- **Run-Length Ternaire** : Compression des séquences répétitives en ternaire
- **Delta Ternaire** : Compression par différence ternaire

## Utilisation du Simulateur

Le simulateur peut être exécuté avec la commande :

```bash
cargo run
```

Des programmes de test sont disponibles dans le dossier `bin/` et peuvent être exécutés avec :

```bash
cargo run --bin test_alu_flags
cargo run --bin test_branch
cargo run --bin test_cpu
cargo run --bin test_load_store
cargo run --bin test_ternary_ops
cargo run --bin test_compact_format
cargo run --bin test_csr_ops
cargo run --bin test_neural
```

## Benchmarking

Le simulateur inclut un système de benchmarking pour comparer les performances de l'architecture ternaire PrismChrono avec l'architecture binaire traditionnelle. Les benchmarks mesurent :

- Vitesse d'exécution (instructions par seconde)
- Utilisation de la mémoire
- Efficacité énergétique théorique
- Densité de code

## Développement Futur

Le projet PrismChrono prévoit les développements suivants :

- Amélioration du compilateur assembleur (`prismchrono_asm`)
- Implémentation d'un système d'exploitation minimal ternaire
- Optimisation des performances du simulateur
- Extension du jeu d'instructions ternaires spécialisées
- Développement d'un compilateur C pour l'architecture PrismChrono
- Implémentation matérielle sur FPGA

## Comment Contribuer

Les contributions au projet PrismChrono sont les bienvenues. Voici comment vous pouvez contribuer :

1. Forker le dépôt
2. Créer une branche pour vos modifications (`git checkout -b feature/ma-feature`)
3. Committer vos changements (`git commit -am 'Ajout de ma feature'`)
4. Pousser vers la branche (`git push origin feature/ma-feature`)
5. Créer une Pull Request

## Licence

Ce projet est sous licence MIT. Voir le fichier LICENSE pour plus de détails.