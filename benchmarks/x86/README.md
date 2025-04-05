# Benchmarks x86 (C/Rust)

Ce répertoire contient les implémentations en C ou Rust des benchmarks pour l'architecture binaire de référence (x86_64).

## Benchmarks Standards

- `sum_array.c` / `sum_array.rs` : Calcul de la somme des éléments d'un tableau d'entiers
- `memcpy.c` / `memcpy.rs` : Copie d'un bloc de mémoire d'une zone source vers une zone destination
- `factorial.c` / `factorial.rs` : Calcul itératif de la factorielle d'un nombre
- `linear_search.c` / `linear_search.rs` : Recherche de la première occurrence d'une valeur dans un tableau
- `insertion_sort.c` / `insertion_sort.rs` : Tri d'un petit tableau d'entiers par insertion
- `function_call.c` / `function_call.rs` : Test d'appel de fonction simple

## Benchmarks Spécifiques Ternaires

- `ternary_logic.c` / `ternary_logic.rs` : Implémentation d'un système de vote ou de logique tri-valuée
- `special_states.c` / `special_states.rs` : Traitement d'un tableau avec des valeurs spéciales (NULL, NaN)
- `base24_arithmetic.c` / `base24_arithmetic.rs` : Calculs exploitant la base 24 ou la symétrie

## Convention d'implémentation

Chaque benchmark doit :
1. Initialiser les données de test de manière identique à la version PrismChrono
2. Implémenter l'algorithme de manière équivalente
3. Retourner ou stocker le résultat final de manière à pouvoir le vérifier
4. Être compilé avec des options standard (ex: `-O2` pour gcc/clang)

## Compilation et exécution

Utiliser les scripts fournis dans le répertoire `../scripts/` pour compiler et exécuter les benchmarks, ainsi que pour collecter les métriques via `perf`, `size`, et autres outils.