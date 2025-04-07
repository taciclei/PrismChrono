# Benchmarks PrismChrono (Assembleur)

Ce répertoire contient les implémentations en assembleur PrismChrono des benchmarks standards et spécifiques.

## Benchmarks Standards

- `sum_array.s` : Calcul de la somme des éléments d'un tableau d'entiers
- `memcpy.s` : Copie d'un bloc de mémoire d'une zone source vers une zone destination
- `factorial.s` : Calcul itératif de la factorielle d'un nombre
- `linear_search.s` : Recherche de la première occurrence d'une valeur dans un tableau
- `insertion_sort.s` : Tri d'un petit tableau d'entiers par insertion
- `function_call.s` : Test d'appel de fonction simple

## Benchmarks Spécifiques Ternaires

- `ternary_logic.s` : Implémentation d'un système de vote à trois états
- `tvpu_operations.s` : Évaluation des performances des instructions vectorielles ternaires
- `branch3_predictor.s` : Évaluation des performances du prédicteur de branchement ternaire avancé
- `special_states.s` : Traitement d'un tableau avec des valeurs spéciales (NULL, NaN)
- `base24_arithmetic.s` : Calculs exploitant la base 24 ou la symétrie
- `trit_operations.s` : Opérations spécialisées trit par trit (TMIN, TMAX, TSUM, TCMP3)
- `branch3_decision.s` : Prise de décision avec branchement ternaire (BRANCH3)
- `compact_format.s` : Comparaison entre format standard et format compact
- `optimized_memory.s` : Accès mémoire optimisés avec LOADT3/STORET3 et LOADTM/STORETM
- `ternary_signal_processing.s` : Traitement de signal optimisé avec instructions TFFT et TFILTER
- `quantum_simulation.s` : Simulation quantique avec instructions TQBIT et TQGATE
- `ternary_cryptography.s` : Opérations cryptographiques avec instructions TSHA3, TAES et TRNG
- `neural_network_ternary.s` : Réseaux de neurones avec instructions TNEURON, TCONV2D et TATTN
- `predictive_cache.s` : Accès mémoire avec cache prédictif ternaire à trois niveaux de confiance
- `ternary_data_compression.s` : Compression et décompression de données avec instructions TCOMPRESS et TDECOMPRESS

## Convention d'implémentation

Chaque benchmark doit :
1. Initialiser les données de test de manière identique à la version x86
2. Implémenter l'algorithme de manière équivalente
3. Stocker le résultat final dans un emplacement mémoire prédéfini
4. Terminer par une instruction spéciale pour signaler la fin du benchmark

## Métriques collectées

Le simulateur PrismChrono collectera automatiquement les métriques suivantes :
- Nombre d'instructions exécutées
- Nombre de lectures/écritures mémoire
- Nombre de branches (totales et prises)
- Taille du code assemblé