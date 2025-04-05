# Guide de Benchmarking PrismChrono

## Introduction

Ce document présente le système de benchmarking comparatif entre l'architecture ternaire PrismChrono et l'architecture binaire x86. Il explique comment exécuter les benchmarks, interpréter les résultats et comprendre les métriques utilisées pour l'analyse comparative.

## Architecture du Projet

Le projet PrismChrono est une architecture ternaire innovante qui utilise une logique à trois états (ternaire) au lieu de la logique binaire traditionnelle. Les principales caractéristiques de cette architecture sont :

- **Type**: Architecture Logic GPR Base-24 Ternaire +
- **Taille de mot**: 24 Trits (8 Trytes)
- **Mémoire adressable**: 16 MTrytes
- **Endianness**: Little-Endian
- **Registres**: 8 registres généraux (R0-R7)

### Types de Données Ternaires

- **Trit**: L'unité fondamentale de l'architecture ternaire, équivalent au bit dans les systèmes binaires. Il peut prendre trois valeurs : N (-1), Z (0), P (+1).
- **Tryte**: Composé de 3 Trits, peut représenter des valeurs numériques de -13 à +13 en ternaire équilibré.
- **Word**: Composé de 8 Trytes (24 Trits), représente la taille standard des données manipulées par le processeur.

## Structure du Système de Benchmarking

Le système de benchmarking est organisé comme suit :

```
benchmarks/
  ├── prismchrono/     # Implémentations en assembleur PrismChrono (.s)
  ├── x86/             # Implémentations en C/Rust pour la référence binaire (.c/.rs)
  ├── scripts/         # Scripts d'exécution, de collecte de métriques et de visualisation
  └── results/         # Données brutes collectées et graphiques générés
      ├── raw/         # Données brutes des benchmarks
      ├── graphs/      # Graphiques générés
      └── reports/     # Rapports d'analyse
```

## Benchmarks Disponibles

### Benchmarks Standards

1. **Sum Array**: Calcul de la somme des éléments d'un tableau d'entiers
2. **Memcpy**: Copie d'un bloc de mémoire d'une zone source vers une zone destination
3. **Factorial**: Calcul itératif de la factorielle d'un nombre
4. **Linear Search**: Recherche de la première occurrence d'une valeur dans un tableau
5. **Insertion Sort**: Tri d'un petit tableau d'entiers par insertion
6. **Function Call**: Test d'appel de fonction simple

### Benchmarks Spécifiques Ternaires

1. **Ternary Logic**: Implémentation d'un système de vote ou de logique tri-valuée
2. **Special States**: Traitement d'un tableau avec des valeurs spéciales (NULL, NaN)
3. **Base 24 Arithmetic**: Calculs exploitant la base 24 ou la symétrie

## Métriques Mesurées

Le système de benchmarking collecte et analyse les métriques suivantes :

- **Nombre d'instructions exécutées**: Mesure l'efficacité algorithmique
- **Taille du code**: Mesure la densité du code et l'efficacité de l'encodage des instructions
- **Nombre de lectures mémoire**: Mesure l'efficacité des accès mémoire en lecture
- **Nombre d'écritures mémoire**: Mesure l'efficacité des accès mémoire en écriture
- **Nombre de branches**: Mesure la complexité du flux de contrôle
- **Branches prises**: Mesure l'efficacité de la prédiction de branchement

### Métriques Dérivées

- **inst_mem_ratio**: Ratio Instructions / Opérations Mémoire - Mesure l'efficacité des instructions par rapport aux accès mémoire
- **inst_branch_ratio**: Ratio Instructions / Branches - Mesure la densité des branchements dans le code
- **branch_taken_ratio**: Ratio Branches Prises / Total Branches - Mesure l'efficacité de la prédiction de branchement
- **code_density**: Densité du Code (Instructions / Taille) - Mesure l'efficacité de l'encodage des instructions

## Exécution des Benchmarks

### Prérequis

Avant d'exécuter les benchmarks, assurez-vous que les composants suivants sont installés et compilés :

1. **Assembleur PrismChrono**:
   ```bash
   cd /chemin/vers/PrismChrono/prismchrono_asm
   cargo build --release
   ```

2. **Simulateur PrismChrono**:
   ```bash
   cd /chemin/vers/PrismChrono/prismChrono_sim
   cargo build --release
   ```

3. **Outils de compilation C/C++**:
   - GCC (pour les benchmarks x86)
   - Outils de mesure de performance (perf, size)

### Exécution Complète

Pour exécuter tous les benchmarks, générer les graphiques et produire un rapport complet :

```bash
./benchmarks/scripts/run_all.sh
```

Ce script exécute séquentiellement les étapes suivantes :

1. Exécution des benchmarks PrismChrono
2. Exécution des benchmarks x86
3. Combinaison des métriques
4. Génération des graphiques
5. Génération du rapport

### Exécution Étape par Étape

Vous pouvez également exécuter chaque étape individuellement :

```bash
# Exécuter uniquement les benchmarks PrismChrono
./benchmarks/scripts/run_prismchrono.sh

# Exécuter uniquement les benchmarks x86
./benchmarks/scripts/run_x86.sh

# Collecter et combiner les métriques
python3 benchmarks/scripts/combine_metrics.py

# Générer les graphiques
python3 benchmarks/scripts/generate_graphs.py

# Générer le rapport
python3 benchmarks/scripts/generate_report.py
```

## Interprétation des Résultats

### Rapports Générés

Le système génère deux types de rapports :

1. **Rapport Markdown** (`benchmark_report_latest.md`): Un rapport textuel formaté en Markdown
2. **Rapport HTML** (`benchmark_report_latest.html`): Une version HTML du rapport avec des styles CSS

Ces rapports sont stockés dans le répertoire `benchmarks/results/reports/`.

### Structure du Rapport

Le rapport comprend les sections suivantes :

1. **Introduction**: Présentation du contexte et des objectifs de l'analyse
2. **Résumé des Résultats**: Vue d'ensemble des benchmarks exécutés et des ratios moyens
3. **Analyse par Catégorie de Benchmark**: Analyse détaillée des performances par catégorie
4. **Analyse des Métriques Dérivées**: Analyse des métriques calculées à partir des métriques de base
5. **Analyse Détaillée par Benchmark**: Analyse individuelle de chaque benchmark
6. **Conclusion**: Synthèse des résultats et recommandations

### Interprétation des Ratios

Les ratios présentés dans le rapport sont calculés comme suit :

```
Ratio = Valeur_PrismChrono / Valeur_x86
```

- **Ratio < 1**: PrismChrono est plus performant que x86 pour cette métrique
- **Ratio = 1**: Performances équivalentes
- **Ratio > 1**: x86 est plus performant que PrismChrono pour cette métrique

## Personnalisation des Benchmarks

### Configuration

La configuration des benchmarks est définie dans le fichier `benchmarks/scripts/config.json`. Ce fichier contient :

- La liste des benchmarks à exécuter, regroupés par catégorie
- Les paramètres de chaque benchmark
- Les métriques à collecter et leurs descriptions

### Ajout d'un Nouveau Benchmark

Pour ajouter un nouveau benchmark :

1. Créez l'implémentation PrismChrono dans `benchmarks/prismchrono/`
2. Créez l'implémentation x86 correspondante dans `benchmarks/x86/`
3. Ajoutez le benchmark à la configuration dans `config.json`

## Dépannage

### Problèmes Courants

1. **Erreur: Assembleur PrismChrono non trouvé**
   - Solution: Compilez l'assembleur avec `cargo build --release` dans le répertoire `prismchrono_asm`

2. **Erreur: Simulateur PrismChrono non trouvé**
   - Solution: Compilez le simulateur avec `cargo build --release` dans le répertoire `prismChrono_sim`

3. **Erreur lors de la compilation des benchmarks x86**
   - Solution: Vérifiez que GCC est installé et que les fichiers source sont corrects

4. **Aucun graphique généré**
   - Solution: Vérifiez que matplotlib est installé (`pip install matplotlib`)

## Conclusion

Le système de benchmarking PrismChrono fournit une analyse comparative détaillée entre l'architecture ternaire PrismChrono et l'architecture binaire x86. Les résultats permettent d'identifier les forces et les faiblesses de l'architecture ternaire, ainsi que les cas d'utilisation où elle pourrait offrir des avantages significatifs.

Pour toute question ou suggestion concernant le système de benchmarking, veuillez consulter la documentation du projet ou contacter l'équipe de développement.