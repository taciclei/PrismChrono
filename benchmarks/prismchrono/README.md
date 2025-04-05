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

- `ternary_logic.s` : Implémentation d'un système de vote ou de logique tri-valuée
- `special_states.s` : Traitement d'un tableau avec des valeurs spéciales (NULL, NaN)
- `base24_arithmetic.s` : Calculs exploitant la base 24 ou la symétrie

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