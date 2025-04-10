# Instructions Spécialisées Ternaires PrismChrono

Ce document décrit les instructions spécialisées conçues pour exploiter les avantages uniques de l'architecture ternaire équilibrée de PrismChrono.

## Instructions de Logique Multi-Valuée

### TCMP3 (Comparaison Ternaire)
- **Format:** `TCMP3 Rd, Rs1, Rs2`
- **Description:** Compare Rs1 et Rs2 et stocke le résultat ternaire dans Rd
- **Résultat:**
  - Rd = TRIT_N (-1) si Rs1 < Rs2
  - Rd = TRIT_Z (0) si Rs1 = Rs2
  - Rd = TRIT_P (+1) si Rs1 > Rs2
- **Implémentation:** Extension simple de l'ALU avec logique de comparaison ternaire

### ABS_T (Valeur Absolue Ternaire)
- **Format:** `ABS_T Rd, Rs1`
- **Description:** Calcule la valeur absolue ternaire de Rs1
- **Résultat:**
  - Si Rs1 est négatif, inverse tous les trits
  - Si Rs1 est positif ou zéro, copie directe
- **Implémentation:** Test du signe + TINV conditionnel

### SIGNUM_T (Extraction de Signe Ternaire)
- **Format:** `SIGNUM_T Rd, Rs1`
- **Description:** Extrait le signe de Rs1 sous forme ternaire
- **Résultat:**
  - Rd = TRIT_N (-1) si Rs1 < 0
  - Rd = TRIT_Z (0) si Rs1 = 0
  - Rd = TRIT_P (+1) si Rs1 > 0
- **Implémentation:** Analyse du signe et génération du trit résultat

## Manipulation de Trytes

### EXTRACT_TRYTE
- **Format:** `EXTRACT_TRYTE Rd, Rs1, index`
- **Description:** Extrait un tryte spécifique de Rs1
- **Résultat:** Le tryte à la position index est placé dans les trits de poids faible de Rd
- **Implémentation:** Décalage et masquage des bits

### INSERT_TRYTE
- **Format:** `INSERT_TRYTE Rd, Rs1, index, Rs_tryte`
- **Description:** Insère un tryte dans Rs1 à la position spécifiée
- **Résultat:** Copie de Rs1 avec le tryte remplacé à la position index
- **Implémentation:** Masquage et combinaison de bits

## Encodage des Instructions

Toutes les nouvelles instructions suivent le format R standard de PrismChrono avec des champs d'opcode et funct3/funct7 spécifiques:

```
TCMP3:        opcode=0x33, funct3=0x1, funct7=0x20
ABS_T:        opcode=0x33, funct3=0x2, funct7=0x20
SIGNUM_T:     opcode=0x33, funct3=0x3, funct7=0x20
EXTRACT_TRYTE: opcode=0x33, funct3=0x4, funct7=0x20
INSERT_TRYTE:  opcode=0x33, funct3=0x5, funct7=0x20
```

## Impact sur le Pipeline

Toutes ces instructions sont exécutées en un seul cycle dans l'étage EX, utilisant l'ALU étendue ou des unités de manipulation de trytes dédiées. Elles suivent le même chemin de données que les instructions ALU standard, avec des signaux de contrôle spécifiques pour sélectionner l'opération appropriée.

## Avantages de l'Architecture Ternaire

Ces instructions tirent parti de la nature ternaire de l'architecture pour:
- Comparaisons directes à trois voies (TCMP3)
- Manipulation efficace des signes (ABS_T, SIGNUM_T)
- Opérations naturelles sur les trytes

Elles simplifient le code assembleur en remplaçant des séquences d'instructions binaires par des opérations ternaires directes.