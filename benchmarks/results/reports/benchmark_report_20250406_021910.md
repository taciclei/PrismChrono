# Rapport de Benchmarking Comparatif PrismChrono vs x86
*Généré le 06/04/2025 à 02:19:10*

## Introduction
Ce rapport présente une analyse comparative des performances entre l'architecture ternaire PrismChrono et l'architecture binaire x86. 
Les benchmarks ont été exécutés sur les deux plateformes et les métriques ont été collectées pour permettre une comparaison directe.

## Résumé des Résultats
**Nombre total de benchmarks:** 13
**Benchmarks standard:** 6
**Benchmarks spécifiques ternaires:** 7

### Ratios Moyens PrismChrono/x86
Le graphique ci-dessous présente les ratios moyens des métriques clés entre PrismChrono et x86, par catégorie de benchmark:

![Ratios Moyens](../graphs/summary_ratios_latest.png)

### Tableau des Ratios Moyens
| Métrique | Tous | Standard | Ternaire Spécifique |
| --- | ---: | ---: | ---: |
| Nombre d'instructions exécutées | 0.9872 | 1.2170 | 0.7902 |
| Taille du code exécutable | 0.8989 | 1.0736 | 0.7491 |
| Nombre de lectures mémoire | 0.8169 | 0.9942 | 0.6650 |
| Nombre d'écritures mémoire | 0.8398 | 0.8453 | 0.8352 |
| Nombre de branches | 0.8577 | 0.9328 | 0.7933 |
| Nombre de branches prises | 1.0443 | 1.2594 | 0.8600 |
| inst_mem_ratio | 1.2404 | 1.3576 | 1.1399 |
| inst_branch_ratio | 1.1872 | 1.3579 | 1.0409 |
| branch_taken_ratio | 1.3364 | 1.4394 | 1.2481 |
| code_density | 1.0997 | 1.1566 | 1.0509 |

> Note: Un ratio < 1 indique que PrismChrono est plus performant que x86 pour cette métrique.
> Un ratio > 1 indique que x86 est plus performant que PrismChrono.

## Analyse par Catégorie de Benchmark
### Benchmarks Standard
Les benchmarks standard permettent d'évaluer les performances générales de l'architecture PrismChrono par rapport à x86 sur des tâches communes.

| Benchmark | Description | Ratio Inst | Ratio Mem Ops | Ratio Code Size |
| --- | --- | ---: | ---: | ---: |
| sum_array | Calcul de la somme des éléments d'un tableau d'entiers | 1.0992 | 1.1353 | 1.0495 |
| memcpy | Copie d'un bloc de mémoire d'une zone source vers une zone destination | 1.4841 | 0.8583 | 1.1087 |
| factorial | Calcul itératif de la factorielle d'un nombre | 1.1170 | 0.8366 | 1.0730 |
| linear_search | Recherche de la première occurrence d'une valeur dans un tableau | 1.1315 | 1.1255 | 0.7565 |
| insertion_sort | Tri d'un petit tableau d'entiers par insertion | 1.2272 | 0.7735 | 1.1722 |
| function_call | Test d'appel de fonction simple | 1.2431 | 0.7893 | 1.2816 |

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
| ternary_logic | Implémentation d'un système de vote à trois états | 0.8284 | 0.8889 | 0.8133 |
| special_states | Traitement d'un tableau avec des valeurs spéciales (NULL, NaN) | 0.9226 | 0.8241 | 0.7281 |
| base24_arithmetic | Calculs exploitant la base 24 ou la symétrie | 0.9613 | 1.1333 | 0.8378 |
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
| Nombre d'instructions exécutées | 1186 | 1079 | 1.0992 |
| Taille du code exécutable | 530 | 505 | 1.0495 |
| Nombre de lectures mémoire | 279 | 217 | 1.2857 |
| Nombre d'écritures mémoire | 195 | 198 | 0.9848 |
| Nombre de branches | 74 | 85 | 0.8706 |
| Nombre de branches prises | 47 | 39 | 1.2051 |
| inst_mem_ratio | 2.5021 | 2.6000 | 0.9623 |
| inst_branch_ratio | 16.0270 | 12.6941 | 1.2626 |
| branch_taken_ratio | 0.6351 | 0.4588 | 1.3843 |
| code_density | 2.2377 | 2.1366 | 1.0473 |

### memcpy (Standard)
*Copie d'un bloc de mémoire d'une zone source vers une zone destination*

| Métrique | PrismChrono | x86 | Ratio |
| --- | ---: | ---: | ---: |
| Nombre d'instructions exécutées | 1214 | 818 | 1.4841 |
| Taille du code exécutable | 459 | 414 | 1.1087 |
| Nombre de lectures mémoire | 259 | 242 | 1.0702 |
| Nombre d'écritures mémoire | 117 | 181 | 0.6464 |
| Nombre de branches | 99 | 69 | 1.4348 |
| Nombre de branches prises | 38 | 33 | 1.1515 |
| inst_mem_ratio | 3.2287 | 1.9338 | 1.6696 |
| inst_branch_ratio | 12.2626 | 11.8551 | 1.0344 |
| branch_taken_ratio | 0.3838 | 0.4783 | 0.8024 |
| code_density | 2.6449 | 1.9758 | 1.3386 |

### factorial (Standard)
*Calcul itératif de la factorielle d'un nombre*

| Métrique | PrismChrono | x86 | Ratio |
| --- | ---: | ---: | ---: |
| Nombre d'instructions exécutées | 1117 | 1000 | 1.1170 |
| Taille du code exécutable | 485 | 452 | 1.0730 |
| Nombre de lectures mémoire | 271 | 260 | 1.0423 |
| Nombre d'écritures mémoire | 123 | 195 | 0.6308 |
| Nombre de branches | 59 | 73 | 0.8082 |
| Nombre de branches prises | 47 | 26 | 1.8077 |
| inst_mem_ratio | 2.8350 | 2.1978 | 1.2899 |
| inst_branch_ratio | 18.9322 | 13.6986 | 1.3821 |
| branch_taken_ratio | 0.7966 | 0.3562 | 2.2364 |
| code_density | 2.3031 | 2.2124 | 1.0410 |

### linear_search (Standard)
*Recherche de la première occurrence d'une valeur dans un tableau*

| Métrique | PrismChrono | x86 | Ratio |
| --- | ---: | ---: | ---: |
| Nombre d'instructions exécutées | 1015 | 897 | 1.1315 |
| Taille du code exécutable | 351 | 464 | 0.7565 |
| Nombre de lectures mémoire | 227 | 296 | 0.7669 |
| Nombre d'écritures mémoire | 187 | 126 | 1.4841 |
| Nombre de branches | 58 | 77 | 0.7532 |
| Nombre de branches prises | 50 | 32 | 1.5625 |
| inst_mem_ratio | 2.4517 | 2.1256 | 1.1534 |
| inst_branch_ratio | 17.5000 | 11.6494 | 1.5022 |
| branch_taken_ratio | 0.8621 | 0.4156 | 2.0744 |
| code_density | 2.8917 | 1.9332 | 1.4958 |

### insertion_sort (Standard)
*Tri d'un petit tableau d'entiers par insertion*

| Métrique | PrismChrono | x86 | Ratio |
| --- | ---: | ---: | ---: |
| Nombre d'instructions exécutées | 1291 | 1052 | 1.2272 |
| Taille du code exécutable | 497 | 424 | 1.1722 |
| Nombre de lectures mémoire | 248 | 273 | 0.9084 |
| Nombre d'écritures mémoire | 122 | 191 | 0.6387 |
| Nombre de branches | 71 | 69 | 1.0290 |
| Nombre de branches prises | 30 | 29 | 1.0345 |
| inst_mem_ratio | 3.4892 | 2.2672 | 1.5390 |
| inst_branch_ratio | 18.1831 | 15.2464 | 1.1926 |
| branch_taken_ratio | 0.4225 | 0.4203 | 1.0052 |
| code_density | 2.5976 | 2.4811 | 1.0470 |

### function_call (Standard)
*Test d'appel de fonction simple*

| Métrique | PrismChrono | x86 | Ratio |
| --- | ---: | ---: | ---: |
| Nombre d'instructions exécutées | 1166 | 938 | 1.2431 |
| Taille du code exécutable | 537 | 419 | 1.2816 |
| Nombre de lectures mémoire | 231 | 259 | 0.8919 |
| Nombre d'écritures mémoire | 114 | 166 | 0.6867 |
| Nombre de branches | 68 | 97 | 0.7010 |
| Nombre de branches prises | 31 | 39 | 0.7949 |
| inst_mem_ratio | 3.3797 | 2.2071 | 1.5313 |
| inst_branch_ratio | 17.1471 | 9.6701 | 1.7732 |
| branch_taken_ratio | 0.4559 | 0.4021 | 1.1338 |
| code_density | 2.1713 | 2.2387 | 0.9699 |

### ternary_logic (Ternary_specific)
*Implémentation d'un système de vote à trois états*

| Métrique | PrismChrono | x86 | Ratio |
| --- | ---: | ---: | ---: |
| Nombre d'instructions exécutées | 782 | 944 | 0.8284 |
| Taille du code exécutable | 392 | 482 | 0.8133 |
| Nombre de lectures mémoire | 208 | 291 | 0.7148 |
| Nombre d'écritures mémoire | 118 | 111 | 1.0631 |
| Nombre de branches | 60 | 76 | 0.7895 |
| Nombre de branches prises | 39 | 41 | 0.9512 |
| inst_mem_ratio | 2.3988 | 2.3483 | 1.0215 |
| inst_branch_ratio | 13.0333 | 12.4211 | 1.0493 |
| branch_taken_ratio | 0.6500 | 0.5395 | 1.2048 |
| code_density | 1.9949 | 1.9585 | 1.0186 |

### special_states (Ternary_specific)
*Traitement d'un tableau avec des valeurs spéciales (NULL, NaN)*

| Métrique | PrismChrono | x86 | Ratio |
| --- | ---: | ---: | ---: |
| Nombre d'instructions exécutées | 834 | 904 | 0.9226 |
| Taille du code exécutable | 340 | 467 | 0.7281 |
| Nombre de lectures mémoire | 180 | 298 | 0.6040 |
| Nombre d'écritures mémoire | 118 | 113 | 1.0442 |
| Nombre de branches | 74 | 94 | 0.7872 |
| Nombre de branches prises | 31 | 38 | 0.8158 |
| inst_mem_ratio | 2.7987 | 2.1995 | 1.2724 |
| inst_branch_ratio | 11.2703 | 9.6170 | 1.1719 |
| branch_taken_ratio | 0.4189 | 0.4043 | 1.0361 |
| code_density | 2.4529 | 1.9358 | 1.2671 |

### base24_arithmetic (Ternary_specific)
*Calculs exploitant la base 24 ou la symétrie*

| Métrique | PrismChrono | x86 | Ratio |
| --- | ---: | ---: | ---: |
| Nombre d'instructions exécutées | 870 | 905 | 0.9613 |
| Taille du code exécutable | 408 | 487 | 0.8378 |
| Nombre de lectures mémoire | 207 | 209 | 0.9904 |
| Nombre d'écritures mémoire | 134 | 105 | 1.2762 |
| Nombre de branches | 57 | 56 | 1.0179 |
| Nombre de branches prises | 39 | 46 | 0.8478 |
| inst_mem_ratio | 2.5513 | 2.8822 | 0.8852 |
| inst_branch_ratio | 15.2632 | 16.1607 | 0.9445 |
| branch_taken_ratio | 0.6842 | 0.8214 | 0.8330 |
| code_density | 2.1324 | 1.8583 | 1.1475 |

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
- **Nombre d'instructions exécutées**: Ratio moyen de 0.9872 (PrismChrono est 1.3% plus efficace)
- **Taille du code exécutable**: Ratio moyen de 0.8989 (PrismChrono est 10.1% plus efficace)
- **Nombre de lectures mémoire**: Ratio moyen de 0.8169 (PrismChrono est 18.3% plus efficace)
- **Nombre d'écritures mémoire**: Ratio moyen de 0.8398 (PrismChrono est 16.0% plus efficace)
- **Nombre de branches**: Ratio moyen de 0.8577 (PrismChrono est 14.2% plus efficace)

### Points à Améliorer
PrismChrono présente des performances inférieures dans les métriques suivantes:
- **Nombre de branches prises**: Ratio moyen de 1.0443 (PrismChrono est 4.4% moins efficace)
- **inst_mem_ratio**: Ratio moyen de 1.2404 (PrismChrono est 24.0% moins efficace)
- **inst_branch_ratio**: Ratio moyen de 1.1872 (PrismChrono est 18.7% moins efficace)
- **branch_taken_ratio**: Ratio moyen de 1.3364 (PrismChrono est 33.6% moins efficace)
- **code_density**: Ratio moyen de 1.0997 (PrismChrono est 10.0% moins efficace)

### Avantages Spécifiques Ternaires
Les benchmarks spécifiques ternaires montrent des avantages particuliers dans:
- **Nombre d'instructions exécutées**: Ratio de 0.7902 pour les benchmarks ternaires vs 1.2170 pour les benchmarks standard
- **Taille du code exécutable**: Ratio de 0.7491 pour les benchmarks ternaires vs 1.0736 pour les benchmarks standard
- **Nombre de lectures mémoire**: Ratio de 0.6650 pour les benchmarks ternaires vs 0.9942 pour les benchmarks standard
- **Nombre d'écritures mémoire**: Ratio de 0.8352 pour les benchmarks ternaires vs 0.8453 pour les benchmarks standard
- **Nombre de branches**: Ratio de 0.7933 pour les benchmarks ternaires vs 0.9328 pour les benchmarks standard
- **Nombre de branches prises**: Ratio de 0.8600 pour les benchmarks ternaires vs 1.2594 pour les benchmarks standard

### Recommandations
Sur la base de cette analyse, voici quelques recommandations pour l'évolution de PrismChrono:

1. **Optimisation des Points Faibles**: Concentrer les efforts d'optimisation sur les métriques où PrismChrono est moins performant.
2. **Exploitation des Avantages Ternaires**: Développer davantage les cas d'utilisation où l'architecture ternaire montre des avantages significatifs.
3. **Benchmarks Supplémentaires**: Créer des benchmarks plus spécifiques pour mieux évaluer les avantages potentiels de l'architecture ternaire.
4. **Analyse Approfondie**: Examiner en détail les benchmarks où PrismChrono surpasse x86 pour comprendre les facteurs contribuant à cette performance supérieure.