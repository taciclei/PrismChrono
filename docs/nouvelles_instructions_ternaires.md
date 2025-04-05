# Nouvelles Instructions Ternaires pour PrismChrono

## Introduction

Ce document détaille les nouvelles instructions ternaires proposées pour l'architecture PrismChrono, conçues pour exploiter pleinement les avantages de la logique ternaire et améliorer les performances dans les domaines identifiés comme points forts dans les benchmarks comparatifs.

## 1. Instructions de Manipulation de Trits

### 1.1 Instructions Ternaires Spécialisées

| Instruction | Format | Description | Opération |
|-------------|--------|-------------|------------|
| `TMIN Rd, Rs1, Rs2` | R | Minimum ternaire (par trit) | Pour chaque trit i: Rd[i] = min(Rs1[i], Rs2[i]) |
| `TMAX Rd, Rs1, Rs2` | R | Maximum ternaire (par trit) | Pour chaque trit i: Rd[i] = max(Rs1[i], Rs2[i]) |
| `TSUM Rd, Rs1, Rs2` | R | Somme ternaire (par trit) | Pour chaque trit i: Rd[i] = Rs1[i] + Rs2[i] (sans propagation) |
| `TCMP3 Rd, Rs1, Rs2` | R | Comparaison ternaire à 3 états | Pour chaque trit i: Rd[i] = -1 si Rs1[i] < Rs2[i], 0 si Rs1[i] = Rs2[i], 1 si Rs1[i] > Rs2[i] |

### 1.2 Instructions de Rotation et Décalage Ternaires

| Instruction | Format | Description | Opération |
|-------------|--------|-------------|------------|
| `TROTL Rd, Rs1, imm` | I | Rotation ternaire à gauche | Rd = Rs1 rotationné à gauche de imm positions |
| `TROTR Rd, Rs1, imm` | I | Rotation ternaire à droite | Rd = Rs1 rotationné à droite de imm positions |
| `TSHIFTL Rd, Rs1, imm` | I | Décalage ternaire à gauche | Rd = Rs1 décalé à gauche de imm positions, rempli de zéros |
| `TSHIFTR Rd, Rs1, imm` | I | Décalage ternaire à droite | Rd = Rs1 décalé à droite de imm positions, rempli de zéros |

## 2. Instructions de Branchement Ternaire

### 2.1 Branchement Ternaire

| Instruction | Format | Description | Opération |
|-------------|--------|-------------|------------|
| `BRANCH3 Rs1, offset_neg, offset_zero, offset_pos` | B3 | Branchement basé sur une condition ternaire | Si Rs1 < 0: PC += offset_neg*4<br>Si Rs1 = 0: PC += offset_zero*4<br>Si Rs1 > 0: PC += offset_pos*4 |

## 3. Instructions d'Accès Mémoire Optimisées

### 3.1 Instructions de Chargement/Stockage Spécialisées

| Instruction | Format | Description | Opération |
|-------------|--------|-------------|------------|
| `LOADT3 Rd, imm(Rs1)` | I | Charge 3 trytes consécutifs | Rd[0..2] = Mem[Rs1+imm..Rs1+imm+2] |
| `STORET3 Rs2, imm(Rs1)` | S | Stocke 3 trytes consécutifs | Mem[Rs1+imm..Rs1+imm+2] = Rs2[0..2] |
| `LOADTM Rd, mask, imm(Rs1)` | I | Charge un masque de trytes | Pour chaque bit i dans mask: si bit=1, Rd[i] = Mem[Rs1+imm+i] |
| `STORETM Rs2, mask, imm(Rs1)` | S | Stocke un masque de trytes | Pour chaque bit i dans mask: si bit=1, Mem[Rs1+imm+i] = Rs2[i] |

### 3.2 Instructions de Manipulation Mémoire Ternaire

| Instruction | Format | Description | Opération |
|-------------|--------|-------------|------------|
| `TMEMCPY Rd, Rs1, Rs2` | R | Copie mémoire optimisée | Copie Rs2 trytes de Rs1 vers Rd |
| `TMEMSET Rd, Rs1, Rs2` | R | Initialisation mémoire | Initialise Rs2 trytes à partir de Rd avec la valeur Rs1 |

## 4. Format d'Instruction Compact

### 4.1 Instructions Compactes (8 trits)

| Instruction | Format | Description | Opération |
|-------------|--------|-------------|------------|
| `CMOV Rd, Rs` | C | Copie registre (format compact) | Rd = Rs |
| `CADD Rd, Rs` | C | Addition (format compact) | Rd += Rs |
| `CSUB Rd, Rs` | C | Soustraction (format compact) | Rd -= Rs |
| `CBRANCH cond, offset` | C | Branchement (format compact) | Si condition vraie: PC += offset*4 |

## 5. Instructions Multi-opérations

| Instruction | Format | Description | Opération |
|-------------|--------|-------------|------------|
| `MADDW Rd, Rs1, Rs2, Rs3` | R4 | Multiplication-Addition | Rd = Rs1 * Rs2 + Rs3 |
| `MSUBW Rd, Rs1, Rs2, Rs3` | R4 | Multiplication-Soustraction | Rd = Rs1 * Rs2 - Rs3 |

## 6. Instructions pour États Spéciaux

### 6.1 Instructions pour Valeurs Spéciales

| Instruction | Format | Description | Opération |
|-------------|--------|-------------|------------|
| `ISNULL Rd, Rs1` | R | Teste si un registre contient NULL | Rd = 1 si Rs1 contient NULL, sinon 0 |
| `ISNAN Rd, Rs1` | R | Teste si un registre contient NaN | Rd = 1 si Rs1 contient NaN, sinon 0 |
| `ISUNDEF Rd, Rs1` | R | Teste si un registre contient UNDEF | Rd = 1 si Rs1 contient UNDEF, sinon 0 |
| `SETNULL Rd` | R | Définit un registre à NULL | Rd = NULL |
| `SETNAN Rd` | R | Définit un registre à NaN | Rd = NaN |
| `SETUNDEF Rd` | R | Définit un registre à UNDEF | Rd = UNDEF |

### 6.2 Opérations Conditionnelles Ternaires

| Instruction | Format | Description | Opération |
|-------------|--------|-------------|------------|
| `TSEL Rd, Rs1, Rs2, Rs3` | R4 | Sélection ternaire | Si Rs1 < 0: Rd = Rs2<br>Si Rs1 = 0: Rd = Rs3<br>Si Rs1 > 0: Rd = Rs2 + Rs3 |

## 7. Instructions Arithmétiques Base 24

| Instruction | Format | Description | Opération |
|-------------|--------|-------------|------------|
| `ADDB24 Rd, Rs1, Rs2` | R | Addition en base 24 | Rd = Rs1 + Rs2 (en base 24) |
| `SUBB24 Rd, Rs1, Rs2` | R | Soustraction en base 24 | Rd = Rs1 - Rs2 (en base 24) |
| `MULB24 Rd, Rs1, Rs2` | R | Multiplication en base 24 | Rd = Rs1 * Rs2 (en base 24) |
| `DIVB24 Rd, Rs1, Rs2` | R | Division en base 24 | Rd = Rs1 / Rs2 (en base 24) |
| `CVTB24 Rd, Rs1` | R | Conversion en base 24 | Rd = conversion de Rs1 en base 24 |
| `CVTFRB24 Rd, Rs1` | R | Conversion depuis la base 24 | Rd = conversion de Rs1 depuis la base 24 |

## Nouveaux Formats d'Instructions

### Format B3 (Branchement Ternaire)

```
+-------+-------+-------+-------+
| Opcode|  Rs1  |offset_n|offset_z|
+-------+-------+-------+-------+
|offset_p|  xxx  |  xxx  |  xxx  |
+-------+-------+-------+-------+
```

### Format C (Compact, 8 trits)

```
+-------+-------+
| Opcode|  Rd   |
+-------+-------+
|  Rs   |  xxx  |
+-------+-------+
```

### Format R4 (4 registres)

```
+-------+-------+-------+-------+
| Opcode|  Rd   |  Rs1  |  Rs2  |
+-------+-------+-------+-------+
|  Rs3  |  xxx  |  xxx  |  xxx  |
+-------+-------+-------+-------+
```

## Impact sur les Performances

L'ajout de ces nouvelles instructions devrait avoir un impact significatif sur les performances de l'architecture PrismChrono :

1. **Réduction du nombre d'instructions** : Les instructions spécialisées ternaires et multi-opérations permettront d'effectuer en une seule instruction ce qui nécessitait auparavant plusieurs instructions.

2. **Amélioration de la densité de code** : Le format d'instruction compact réduira la taille du code exécutable, améliorant ainsi la densité de code.

3. **Réduction des branches** : Les instructions de branchement ternaire permettront de réduire le nombre de branches nécessaires, améliorant ainsi les performances dans ce domaine.

4. **Optimisation des accès mémoire** : Les instructions spécialisées pour la mémoire réduiront le nombre d'opérations mémoire nécessaires.

5. **Exploitation des avantages ternaires** : Les instructions pour les états spéciaux et la base 24 exploiteront pleinement les avantages de l'architecture ternaire.

## Conclusion

Ces nouvelles instructions ternaires constituent une extension significative du jeu d'instructions PrismChrono, visant à exploiter pleinement le potentiel de l'architecture ternaire. Leur implémentation devrait permettre d'améliorer considérablement les performances de PrismChrono par rapport à l'architecture binaire x86, particulièrement dans les domaines où l'architecture ternaire présente déjà des avantages.

La prochaine étape consistera à implémenter ces instructions dans le simulateur PrismChrono et à effectuer une nouvelle campagne de benchmarking pour valider leur impact réel sur les performances.