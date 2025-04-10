# Encodage Binaire et Types de Données pour PrismChrono VHDL

## Introduction

Ce document décrit l'encodage binaire utilisé pour représenter les valeurs ternaires dans l'implémentation VHDL du projet PrismChrono. L'architecture PrismChrono utilise une logique ternaire équilibrée ({N, Z, P}) qui est simulée sur du matériel binaire (FPGA) en utilisant un encodage spécifique.

## Encodage Binaire des Trits

Chaque trit (chiffre ternaire) est encodé sur 2 bits selon le mapping suivant :

| Valeur Ternaire | Symbole | Valeur Entière | Encodage Binaire |
|-----------------|---------|----------------|------------------|
| Négatif         | N       | -1             | `00`             |
| Zéro            | Z       | 0              | `01`             |
| Positif         | P       | 1              | `10`             |

L'encodage `11` n'est pas utilisé dans les opérations normales et est considéré comme une valeur invalide. Dans les fonctions de conversion, cette valeur est traitée comme 0 (Z) par défaut.

## Types de Données Définis

Le package `prismchrono_types_pkg.vhd` définit les types suivants :

### EncodedTrit

```vhdl
subtype EncodedTrit is std_logic_vector(1 downto 0);
```

Ce type représente un seul trit encodé sur 2 bits. Les constantes suivantes sont définies pour faciliter l'utilisation :

```vhdl
constant TRIT_N : EncodedTrit := "00"; -- Négatif (-1)
constant TRIT_Z : EncodedTrit := "01"; -- Zéro (0)
constant TRIT_P : EncodedTrit := "10"; -- Positif (+1)
```

### EncodedTryte

```vhdl
subtype EncodedTryte is std_logic_vector(5 downto 0);
```

Ce type représente un tryte, composé de 3 trits (3 × 2 bits = 6 bits). Un tryte peut représenter des valeurs dans la plage [-13, 13] en utilisant l'arithmétique ternaire équilibrée.

### EncodedWord

```vhdl
subtype EncodedWord is std_logic_vector(47 downto 0);
```

Ce type représente un mot ternaire complet, composé de 24 trits (24 × 2 bits = 48 bits). C'est l'unité de base pour les opérations de l'ALU et les registres du CPU.

### EncodedAddress

```vhdl
subtype EncodedAddress is std_logic_vector(31 downto 0);
```

Ce type représente une adresse mémoire, composée de 16 trits (16 × 2 bits = 32 bits).

## Fonctions de Conversion

Le package définit également deux fonctions essentielles pour la conversion entre les trits encodés et les valeurs entières :

### to_integer

```vhdl
function to_integer(t: EncodedTrit) return integer;
```

Cette fonction convertit un trit encodé en sa valeur entière correspondante (-1, 0, ou 1). Pour l'encodage non utilisé `11`, la fonction retourne 0 par défaut.

### to_encoded_trit

```vhdl
function to_encoded_trit(i: integer) return EncodedTrit;
```

Cette fonction convertit une valeur entière en son trit encodé correspondant. Les valeurs négatives sont converties en `TRIT_N`, les valeurs positives en `TRIT_P`, et zéro en `TRIT_Z`.

## Utilisation dans l'Arithmétique Ternaire

Cet encodage est utilisé dans tous les modules du projet, notamment dans :

1. **L'inverseur ternaire** (`trit_inverter.vhd`) : Inverse la valeur d'un trit (N→P, P→N, Z→Z).
2. **L'additionneur complet 1-trit** (`ternary_full_adder_1t.vhd`) : Effectue l'addition de trois trits avec gestion de la retenue.

Ces modules forment la base de l'ALU ternaire qui sera développée dans les sprints suivants.

## Avantages de l'Encodage Choisi

1. **Simplicité** : L'encodage sur 2 bits est simple à comprendre et à implémenter.
2. **Efficacité** : Utilise efficacement les ressources binaires disponibles sur le FPGA.
3. **Symétrie** : Maintient la symétrie de l'arithmétique ternaire équilibrée.
4. **Extensibilité** : Peut être facilement étendu pour des structures de données plus complexes.

## Conclusion

L'encodage binaire des trits défini dans ce document est fondamental pour l'implémentation VHDL du projet PrismChrono. Il permet de simuler efficacement la logique ternaire sur du matériel binaire tout en préservant les avantages de l'arithmétique ternaire équilibrée.