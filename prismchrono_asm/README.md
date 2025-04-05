# PrismChrono Assembleur (prismchrono_asm)

Un assembleur pour l'architecture ternaire PrismChrono, permettant de traduire du code assembleur en code machine ternaire.

## Objectif

L'assembleur `prismchrono_asm` est un outil en ligne de commande qui traduit des fichiers texte (`.s`) contenant du code assembleur PrismChrono en un fichier de sortie (`.tobj`) représentant le code machine ternaire dans un format texte lisible.

L'implémentation repose sur le mécanisme classique de l'**assemblage en deux passes** pour gérer les références avant aux labels.

## Fonctionnalités

- Parsing du code assembleur PrismChrono
- Gestion des labels et résolution des références
- Support des directives `.org`, `.tryte`, `.word`, `.align`
- Encodage des instructions en code machine ternaire
- Génération de fichiers `.tobj` lisibles

## Instructions supportées

L'assembleur supporte les instructions suivantes :

### Instructions de base
- `NOP` - No Operation
- `HALT` - Arrêt du processeur

### Instructions arithmétiques et logiques
- `ADDI` - Addition immédiate
- `LUI` - Load Upper Immediate
- `ADD` - Addition
- `SUB` - Soustraction

### Instructions de contrôle de flux
- `JAL` - Jump And Link
- `BRANCH` - Branchement conditionnel (avec conditions: eq, ne, lt, ge, gt, le)

### Instructions mémoire
- `STOREW` - Stocke un mot (word)
- `STORET` - Stocke un tryte

### Instructions système
- `ECALL` - Appel système
- `EBREAK` - Point d'arrêt
- `MRET_T` - Retour de trap machine

### Instructions CSR (Control and Status Register)
- `CSRRW_T` - CSR Read & Write
- `CSRRS_T` - CSR Read & Set

### Registres CSR supportés
- `MSTATUS_T` - État machine
- `MTVEC_T` - Vecteur de trap
- `MEPC_T` - Adresse de retour de trap
- `MCAUSE_T` - Cause du trap

## Utilisation

```bash
# Assembler un fichier source
prismchrono_asm input.s -o output.tobj

# Afficher l'aide
prismchrono_asm --help
```

## Format du fichier assembleur (.s)

```assembly
# Exemple de code assembleur PrismChrono
.org 0x100      # Définir l'adresse de départ

start:          # Définition d'un label
    LUI R1, 42  # Charger la valeur 42 dans le registre R1
    ADDI R2, R1, 10  # R2 = R1 + 10
    JAL loop    # Sauter à 'loop' et sauvegarder l'adresse de retour

loop:
    NOP         # Ne rien faire
    JAL start   # Retourner au début
    HALT        # Arrêter le processeur (ne sera jamais exécuté)
```

## Format du fichier objet (.tobj)

Le fichier `.tobj` est un format texte représentant le code machine ternaire :

```
0100: ZZZ ZZZ ZZZ ZZZ # NOP
0104: PZN NZP ZZZ ZZZ # LUI R1, 42
0108: ZPN PZZ NZP ZZZ # ADDI R2, R1, 10
010C: PNN ZZZ ZZZ ZZZ # JAL loop
0110: ZZZ ZZZ ZZZ ZZZ # NOP
0114: PNN NZZ ZZZ ZZZ # JAL start
0118: ZZZ ZZZ ZZP ZZZ # HALT
```

## Développement

Ce projet est en cours de développement dans le cadre du Sprint 10 du projet PrismChrono.