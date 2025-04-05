# PrismChrono Benchmarks

Ce répertoire contient les benchmarks pour l'évaluation comparative de l'architecture PrismChrono par rapport à une architecture binaire standard (x86_64).

## Structure

- `prismchrono/` : Implémentations en assembleur PrismChrono (`.s`)
- `x86/` : Implémentations en C/Rust pour la référence binaire (`.c`/`.rs`)
- `scripts/` : Scripts d'exécution, de collecte de métriques et de visualisation
- `results/` : Données brutes collectées et graphiques générés

## Benchmarks Standards

1. **Sum Array** : Calcul de la somme des éléments d'un tableau d'entiers
2. **Memcpy** : Copie d'un bloc de mémoire d'une zone source vers une zone destination
3. **Factorial** : Calcul itératif de la factorielle d'un nombre
4. **Linear Search** : Recherche de la première occurrence d'une valeur dans un tableau
5. **Insertion Sort** : Tri d'un petit tableau d'entiers par insertion
6. **Function Call** : Test d'appel de fonction simple

## Benchmarks Spécifiques Ternaires

1. **Ternary Logic** : Implémentation d'un système de vote ou de logique tri-valuée
2. **Special States** : Traitement d'un tableau avec des valeurs spéciales (NULL, NaN)
3. **Base 24 Arithmetic** : Calculs exploitant la base 24 ou la symétrie
4. **Trit Operations** : Opérations spécialisées trit par trit (TMIN, TMAX, TSUM, TCMP3)
5. **Branch3 Decision** : Prise de décision avec branchement ternaire (BRANCH3)
6. **Compact Format** : Comparaison entre format standard et format compact
7. **Optimized Memory** : Accès mémoire optimisés avec LOADT3/STORET3 et LOADTM/STORETM

## Métriques Mesurées

- Nombre d'instructions exécutées
- Taille du code
- Nombre de lectures mémoire
- Nombre d'écritures mémoire
- Nombre de branches
- Ratios dérivés (Instructions/Accès Mémoire, etc.)

## Utilisation

Consultez le fichier `scripts/README.md` pour les instructions d'exécution des benchmarks et de génération des rapports.