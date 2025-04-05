# Résultats des Benchmarks

Ce répertoire contient les données brutes collectées et les graphiques générés lors de l'exécution des benchmarks comparatifs entre PrismChrono et l'architecture binaire de référence.

## Structure

- `raw/` : Données brutes collectées au format CSV/JSON
  - `prismchrono/` : Métriques collectées pour les benchmarks PrismChrono
  - `x86/` : Métriques collectées pour les benchmarks x86
  - `combined/` : Métriques combinées des deux plateformes

- `graphs/` : Graphiques générés à partir des données brutes
  - `instructions/` : Comparaisons du nombre d'instructions
  - `memory_access/` : Comparaisons des accès mémoire
  - `code_size/` : Comparaisons de la taille du code
  - `branches/` : Comparaisons du nombre de branches
  - `ratios/` : Comparaisons des ratios dérivés

- `reports/` : Rapports d'analyse générés
  - `benchmark_results_v1.md` : Rapport initial d'analyse comparative

## Interprétation des résultats

Les résultats doivent être interprétés avec prudence, en tenant compte des différences fondamentales entre les architectures comparées :

1. PrismChrono est simulé, tandis que x86 est exécuté nativement
2. PrismChrono utilise une base ternaire équilibrée, tandis que x86 utilise une base binaire
3. Les compilateurs pour x86 sont hautement optimisés, contrairement à l'assemblage manuel pour PrismChrono

L'objectif n'est pas de comparer la vitesse d'exécution brute, mais d'évaluer les caractéristiques architecturales (nombre d'instructions, taille du code, accès mémoire) pour des tâches identiques.