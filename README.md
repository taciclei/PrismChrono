# Projet PrismChrono

PrismChrono est un projet d'architecture ternaire innovante, utilisant une logique à trois états (ternaire) au lieu de la logique binaire traditionnelle. Ce projet comprend un simulateur et un assembleur pour cette architecture unique.

## Composants du projet

### PrismChrono Simulateur

Le simulateur permet d'exécuter du code machine ternaire et de simuler le comportement du processeur PrismChrono.

[Voir la documentation du simulateur](./prismChrono_sim/README.md)

### PrismChrono Assembleur

L'assembleur permet de traduire du code assembleur PrismChrono en code machine ternaire exécutable par le simulateur.

[Voir la documentation de l'assembleur](./prismchrono_asm/README.md)

## Caractéristiques de l'Architecture

- **Type**: Architecture Logic GPR Base-24 Ternaire +
- **Taille de mot**: 24 Trits (8 Trytes)
- **Mémoire adressable**: 16 MTrytes
- **Endianness**: Little-Endian
- **Registres**: 8 registres généraux (R0-R7)

## Types de Données Ternaires

### Trit

Le Trit est l'unité fondamentale de l'architecture ternaire, équivalent au bit dans les systèmes binaires. Il peut prendre trois valeurs :

- **N** : -1 (Négatif)
- **Z** : 0 (Zéro)
- **P** : +1 (Positif)

### Tryte

Un Tryte est composé de 3 Trits et peut représenter des valeurs numériques de -13 à +13 en ternaire équilibré.

### Word

Un Word est composé de 8 Trytes (24 Trits) et représente la taille standard des données manipulées par le processeur.

## Utilisation

Pour utiliser le projet PrismChrono :

1. Écrire un programme en assembleur PrismChrono (fichier `.s`)
2. Assembler le programme avec l'assembleur PrismChrono pour obtenir un fichier `.tobj`
3. Exécuter le fichier `.tobj` avec le simulateur PrismChrono

## Développement

Ce projet est en cours de développement. Consultez les dossiers `sprints/` et `docs/` pour plus d'informations sur l'état d'avancement et les fonctionnalités prévues.