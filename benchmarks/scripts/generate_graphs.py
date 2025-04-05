#!/usr/bin/env python3
# Script pour générer des graphiques comparatifs à partir des métriques combinées
# Sprint 13: Benchmarking Comparatif & Analyse Architecturale

import os
import json
import sys
import matplotlib.pyplot as plt
import numpy as np
from pathlib import Path
from datetime import datetime

# Définition des chemins
SCRIPT_DIR = Path(os.path.dirname(os.path.abspath(__file__)))
BENCHMARK_DIR = SCRIPT_DIR.parent
COMBINED_RESULTS_DIR = BENCHMARK_DIR / "results" / "raw" / "combined"
GRAPHS_DIR = BENCHMARK_DIR / "results" / "graphs"

# Créer le répertoire de graphiques s'il n'existe pas
GRAPHS_DIR.mkdir(parents=True, exist_ok=True)
print(f"Répertoire de graphiques vérifié/créé: {GRAPHS_DIR}")

# Horodatage pour les fichiers de sortie
TIMESTAMP = datetime.now().strftime("%Y%m%d_%H%M%S")

# Charger les données combinées
COMBINED_DATA_FILE = COMBINED_RESULTS_DIR / "combined_metrics_latest.json"
STATS_FILE = COMBINED_RESULTS_DIR / "stats_latest.json"

if not COMBINED_DATA_FILE.exists():
    print(f"Erreur: Fichier de données combinées non trouvé: {COMBINED_DATA_FILE}")
    print("Veuillez d'abord exécuter le script combine_metrics.py")
    sys.exit(1)

try:
    with open(COMBINED_DATA_FILE, 'r') as f:
        combined_data = json.load(f)
    print(f"Données combinées chargées depuis: {COMBINED_DATA_FILE}")
    
    with open(STATS_FILE, 'r') as f:
        stats = json.load(f)
    print(f"Statistiques globales chargées depuis: {STATS_FILE}")
except json.JSONDecodeError as e:
    print(f"Erreur: Format JSON invalide dans {COMBINED_DATA_FILE}: {e}")
    sys.exit(1)
except Exception as e:
    print(f"Erreur lors du chargement des données: {e}")
    sys.exit(1)

# Charger la configuration pour obtenir les descriptions des métriques
CONFIG_FILE = SCRIPT_DIR / "config.json"
if not CONFIG_FILE.exists():
    print(f"Avertissement: Fichier de configuration non trouvé: {CONFIG_FILE}")
    metric_descriptions = {}
else:
    try:
        with open(CONFIG_FILE, 'r') as f:
            config = json.load(f)
        metric_descriptions = {m['name']: m['description'] for m in config.get('metrics', [])}
        print(f"Configuration chargée depuis: {CONFIG_FILE}")
    except Exception as e:
        print(f"Avertissement: Erreur lors du chargement de la configuration: {e}")
        metric_descriptions = {}

# Extraire les métriques de base et dérivées
base_metrics = []
derived_metrics = []

if combined_data and len(combined_data) > 0:
    # Identifier les métriques de base et dérivées à partir des clés du premier élément
    first_item = combined_data[0]
    for key in first_item.keys():
        if key.startswith('ratio_'):
            metric_name = key[6:]  # Enlever 'ratio_'
            if metric_name in ['inst_mem_ratio', 'inst_branch_ratio', 'branch_taken_ratio', 'code_density']:
                derived_metrics.append(metric_name)
            elif metric_name not in ['benchmark', 'platform', 'prismchrono_success', 'x86_success', 'category']:
                base_metrics.append(metric_name)

print(f"Métriques de base identifiées: {', '.join(base_metrics)}")
print(f"Métriques dérivées identifiées: {', '.join(derived_metrics)}")

# Fonction pour générer un graphique de comparaison pour une métrique
def generate_comparison_graph(metric, benchmarks_data, category=None):
    # Filtrer les données par catégorie si spécifiée
    if category:
        filtered_data = [d for d in benchmarks_data if d.get('category') == category]
        title_suffix = f" - Catégorie: {category.capitalize()}"
    else:
        filtered_data = benchmarks_data
        title_suffix = " - Tous les benchmarks"
    
    if not filtered_data:
        print(f"Avertissement: Aucune donnée pour la métrique {metric}{title_suffix}")
        return None
    
    # Extraire les noms de benchmarks et les valeurs
    benchmark_names = [d['benchmark'] for d in filtered_data]
    prismchrono_values = [d.get(f'prismchrono_{metric}', 0) for d in filtered_data]
    x86_values = [d.get(f'x86_{metric}', 0) for d in filtered_data]
    ratio_values = [d.get(f'ratio_{metric}', 0) for d in filtered_data]
    
    # Créer la figure et les axes
    fig, (ax1, ax2) = plt.subplots(2, 1, figsize=(12, 10), gridspec_kw={'height_ratios': [3, 1]})
    
    # Largeur des barres
    bar_width = 0.35
    x = np.arange(len(benchmark_names))
    
    # Graphique des valeurs absolues
    bars1 = ax1.bar(x - bar_width/2, prismchrono_values, bar_width, label='PrismChrono')
    bars2 = ax1.bar(x + bar_width/2, x86_values, bar_width, label='x86')
    
    # Ajouter les étiquettes et le titre
    metric_description = metric_descriptions.get(metric, metric)
    ax1.set_title(f"Comparaison {metric_description}{title_suffix}")
    ax1.set_xticks(x)
    ax1.set_xticklabels(benchmark_names, rotation=45, ha='right')
    ax1.legend()
    ax1.grid(axis='y', linestyle='--', alpha=0.7)
    
    # Ajouter les valeurs au-dessus des barres
    def add_labels(bars):
        for bar in bars:
            height = bar.get_height()
            ax1.annotate(f'{height}',
                        xy=(bar.get_x() + bar.get_width() / 2, height),
                        xytext=(0, 3),  # 3 points de décalage vertical
                        textcoords="offset points",
                        ha='center', va='bottom', fontsize=8)
    
    add_labels(bars1)
    add_labels(bars2)
    
    # Graphique des ratios
    bars3 = ax2.bar(x, ratio_values, bar_width*1.5, color='green')
    ax2.set_title(f"Ratio PrismChrono/x86 pour {metric}")
    ax2.set_xticks(x)
    ax2.set_xticklabels(benchmark_names, rotation=45, ha='right')
    ax2.axhline(y=1, color='r', linestyle='-', alpha=0.5)  # Ligne de référence à ratio=1
    ax2.grid(axis='y', linestyle='--', alpha=0.7)
    
    # Ajouter les valeurs au-dessus des barres de ratio
    for bar in bars3:
        height = bar.get_height()
        ax2.annotate(f'{height:.2f}',
                    xy=(bar.get_x() + bar.get_width() / 2, height),
                    xytext=(0, 3),  # 3 points de décalage vertical
                    textcoords="offset points",
                    ha='center', va='bottom', fontsize=8)
    
    plt.tight_layout()
    
    # Déterminer le nom du fichier
    if category:
        filename = f"{metric}_{category}_{TIMESTAMP}.png"
    else:
        filename = f"{metric}_all_{TIMESTAMP}.png"
    
    # Sauvegarder le graphique
    filepath = GRAPHS_DIR / filename
    plt.savefig(filepath)
    print(f"Graphique sauvegardé: {filepath}")
    
    # Également sauvegarder une version "latest"
    if category:
        latest_filename = f"{metric}_{category}_latest.png"
    else:
        latest_filename = f"{metric}_all_latest.png"
    
    latest_filepath = GRAPHS_DIR / latest_filename
    plt.savefig(latest_filepath)
    
    plt.close(fig)
    return filepath

# Générer des graphiques pour toutes les métriques de base
print("\nGénération des graphiques pour les métriques de base...")
for metric in base_metrics:
    # Graphique pour tous les benchmarks
    generate_comparison_graph(metric, combined_data)
    
    # Graphiques par catégorie
    generate_comparison_graph(metric, combined_data, category='standard')
    generate_comparison_graph(metric, combined_data, category='ternary_specific')

# Générer des graphiques pour toutes les métriques dérivées
print("\nGénération des graphiques pour les métriques dérivées...")
for metric in derived_metrics:
    # Graphique pour tous les benchmarks
    generate_comparison_graph(metric, combined_data)
    
    # Graphiques par catégorie
    generate_comparison_graph(metric, combined_data, category='standard')
    generate_comparison_graph(metric, combined_data, category='ternary_specific')

# Générer un graphique de synthèse des ratios moyens
def generate_summary_graph():
    categories = ['standard', 'ternary_specific']
    all_metrics = base_metrics + derived_metrics
    
    # Préparer les données
    category_data = {}
    for category in categories:
        category_data[category] = [stats['category_avg_ratios'][category].get(metric, 0) for metric in all_metrics]
    
    # Créer la figure
    fig, ax = plt.subplots(figsize=(14, 8))
    
    # Position des barres
    x = np.arange(len(all_metrics))
    bar_width = 0.35
    
    # Créer les barres
    bars1 = ax.bar(x - bar_width/2, category_data['standard'], bar_width, label='Standard')
    bars2 = ax.bar(x + bar_width/2, category_data['ternary_specific'], bar_width, label='Ternaire Spécifique')
    
    # Ajouter les étiquettes et le titre
    ax.set_title("Ratios moyens PrismChrono/x86 par catégorie de benchmark")
    ax.set_xticks(x)
    ax.set_xticklabels(all_metrics, rotation=45, ha='right')
    ax.legend()
    ax.grid(axis='y', linestyle='--', alpha=0.7)
    ax.axhline(y=1, color='r', linestyle='-', alpha=0.5)  # Ligne de référence à ratio=1
    
    # Ajouter les valeurs au-dessus des barres
    def add_labels(bars):
        for bar in bars:
            height = bar.get_height()
            ax.annotate(f'{height:.2f}',
                        xy=(bar.get_x() + bar.get_width() / 2, height),
                        xytext=(0, 3),  # 3 points de décalage vertical
                        textcoords="offset points",
                        ha='center', va='bottom', fontsize=8)
    
    add_labels(bars1)
    add_labels(bars2)
    
    plt.tight_layout()
    
    # Sauvegarder le graphique
    filename = f"summary_ratios_{TIMESTAMP}.png"
    filepath = GRAPHS_DIR / filename
    plt.savefig(filepath)
    print(f"Graphique de synthèse sauvegardé: {filepath}")
    
    # Également sauvegarder une version "latest"
    latest_filepath = GRAPHS_DIR / "summary_ratios_latest.png"
    plt.savefig(latest_filepath)
    
    plt.close(fig)
    return filepath

# Générer le graphique de synthèse
print("\nGénération du graphique de synthèse des ratios moyens...")
generate_summary_graph()

print("\nGénération des graphiques terminée avec succès!")
print(f"Tous les graphiques ont été sauvegardés dans: {GRAPHS_DIR}")
print("\nVous pouvez maintenant exécuter le script generate_report.py pour générer un rapport détaillé.")