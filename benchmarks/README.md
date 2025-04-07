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

1. **Ternary Logic** : Implémentation d'un système de vote à trois états
2. **TVPU Operations** : Évaluation des performances des instructions vectorielles ternaires
3. **Branch3 Predictor** : Évaluation des performances du prédicteur de branchement ternaire avancé
4. **Special States** : Traitement d'un tableau avec des valeurs spéciales (NULL, NaN)
5. **Base24 Arithmetic** : Calculs exploitant la base 24 ou la symétrie
6. **Trit Operations** : Opérations spécialisées trit par trit (TMIN, TMAX, TSUM, TCMP3)
7. **Branch3 Decision** : Prise de décision avec branchement ternaire (BRANCH3)
8. **Compact Format** : Comparaison entre format standard et format compact
9. **Optimized Memory** : Accès mémoire optimisés avec LOADT3/STORET3 et LOADTM/STORETM
10. **Ternary Signal Processing** : Traitement de signal optimisé avec instructions TFFT et TFILTER
11. **Quantum Simulation** : Simulation quantique avec instructions TQBIT et TQGATE
12. **Ternary Cryptography** : Opérations cryptographiques avec instructions TSHA3, TAES et TRNG
13. **Neural Network Ternary** : Réseaux de neurones avec instructions TNEURON, TCONV2D et TATTN
14. **Predictive Cache** : Accès mémoire avec cache prédictif ternaire à trois niveaux de confiance
15. **Ternary Data Compression** : Compression et décompression de données avec instructions TCOMPRESS et TDECOMPRESS

## Métriques Mesurées

- Nombre d'instructions exécutées
- Taille du code
- Nombre de lectures mémoire
- Nombre d'écritures mémoire
- Nombre de branches
- Ratios dérivés (Instructions/Accès Mémoire, etc.)

## Utilisation

Consultez le fichier `scripts/README.md` pour les instructions d'exécution des benchmarks et de génération des rapports.