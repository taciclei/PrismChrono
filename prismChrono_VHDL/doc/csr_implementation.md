# Implémentation des CSR (Control and Status Registers) dans PrismChrono

Ce document décrit l'implémentation des registres de contrôle et de statut (CSR) dans le processeur PrismChrono VHDL.

## Vue d'ensemble

Les CSR (Control and Status Registers) sont des registres spéciaux qui permettent au processeur de gérer son propre état interne. Dans l'architecture PrismChrono, ces registres sont utilisés pour:

- Stocker l'état du processeur (mode de fonctionnement, interruptions activées, etc.)
- Gérer les exceptions et les interruptions
- Fournir des informations sur les capacités du processeur
- Stocker des valeurs temporaires pour le système d'exploitation

## Architecture des CSR

Les CSR sont implémentés dans un module dédié `csr_registers.vhd`. Ce module gère l'accès en lecture et en écriture aux différents registres CSR en fonction du niveau de privilège courant.

### Registres implémentés

Les principaux registres CSR implémentés sont:

| Nom | Adresse | Description |
|-----|---------|-------------|
| mstatus | 0x300 | État de la machine |
| misa | 0x301 | Architecture ISA supportée |
| medeleg | 0x302 | Délégation des exceptions |
| mideleg | 0x303 | Délégation des interruptions |
| mie | 0x304 | Activation des interruptions |
| mtvec | 0x305 | Vecteur de trap |
| mscratch | 0x340 | Registre de travail |
| mepc | 0x341 | Exception Program Counter |
| mcause | 0x342 | Cause de l'exception |
| mtval | 0x343 | Valeur associée au trap |
| mip | 0x344 | Interruptions en attente |

## Encodage ternaire des CSR

Dans l'architecture PrismChrono, les CSR sont encodés en ternaire, comme toutes les autres données. Chaque CSR est représenté par un `EncodedWord` de 24 trits (48 bits).

## Instructions CSR

Trois instructions CSR sont implémentées:

1. **CSRRW_T** (CSR Read/Write Ternary): Lit la valeur actuelle du CSR dans le registre destination (rd) et écrit la valeur du registre source (rs1) dans le CSR.

2. **CSRRS_T** (CSR Read/Set Ternary): Lit la valeur actuelle du CSR dans le registre destination (rd) et effectue une opération MAX ternaire bit à bit entre le CSR et le registre source (rs1).

3. **CSRRC_T** (CSR Read/Clear Ternary): Lit la valeur actuelle du CSR dans le registre destination (rd) et effectue une opération MIN ternaire bit à bit entre le CSR et le complément du registre source (rs1).

## Opérations ternaires sur les CSR

### Opération MAX ternaire (pour CSRRS_T)

L'opération MAX ternaire est utilisée pour l'instruction CSRRS_T. Elle est définie comme suit:

| Trit A | Trit B | MAX(A,B) |
|--------|--------|----------|
| -1 | -1 | -1 |
| -1 | 0 | 0 |
| -1 | +1 | +1 |
| 0 | -1 | 0 |
| 0 | 0 | 0 |
| 0 | +1 | +1 |
| +1 | -1 | +1 |
| +1 | 0 | +1 |
| +1 | +1 | +1 |

Cette opération est équivalente à un OR logique dans le cas binaire.

### Opération MIN ternaire (pour CSRRC_T)

L'opération MIN ternaire est utilisée pour l'instruction CSRRC_T. Elle est définie comme suit:

| Trit A | Trit B | MIN(A,B) |
|--------|--------|----------|
| -1 | -1 | -1 |
| -1 | 0 | -1 |
| -1 | +1 | -1 |
| 0 | -1 | -1 |
| 0 | 0 | 0 |
| 0 | +1 | 0 |
| +1 | -1 | -1 |
| +1 | 0 | 0 |
| +1 | +1 | +1 |

Cette opération est équivalente à un AND logique dans le cas binaire.

## Intégration avec le pipeline

Les CSR sont intégrés dans le pipeline du processeur PrismChrono. L'accès aux CSR se fait pendant l'étage d'exécution (EXEC_CSR) et le résultat est écrit dans le registre destination pendant l'étage de write-back (WB_CSR).

## Vérification du niveau de privilège

L'accès aux CSR est contrôlé par le niveau de privilège courant du processeur. Dans l'implémentation actuelle, tous les CSR nécessitent le niveau de privilège Machine (M) pour être accessibles.

## Extensions futures

Dans les versions futures, l'implémentation des CSR pourra être étendue pour:

- Supporter d'autres niveaux de privilège (Supervisor, User)
- Ajouter des CSR spécifiques à l'architecture ternaire
- Implémenter des mécanismes de protection mémoire
- Gérer des fonctionnalités avancées comme la virtualisation