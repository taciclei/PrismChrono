# Rapport de Benchmarking Comparatif PrismChrono vs x86
*Généré le 06/04/2025 à 03:10:13*

## Introduction
Ce rapport présente une analyse comparative des performances entre l'architecture ternaire PrismChrono et l'architecture binaire x86. 
Les benchmarks ont été exécutés sur les deux plateformes et les métriques ont été collectées pour permettre une comparaison directe.

## Résumé des Résultats
**Nombre total de benchmarks:** 15
**Benchmarks standard:** 6
**Benchmarks spécifiques ternaires:** 9

### Ratios Moyens PrismChrono/x86
Le graphique ci-dessous présente les ratios moyens des métriques clés entre PrismChrono et x86, par catégorie de benchmark:

![Ratios Moyens](../graphs/summary_ratios_latest.png)

### Tableau des Ratios Moyens
| Métrique | Tous | Standard | Ternaire Spécifique |
| --- | ---: | ---: | ---: |
| Nombre d'instructions exécutées | 0.7048 | 0.0000 | 0.7048 |
| Taille du code exécutable | 0.7162 | 0.0000 | 0.7162 |
| Nombre de lectures mémoire | 0.5864 | 0.0000 | 0.5864 |
| Nombre d'écritures mémoire | 0.6157 | 0.0000 | 0.6157 |
| Nombre de branches | 0.7396 | 0.0000 | 0.7396 |
| Nombre de branches prises | 0.8513 | 0.0000 | 0.8513 |
| inst_mem_ratio | 1.2001 | 0.0000 | 1.2001 |
| inst_branch_ratio | 1.0301 | 0.0000 | 1.0301 |
| branch_taken_ratio | 1.4158 | 0.0000 | 1.4158 |
| code_density | 0.9807 | 0.0000 | 0.9807 |

> Note: Un ratio < 1 indique que PrismChrono est plus performant que x86 pour cette métrique.
> Un ratio > 1 indique que x86 est plus performant que PrismChrono.

## Analyse par Catégorie de Benchmark
### Benchmarks Standard
Les benchmarks standard permettent d'évaluer les performances générales de l'architecture PrismChrono par rapport à x86 sur des tâches communes.

| Benchmark | Description | Ratio Inst | Ratio Mem Ops | Ratio Code Size |
| --- | --- | ---: | ---: | ---: |
| sum_array | Calcul de la somme des éléments d'un tableau d'entiers | 0.0000 | 0.0000 | 0.0000 |
| memcpy | Copie d'un bloc de mémoire d'une zone source vers une zone destination | 0.0000 | 0.0000 | 0.0000 |
| factorial | Calcul itératif de la factorielle d'un nombre | 0.0000 | 0.0000 | 0.0000 |
| linear_search | Recherche de la première occurrence d'une valeur dans un tableau | inf | inf | inf |
| insertion_sort | Tri d'un petit tableau d'entiers par insertion | inf | inf | inf |
| function_call | Test d'appel de fonction simple | inf | inf | inf |

#### Graphiques des Benchmarks Standard
**Nombre d'instructions exécutées:**
![instruction_count](../graphs/instruction_count_standard_latest.png)

**Taille du code exécutable:**
![code_size](../graphs/code_size_standard_latest.png)

**Nombre de lectures mémoire:**
![memory_reads](../graphs/memory_reads_standard_latest.png)

### Benchmarks Ternaires Spécifiques
Les benchmarks ternaires spécifiques sont conçus pour mettre en évidence les avantages potentiels de l'architecture ternaire dans des cas d'utilisation particuliers.

| Benchmark | Description | Ratio Inst | Ratio Mem Ops | Ratio Code Size |
| --- | --- | ---: | ---: | ---: |
| ternary_logic | Implémentation d'un système de vote à trois états | 0.0000 | 0.0000 | 0.0000 |
| tvpu_operations | Évaluation des performances des instructions vectorielles ternaires | 0.0000 | 0.0000 | 0.0000 |
| branch3_predictor | Évaluation des performances du prédicteur de branchement ternaire avancé | 0.0000 | 0.0000 | 0.0000 |
| special_states | Traitement d'un tableau avec des valeurs spéciales (NULL, NaN) | inf | inf | inf |
| base24_arithmetic | Calculs exploitant la base 24 ou la symétrie | inf | inf | inf |
| trit_operations | Opérations spécialisées trit par trit (TMIN, TMAX, TSUM, TCMP3) | 0.8045 | 0.6015 | 0.7478 |
| branch3_decision | Prise de décision avec branchement ternaire (BRANCH3) | 0.4686 | 0.6598 | 0.5988 |
| compact_format | Comparaison entre format standard et format compact | 0.8018 | 0.5826 | 0.6838 |
| optimized_memory | Accès mémoire optimisés avec LOADT3/STORET3 et LOADTM/STORETM | 0.7442 | 0.5603 | 0.8343 |

#### Graphiques des Benchmarks Ternaires Spécifiques
**Nombre d'instructions exécutées:**
![instruction_count](../graphs/instruction_count_ternary_specific_latest.png)

**Taille du code exécutable:**
![code_size](../graphs/code_size_ternary_specific_latest.png)

**Nombre de lectures mémoire:**
![memory_reads](../graphs/memory_reads_ternary_specific_latest.png)

## Analyse des Métriques Dérivées
Les métriques dérivées permettent d'évaluer l'efficacité relative des architectures au-delà des métriques brutes.

### Description des Métriques Dérivées
| Métrique | Description |
| --- | --- |
| inst_mem_ratio | Ratio Instructions / Opérations Mémoire - Mesure l'efficacité des instructions par rapport aux accès mémoire |
| inst_branch_ratio | Ratio Instructions / Branches - Mesure la densité des branchements dans le code |
| branch_taken_ratio | Ratio Branches Prises / Total Branches - Mesure l'efficacité de la prédiction de branchement |
| code_density | Densité du Code (Instructions / Taille) - Mesure l'efficacité de l'encodage des instructions |

### Graphiques des Métriques Dérivées
**inst_mem_ratio:**
![inst_mem_ratio](../graphs/inst_mem_ratio_all_latest.png)

**inst_branch_ratio:**
![inst_branch_ratio](../graphs/inst_branch_ratio_all_latest.png)

**branch_taken_ratio:**
![branch_taken_ratio](../graphs/branch_taken_ratio_all_latest.png)

**code_density:**
![code_density](../graphs/code_density_all_latest.png)

## Analyse Détaillée par Benchmark
### sum_array (Standard)
*Calcul de la somme des éléments d'un tableau d'entiers*

| Métrique | PrismChrono | x86 | Ratio |
| --- | ---: | ---: | ---: |
| Nombre d'instructions exécutées | 0 | 0 | 0.0000 |
| Taille du code exécutable | 0 | 0 | 0.0000 |
| Nombre de lectures mémoire | 0 | 0 | 0.0000 |
| Nombre d'écritures mémoire | 0 | 0 | 0.0000 |
| Nombre de branches | 0 | 0 | 0.0000 |
| Nombre de branches prises | 0 | 0 | 0.0000 |
| inst_mem_ratio | 0.0000 | 0.0000 | 0.0000 |
| inst_branch_ratio | 0.0000 | 0.0000 | 0.0000 |
| branch_taken_ratio | 0.0000 | 0.0000 | 0.0000 |
| code_density | 0.0000 | 0.0000 | 0.0000 |

### memcpy (Standard)
*Copie d'un bloc de mémoire d'une zone source vers une zone destination*

| Métrique | PrismChrono | x86 | Ratio |
| --- | ---: | ---: | ---: |
| Nombre d'instructions exécutées | 0 | 0 | 0.0000 |
| Taille du code exécutable | 0 | 0 | 0.0000 |
| Nombre de lectures mémoire | 0 | 0 | 0.0000 |
| Nombre d'écritures mémoire | 0 | 0 | 0.0000 |
| Nombre de branches | 0 | 0 | 0.0000 |
| Nombre de branches prises | 0 | 0 | 0.0000 |
| inst_mem_ratio | 0.0000 | 0.0000 | 0.0000 |
| inst_branch_ratio | 0.0000 | 0.0000 | 0.0000 |
| branch_taken_ratio | 0.0000 | 0.0000 | 0.0000 |
| code_density | 0.0000 | 0.0000 | 0.0000 |

### factorial (Standard)
*Calcul itératif de la factorielle d'un nombre*

| Métrique | PrismChrono | x86 | Ratio |
| --- | ---: | ---: | ---: |
| Nombre d'instructions exécutées | 0 | 0 | 0.0000 |
| Taille du code exécutable | 0 | 0 | 0.0000 |
| Nombre de lectures mémoire | 0 | 0 | 0.0000 |
| Nombre d'écritures mémoire | 0 | 0 | 0.0000 |
| Nombre de branches | 0 | 0 | 0.0000 |
| Nombre de branches prises | 0 | 0 | 0.0000 |
| inst_mem_ratio | 0.0000 | 0.0000 | 0.0000 |
| inst_branch_ratio | 0.0000 | 0.0000 | 0.0000 |
| branch_taken_ratio | 0.0000 | 0.0000 | 0.0000 |
| code_density | 0.0000 | 0.0000 | 0.0000 |

### linear_search (Standard)
*Recherche de la première occurrence d'une valeur dans un tableau*

| Métrique | PrismChrono | x86 | Ratio |
| --- | ---: | ---: | ---: |
| Nombre d'instructions exécutées | 1015 | 0 | inf |
| Taille du code exécutable | 351 | 0 | inf |
| Nombre de lectures mémoire | 227 | 0 | inf |
| Nombre d'écritures mémoire | 187 | 0 | inf |
| Nombre de branches | 58 | 0 | inf |
| Nombre de branches prises | 50 | 0 | inf |
| inst_mem_ratio | 2.4517 | 0.0000 | inf |
| inst_branch_ratio | 17.5000 | 0.0000 | inf |
| branch_taken_ratio | 0.8621 | 0.0000 | inf |
| code_density | 2.8917 | 0.0000 | inf |

### insertion_sort (Standard)
*Tri d'un petit tableau d'entiers par insertion*

| Métrique | PrismChrono | x86 | Ratio |
| --- | ---: | ---: | ---: |
| Nombre d'instructions exécutées | 1291 | 0 | inf |
| Taille du code exécutable | 497 | 0 | inf |
| Nombre de lectures mémoire | 248 | 0 | inf |
| Nombre d'écritures mémoire | 122 | 0 | inf |
| Nombre de branches | 71 | 0 | inf |
| Nombre de branches prises | 30 | 0 | inf |
| inst_mem_ratio | 3.4892 | 0.0000 | inf |
| inst_branch_ratio | 18.1831 | 0.0000 | inf |
| branch_taken_ratio | 0.4225 | 0.0000 | inf |
| code_density | 2.5976 | 0.0000 | inf |

### function_call (Standard)
*Test d'appel de fonction simple*

| Métrique | PrismChrono | x86 | Ratio |
| --- | ---: | ---: | ---: |
| Nombre d'instructions exécutées | 1166 | 0 | inf |
| Taille du code exécutable | 537 | 0 | inf |
| Nombre de lectures mémoire | 231 | 0 | inf |
| Nombre d'écritures mémoire | 114 | 0 | inf |
| Nombre de branches | 68 | 0 | inf |
| Nombre de branches prises | 31 | 0 | inf |
| inst_mem_ratio | 3.3797 | 0.0000 | inf |
| inst_branch_ratio | 17.1471 | 0.0000 | inf |
| branch_taken_ratio | 0.4559 | 0.0000 | inf |
| code_density | 2.1713 | 0.0000 | inf |

### ternary_logic (Ternary_specific)
*Implémentation d'un système de vote à trois états*

| Métrique | PrismChrono | x86 | Ratio |
| --- | ---: | ---: | ---: |
| Nombre d'instructions exécutées | 0 | 0 | 0.0000 |
| Taille du code exécutable | 0 | 0 | 0.0000 |
| Nombre de lectures mémoire | 0 | 0 | 0.0000 |
| Nombre d'écritures mémoire | 0 | 0 | 0.0000 |
| Nombre de branches | 0 | 0 | 0.0000 |
| Nombre de branches prises | 0 | 0 | 0.0000 |
| inst_mem_ratio | 0.0000 | 0.0000 | 0.0000 |
| inst_branch_ratio | 0.0000 | 0.0000 | 0.0000 |
| branch_taken_ratio | 0.0000 | 0.0000 | 0.0000 |
| code_density | 0.0000 | 0.0000 | 0.0000 |

### tvpu_operations (Ternary_specific)
*Évaluation des performances des instructions vectorielles ternaires*

| Métrique | PrismChrono | x86 | Ratio |
| --- | ---: | ---: | ---: |
| Nombre d'instructions exécutées | 0 | 0 | 0.0000 |
| Taille du code exécutable | 0 | 0 | 0.0000 |
| Nombre de lectures mémoire | 0 | 0 | 0.0000 |
| Nombre d'écritures mémoire | 0 | 0 | 0.0000 |
| Nombre de branches | 0 | 0 | 0.0000 |
| Nombre de branches prises | 0 | 0 | 0.0000 |
| inst_mem_ratio | 0.0000 | 0.0000 | 0.0000 |
| inst_branch_ratio | 0.0000 | 0.0000 | 0.0000 |
| branch_taken_ratio | 0.0000 | 0.0000 | 0.0000 |
| code_density | 0.0000 | 0.0000 | 0.0000 |

### branch3_predictor (Ternary_specific)
*Évaluation des performances du prédicteur de branchement ternaire avancé*

| Métrique | PrismChrono | x86 | Ratio |
| --- | ---: | ---: | ---: |
| Nombre d'instructions exécutées | 0 | 0 | 0.0000 |
| Taille du code exécutable | 0 | 0 | 0.0000 |
| Nombre de lectures mémoire | 0 | 0 | 0.0000 |
| Nombre d'écritures mémoire | 0 | 0 | 0.0000 |
| Nombre de branches | 0 | 0 | 0.0000 |
| Nombre de branches prises | 0 | 0 | 0.0000 |
| inst_mem_ratio | 0.0000 | 0.0000 | 0.0000 |
| inst_branch_ratio | 0.0000 | 0.0000 | 0.0000 |
| branch_taken_ratio | 0.0000 | 0.0000 | 0.0000 |
| code_density | 0.0000 | 0.0000 | 0.0000 |

### special_states (Ternary_specific)
*Traitement d'un tableau avec des valeurs spéciales (NULL, NaN)*

| Métrique | PrismChrono | x86 | Ratio |
| --- | ---: | ---: | ---: |
| Nombre d'instructions exécutées | 834 | 0 | inf |
| Taille du code exécutable | 340 | 0 | inf |
| Nombre de lectures mémoire | 180 | 0 | inf |
| Nombre d'écritures mémoire | 118 | 0 | inf |
| Nombre de branches | 74 | 0 | inf |
| Nombre de branches prises | 31 | 0 | inf |
| inst_mem_ratio | 2.7987 | 0.0000 | inf |
| inst_branch_ratio | 11.2703 | 0.0000 | inf |
| branch_taken_ratio | 0.4189 | 0.0000 | inf |
| code_density | 2.4529 | 0.0000 | inf |

### base24_arithmetic (Ternary_specific)
*Calculs exploitant la base 24 ou la symétrie*

| Métrique | PrismChrono | x86 | Ratio |
| --- | ---: | ---: | ---: |
| Nombre d'instructions exécutées | 870 | 0 | inf |
| Taille du code exécutable | 408 | 0 | inf |
| Nombre de lectures mémoire | 207 | 0 | inf |
| Nombre d'écritures mémoire | 134 | 0 | inf |
| Nombre de branches | 57 | 0 | inf |
| Nombre de branches prises | 39 | 0 | inf |
| inst_mem_ratio | 2.5513 | 0.0000 | inf |
| inst_branch_ratio | 15.2632 | 0.0000 | inf |
| branch_taken_ratio | 0.6842 | 0.0000 | inf |
| code_density | 2.1324 | 0.0000 | inf |

### trit_operations (Ternary_specific)
*Opérations spécialisées trit par trit (TMIN, TMAX, TSUM, TCMP3)*

| Métrique | PrismChrono | x86 | Ratio |
| --- | ---: | ---: | ---: |
| Nombre d'instructions exécutées | 650 | 808 | 0.8045 |
| Taille du code exécutable | 341 | 456 | 0.7478 |
| Nombre de lectures mémoire | 141 | 220 | 0.6409 |
| Nombre d'écritures mémoire | 86 | 153 | 0.5621 |
| Nombre de branches | 48 | 82 | 0.5854 |
| Nombre de branches prises | 33 | 47 | 0.7021 |
| inst_mem_ratio | 2.8634 | 2.1662 | 1.3219 |
| inst_branch_ratio | 13.5417 | 9.8537 | 1.3743 |
| branch_taken_ratio | 0.6875 | 0.5732 | 1.1994 |
| code_density | 1.9062 | 1.7719 | 1.0758 |

### branch3_decision (Ternary_specific)
*Prise de décision avec branchement ternaire (BRANCH3)*

| Métrique | PrismChrono | x86 | Ratio |
| --- | ---: | ---: | ---: |
| Nombre d'instructions exécutées | 552 | 1178 | 0.4686 |
| Taille du code exécutable | 312 | 521 | 0.5988 |
| Nombre de lectures mémoire | 165 | 248 | 0.6653 |
| Nombre d'écritures mémoire | 106 | 162 | 0.6543 |
| Nombre de branches | 37 | 89 | 0.4157 |
| Nombre de branches prises | 29 | 25 | 1.1600 |
| inst_mem_ratio | 2.0369 | 2.8732 | 0.7089 |
| inst_branch_ratio | 14.9189 | 13.2360 | 1.1271 |
| branch_taken_ratio | 0.7838 | 0.2809 | 2.7903 |
| code_density | 1.7692 | 2.2610 | 0.7825 |

### compact_format (Ternary_specific)
*Comparaison entre format standard et format compact*

| Métrique | PrismChrono | x86 | Ratio |
| --- | ---: | ---: | ---: |
| Nombre d'instructions exécutées | 878 | 1095 | 0.8018 |
| Taille du code exécutable | 346 | 506 | 0.6838 |
| Nombre de lectures mémoire | 158 | 269 | 0.5874 |
| Nombre d'écritures mémoire | 104 | 180 | 0.5778 |
| Nombre de branches | 69 | 60 | 1.1500 |
| Nombre de branches prises | 31 | 48 | 0.6458 |
| inst_mem_ratio | 3.3511 | 2.4388 | 1.3741 |
| inst_branch_ratio | 12.7246 | 18.2500 | 0.6972 |
| branch_taken_ratio | 0.4493 | 0.8000 | 0.5616 |
| code_density | 2.5376 | 2.1640 | 1.1726 |

### optimized_memory (Ternary_specific)
*Accès mémoire optimisés avec LOADT3/STORET3 et LOADTM/STORETM*

| Métrique | PrismChrono | x86 | Ratio |
| --- | ---: | ---: | ---: |
| Nombre d'instructions exécutées | 736 | 989 | 0.7442 |
| Taille du code exécutable | 423 | 507 | 0.8343 |
| Nombre de lectures mémoire | 127 | 281 | 0.4520 |
| Nombre d'écritures mémoire | 113 | 169 | 0.6686 |
| Nombre de branches | 67 | 83 | 0.8072 |
| Nombre de branches prises | 35 | 39 | 0.8974 |
| inst_mem_ratio | 3.0667 | 2.1978 | 1.3953 |
| inst_branch_ratio | 10.9851 | 11.9157 | 0.9219 |
| branch_taken_ratio | 0.5224 | 0.4699 | 1.1117 |
| code_density | 1.7400 | 1.9507 | 0.8920 |

## Conclusion
Cette analyse comparative entre PrismChrono et x86 met en évidence plusieurs points importants:

### Points Forts de PrismChrono
PrismChrono montre des avantages dans les métriques suivantes:
- **Nombre d'instructions exécutées**: Ratio moyen de 0.7048 (PrismChrono est 29.5% plus efficace)
- **Taille du code exécutable**: Ratio moyen de 0.7162 (PrismChrono est 28.4% plus efficace)
- **Nombre de lectures mémoire**: Ratio moyen de 0.5864 (PrismChrono est 41.4% plus efficace)
- **Nombre d'écritures mémoire**: Ratio moyen de 0.6157 (PrismChrono est 38.4% plus efficace)
- **Nombre de branches**: Ratio moyen de 0.7396 (PrismChrono est 26.0% plus efficace)
- **Nombre de branches prises**: Ratio moyen de 0.8513 (PrismChrono est 14.9% plus efficace)
- **code_density**: Ratio moyen de 0.9807 (PrismChrono est 1.9% plus efficace)

### Points à Améliorer
PrismChrono présente des performances inférieures dans les métriques suivantes:
- **inst_mem_ratio**: Ratio moyen de 1.2001 (PrismChrono est 20.0% moins efficace)
- **inst_branch_ratio**: Ratio moyen de 1.0301 (PrismChrono est 3.0% moins efficace)
- **branch_taken_ratio**: Ratio moyen de 1.4158 (PrismChrono est 41.6% moins efficace)

### Recommandations
Sur la base de cette analyse, voici quelques recommandations pour l'évolution de PrismChrono:

1. **Optimisation des Points Faibles**: Concentrer les efforts d'optimisation sur les métriques où PrismChrono est moins performant.
2. **Exploitation des Avantages Ternaires**: Développer davantage les cas d'utilisation où l'architecture ternaire montre des avantages significatifs.
3. **Benchmarks Supplémentaires**: Créer des benchmarks plus spécifiques pour mieux évaluer les avantages potentiels de l'architecture ternaire.
4. **Analyse Approfondie**: Examiner en détail les benchmarks où PrismChrono surpasse x86 pour comprendre les facteurs contribuant à cette performance supérieure.