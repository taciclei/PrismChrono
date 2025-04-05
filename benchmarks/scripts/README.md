# Scripts de Benchmarking

Ce répertoire contient les scripts nécessaires pour exécuter les benchmarks, collecter les métriques et générer les visualisations pour l'analyse comparative entre PrismChrono et l'architecture binaire de référence.

## Scripts d'exécution

- `run_prismchrono.sh` : Assemble et exécute les benchmarks PrismChrono sur le simulateur
- `run_x86.sh` : Compile et exécute les benchmarks x86 (C/Rust)
- `run_all.sh` : Exécute tous les benchmarks sur les deux plateformes

## Scripts de collecte de métriques

- `collect_metrics_prismchrono.py` : Extrait les métriques des sorties du simulateur PrismChrono
- `collect_metrics_x86.py` : Extrait les métriques des sorties de perf/size pour x86
- `combine_metrics.py` : Combine les métriques des deux plateformes dans un format structuré (CSV/JSON)

## Scripts de visualisation

- `generate_graphs.py` : Génère des graphiques comparatifs à partir des données collectées
- `generate_report.py` : Génère un rapport Markdown avec les graphiques et analyses

## Utilisation

### Exécution complète

```bash
# Exécuter tous les benchmarks et générer le rapport
./run_all.sh
```

### Exécution étape par étape

```bash
# Exécuter uniquement les benchmarks PrismChrono
./run_prismchrono.sh

# Exécuter uniquement les benchmarks x86
./run_x86.sh

# Collecter et combiner les métriques
python3 combine_metrics.py

# Générer les graphiques
python3 generate_graphs.py

# Générer le rapport
python3 generate_report.py
```

## Configuration

Les paramètres de configuration (tailles des tableaux, nombre d'itérations, etc.) sont définis dans le fichier `config.json`.