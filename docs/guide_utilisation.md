# Guide d'Utilisation des Benchmarks PrismChrono

## Introduction

Ce guide explique comment utiliser le système de benchmarking PrismChrono pour comparer les performances de l'architecture ternaire PrismChrono avec l'architecture binaire x86. Il est destiné aux utilisateurs qui souhaitent exécuter les benchmarks existants ou en créer de nouveaux.

## Installation et Prérequis

Avant de pouvoir utiliser le système de benchmarking, assurez-vous que les composants suivants sont installés et configurés :

### Outils Requis

1. **Rust et Cargo** (pour compiler l'assembleur et le simulateur)
   ```bash
   curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
   ```

2. **GCC** (pour compiler les benchmarks x86)
   ```bash
   # Sur macOS avec Homebrew
   brew install gcc
   
   # Sur Ubuntu/Debian
   sudo apt install gcc
   ```

3. **Python 3** avec les bibliothèques nécessaires
   ```bash
   pip3 install matplotlib numpy markdown
   ```

### Compilation des Outils PrismChrono

Avant d'exécuter les benchmarks, vous devez compiler l'assembleur et le simulateur PrismChrono :

```bash
# Compiler l'assembleur
cd /chemin/vers/PrismChrono/prismchrono_asm
cargo build --release

# Compiler le simulateur
cd /chemin/vers/PrismChrono/prismChrono_sim
cargo build --release
```

## Exécution des Benchmarks

### Exécution Complète

Pour exécuter tous les benchmarks, générer les graphiques et produire un rapport complet, utilisez le script `run_all.sh` :

```bash
cd /chemin/vers/PrismChrono
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
cd /chemin/vers/PrismChrono

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

## Structure des Résultats

Après l'exécution des benchmarks, les résultats sont organisés comme suit :

```
benchmarks/results/
  ├── raw/                # Données brutes des benchmarks
  │   ├── prismchrono/    # Résultats des benchmarks PrismChrono
  │   ├── x86/            # Résultats des benchmarks x86
  │   └── combined/       # Métriques combinées
  ├── graphs/             # Graphiques générés
  └── reports/            # Rapports d'analyse
```

### Fichiers de Résultats

- **Données brutes** : Fichiers JSON contenant les métriques collectées pour chaque benchmark
  - `benchmarks/results/raw/prismchrono/{benchmark}.json`
  - `benchmarks/results/raw/x86/{benchmark}.json`

- **Métriques combinées** : Fichier JSON contenant les métriques combinées et les ratios
  - `benchmarks/results/raw/combined/combined_metrics_latest.json`
  - `benchmarks/results/raw/combined/stats_latest.json`

- **Graphiques** : Images PNG des graphiques comparatifs
  - `benchmarks/results/graphs/{metric}_{category}_latest.png`
  - `benchmarks/results/graphs/summary_ratios_latest.png`

- **Rapports** : Rapports d'analyse au format Markdown et HTML
  - `benchmarks/results/reports/benchmark_report_latest.md`
  - `benchmarks/results/reports/benchmark_report_latest.html`

## Interprétation des Résultats

### Lecture du Rapport

Le rapport généré contient plusieurs sections :

1. **Introduction** : Présentation du contexte et des objectifs
2. **Résumé des Résultats** : Vue d'ensemble avec les ratios moyens
3. **Analyse par Catégorie** : Performances par type de benchmark
4. **Analyse des Métriques Dérivées** : Analyse des métriques calculées
5. **Analyse Détaillée** : Résultats détaillés pour chaque benchmark
6. **Conclusion** : Synthèse et recommandations

### Comprendre les Ratios

Les ratios présentés dans le rapport sont calculés comme suit :

```
Ratio = Valeur_PrismChrono / Valeur_x86
```

- **Ratio < 1** : PrismChrono est plus performant que x86
- **Ratio = 1** : Performances équivalentes
- **Ratio > 1** : x86 est plus performant que PrismChrono

### Exemple d'Interprétation

Prenons un exemple concret :

- Si le ratio pour `instruction_count` est de 0.85, cela signifie que PrismChrono exécute 15% moins d'instructions que x86 pour le même benchmark.
- Si le ratio pour `code_size` est de 1.2, cela signifie que le code PrismChrono est 20% plus volumineux que le code x86 équivalent.

## Personnalisation

### Configuration des Benchmarks

La configuration des benchmarks est définie dans le fichier `benchmarks/scripts/config.json`. Vous pouvez modifier ce fichier pour :

- Ajouter ou supprimer des benchmarks
- Modifier les paramètres des benchmarks existants
- Ajouter de nouvelles métriques à collecter

### Création d'un Nouveau Benchmark

Pour créer un nouveau benchmark :

1. **Créez l'implémentation PrismChrono** :
   - Créez un fichier `.s` dans `benchmarks/prismchrono/`
   - Implémentez le benchmark en assembleur PrismChrono

2. **Créez l'implémentation x86** :
   - Créez un fichier `.c` dans `benchmarks/x86/`
   - Implémentez le même algorithme en C

3. **Ajoutez le benchmark à la configuration** :
   - Modifiez `benchmarks/scripts/config.json`
   - Ajoutez une entrée pour votre benchmark dans la catégorie appropriée

### Exemple d'Ajout de Benchmark

Voici un exemple d'ajout d'un nouveau benchmark dans `config.json` :

```json
{
  "benchmarks": {
    "standard": [
      // Benchmarks existants...
      {
        "name": "mon_nouveau_benchmark",
        "description": "Description de mon nouveau benchmark",
        "params": {
          "param1": 100,
          "param2": 200
        }
      }
    ]
  }
}
```

## Dépannage

### Problèmes Courants

1. **Erreur : Assembleur PrismChrono non trouvé**
   - **Cause** : L'assembleur n'a pas été compilé ou n'est pas dans le chemin attendu
   - **Solution** : Compilez l'assembleur avec `cargo build --release`

2. **Erreur : Simulateur PrismChrono non trouvé**
   - **Cause** : Le simulateur n'a pas été compilé ou n'est pas dans le chemin attendu
   - **Solution** : Compilez le simulateur avec `cargo build --release`

3. **Erreur lors de la compilation des benchmarks x86**
   - **Cause** : GCC n'est pas installé ou le code source contient des erreurs
   - **Solution** : Vérifiez l'installation de GCC et corrigez les erreurs dans le code source

4. **Aucun graphique généré**
   - **Cause** : La bibliothèque matplotlib n'est pas installée
   - **Solution** : Installez matplotlib avec `pip install matplotlib`

5. **Erreur lors de la génération du rapport HTML**
   - **Cause** : La bibliothèque markdown n'est pas installée
   - **Solution** : Installez markdown avec `pip install markdown`

### Vérification des Logs

En cas d'erreur, consultez les messages d'erreur affichés dans le terminal. Les scripts affichent des messages détaillés qui peuvent aider à identifier la source du problème.

## Conseils d'Utilisation

1. **Exécutez régulièrement les benchmarks** pendant le développement pour suivre l'évolution des performances.

2. **Comparez les résultats** entre différentes versions de PrismChrono pour mesurer l'impact des modifications.

3. **Concentrez-vous sur les tendances** plutôt que sur les valeurs absolues, car les performances peuvent varier selon l'environnement d'exécution.

4. **Créez des benchmarks spécifiques** pour tester des aspects particuliers de l'architecture ternaire.

5. **Partagez vos résultats** avec la communauté pour contribuer à l'amélioration de PrismChrono.

## Conclusion

Le système de benchmarking PrismChrono est un outil puissant pour évaluer les performances de l'architecture ternaire par rapport à l'architecture binaire traditionnelle. En suivant ce guide, vous pourrez exécuter les benchmarks existants, créer vos propres benchmarks et interpréter les résultats pour mieux comprendre les forces et les faiblesses de l'architecture PrismChrono.

Pour toute question ou suggestion, n'hésitez pas à consulter la documentation technique ou à contacter l'équipe de développement.