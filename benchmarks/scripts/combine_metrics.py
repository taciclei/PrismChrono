#!/usr/bin/env python3
# Script pour combiner les métriques des benchmarks PrismChrono et x86
# Amélioré pour le Sprint 13: Benchmarking Comparatif & Analyse Architecturale

import os
import json
import csv
import sys
from pathlib import Path
from datetime import datetime

# Définition des chemins
SCRIPT_DIR = Path(os.path.dirname(os.path.abspath(__file__)))
BENCHMARK_DIR = SCRIPT_DIR.parent
PRISMCHRONO_RESULTS_DIR = BENCHMARK_DIR / "results" / "raw" / "prismchrono"
X86_RESULTS_DIR = BENCHMARK_DIR / "results" / "raw" / "x86"
COMBINED_RESULTS_DIR = BENCHMARK_DIR / "results" / "raw" / "combined"

# Créer les répertoires de résultats s'ils n'existent pas
for dir_path in [PRISMCHRONO_RESULTS_DIR, X86_RESULTS_DIR, COMBINED_RESULTS_DIR]:
    dir_path.mkdir(parents=True, exist_ok=True)
    print(f"Répertoire vérifié/créé: {dir_path}")

# Horodatage pour les fichiers de sortie
TIMESTAMP = datetime.now().strftime("%Y%m%d_%H%M%S")

# Charger la configuration
CONFIG_FILE = SCRIPT_DIR / "config.json"
if not CONFIG_FILE.exists():
    print(f"Erreur: Fichier de configuration non trouvé: {CONFIG_FILE}")
    sys.exit(1)

try:
    with open(CONFIG_FILE, 'r') as f:
        config = json.load(f)
    print(f"Configuration chargée depuis: {CONFIG_FILE}")
except json.JSONDecodeError as e:
    print(f"Erreur: Format JSON invalide dans {CONFIG_FILE}: {e}")
    sys.exit(1)
except Exception as e:
    print(f"Erreur lors du chargement de {CONFIG_FILE}: {e}")
    sys.exit(1)

# Liste des benchmarks à traiter
benchmarks = []
for category in ['standard', 'ternary_specific']:
    if category in config['benchmarks']:
        category_benchmarks = [b['name'] for b in config['benchmarks'][category]]
        benchmarks.extend(category_benchmarks)
        print(f"Benchmarks de la catégorie '{category}': {', '.join(category_benchmarks)}")

if not benchmarks:
    print("Avertissement: Aucun benchmark trouvé dans la configuration")
    sys.exit(1)

# Liste des métriques à collecter
metrics = [m['name'] for m in config['metrics']]
print(f"Métriques à collecter: {', '.join(metrics)}")

if not metrics:
    print("Erreur: Aucune métrique trouvée dans la configuration")
    sys.exit(1)

# Fonction pour charger les métriques d'un benchmark pour une plateforme
def load_metrics(platform_dir, benchmark, platform_name):
    result_file = platform_dir / f"{benchmark}.json"
    if not result_file.exists():
        print(f"Avertissement: Fichier de résultats {platform_name} non trouvé: {result_file}")
        return {metric: 0 for metric in metrics}, False
    
    try:
        with open(result_file, 'r') as f:
            data = json.load(f)
        
        # Extraire les métriques demandées
        metrics_data = {metric: data.get(metric, 0) for metric in metrics}
        # Vérifier si toutes les métriques sont à zéro (ce qui pourrait indiquer un problème)
        if all(value == 0 for value in metrics_data.values()):
            print(f"Avertissement: Toutes les métriques sont à zéro pour {platform_name}/{benchmark}")
        elif any(value == 0 for value in metrics_data.values()):
            zero_metrics = [m for m, v in metrics_data.items() if v == 0]
            print(f"Avertissement: Certaines métriques sont à zéro pour {platform_name}/{benchmark}: {', '.join(zero_metrics)}")
        
        return metrics_data, True
    except json.JSONDecodeError as e:
        print(f"Erreur: Format JSON invalide dans {result_file}: {e}")
        return {metric: 0 for metric in metrics}, False
    except Exception as e:
        print(f"Erreur lors du chargement de {result_file}: {e}")
        return {metric: 0 for metric in metrics}, False

# Fonction pour calculer les métriques dérivées
def calculate_derived_metrics(metrics_data):
    derived = {}
    
    # Ratio Instructions / Opérations Mémoire (Inst/Mem)
    mem_ops = metrics_data.get('memory_reads', 0) + metrics_data.get('memory_writes', 0)
    if mem_ops > 0:
        derived['inst_mem_ratio'] = round(metrics_data.get('instruction_count', 0) / mem_ops, 4)
    else:
        derived['inst_mem_ratio'] = 0
    
    # Ratio Instructions / Branches (Inst/Branch)
    branches = metrics_data.get('branches', 0)
    if branches > 0:
        derived['inst_branch_ratio'] = round(metrics_data.get('instruction_count', 0) / branches, 4)
    else:
        derived['inst_branch_ratio'] = 0
    
    # Ratio Branches Prises / Total Branches
    if branches > 0:
        derived['branch_taken_ratio'] = round(metrics_data.get('branches_taken', 0) / branches, 4)
    else:
        derived['branch_taken_ratio'] = 0
    
    # Densité d'instructions (Instructions / Taille du code)
    code_size = metrics_data.get('code_size', 0)
    if code_size > 0:
        derived['code_density'] = round(metrics_data.get('instruction_count', 0) / code_size, 4)
    else:
        derived['code_density'] = 0
    
    return derived

# Combiner les métriques pour tous les benchmarks
combined_data = []
success_count = 0
total_count = len(benchmarks)

# Liste des métriques dérivées
derived_metrics = ['inst_mem_ratio', 'inst_branch_ratio', 'branch_taken_ratio', 'code_density']

for benchmark in benchmarks:
    print(f"\nTraitement du benchmark: {benchmark}")
    
    # Charger les métriques pour PrismChrono
    prismchrono_metrics, prismchrono_success = load_metrics(PRISMCHRONO_RESULTS_DIR, benchmark, "PrismChrono")
    
    # Charger les métriques pour x86
    x86_metrics, x86_success = load_metrics(X86_RESULTS_DIR, benchmark, "x86")
    
    # Calculer les métriques dérivées
    prismchrono_derived = calculate_derived_metrics(prismchrono_metrics)
    x86_derived = calculate_derived_metrics(x86_metrics)
    
    # Combiner les métriques
    benchmark_data = {
        'benchmark': benchmark,
        'platform': 'both',
        'prismchrono_success': prismchrono_success,
        'x86_success': x86_success,
        'category': next((cat for cat, benchs in config['benchmarks'].items() 
                        for b in benchs if b['name'] == benchmark), 'unknown')
    }
    
    # Traiter les métriques de base
    for metric in metrics:
        prismchrono_value = prismchrono_metrics[metric]
        x86_value = x86_metrics[metric]
        
        benchmark_data[f'prismchrono_{metric}'] = prismchrono_value
        benchmark_data[f'x86_{metric}'] = x86_value
        
        # Calculer le ratio PrismChrono / x86
        if x86_value > 0:
            ratio = prismchrono_value / x86_value
            ratio_formatted = round(ratio, 4)  # Arrondir à 4 décimales pour lisibilité
        else:
            if prismchrono_value > 0:
                ratio_formatted = float('inf')  # Infini si x86 est zéro mais PrismChrono non
            else:
                ratio_formatted = 0  # Les deux sont zéro
                
        benchmark_data[f'ratio_{metric}'] = ratio_formatted
        
        # Afficher les métriques et ratios
        print(f"  {metric}: PrismChrono={prismchrono_value}, x86={x86_value}, Ratio={ratio_formatted}")
    
    # Traiter les métriques dérivées
    print("  Métriques dérivées:")
    for metric in derived_metrics:
        prismchrono_value = prismchrono_derived[metric]
        x86_value = x86_derived[metric]
        
        benchmark_data[f'prismchrono_{metric}'] = prismchrono_value
        benchmark_data[f'x86_{metric}'] = x86_value
        
        # Calculer le ratio pour les métriques dérivées
        if x86_value > 0:
            ratio = prismchrono_value / x86_value
            ratio_formatted = round(ratio, 4)
        else:
            if prismchrono_value > 0:
                ratio_formatted = float('inf')
            else:
                ratio_formatted = 0
                
        benchmark_data[f'ratio_{metric}'] = ratio_formatted
        
        # Afficher les métriques dérivées et ratios
        print(f"    {metric}: PrismChrono={prismchrono_value}, x86={x86_value}, Ratio={ratio_formatted}")
    
    combined_data.append(benchmark_data)
    
    # Incrémenter le compteur de succès si les deux plateformes ont des données
    if prismchrono_success and x86_success:
        success_count += 1

# Sauvegarder les données combinées au format JSON avec horodatage
json_file = COMBINED_RESULTS_DIR / f"combined_metrics_{TIMESTAMP}.json"
json_latest_file = COMBINED_RESULTS_DIR / "combined_metrics_latest.json"

try:
    with open(json_file, 'w') as f:
        json.dump(combined_data, f, indent=2)
    
    # Également sauvegarder une copie avec le nom "latest" pour faciliter l'accès
    with open(json_latest_file, 'w') as f:
        json.dump(combined_data, f, indent=2)
        
    print(f"\nDonnées JSON sauvegardées dans:\n  - {json_file}\n  - {json_latest_file}")
except Exception as e:
    print(f"Erreur lors de la sauvegarde du fichier JSON: {e}")

# Sauvegarder les données combinées au format CSV avec horodatage
csv_file = COMBINED_RESULTS_DIR / f"combined_metrics_{TIMESTAMP}.csv"
csv_latest_file = COMBINED_RESULTS_DIR / "combined_metrics_latest.csv"

try:
    # Déterminer les en-têtes
    headers = ['benchmark', 'category']
    
    # Ajouter les métriques de base
    for metric in metrics:
        headers.extend([f'prismchrono_{metric}', f'x86_{metric}', f'ratio_{metric}'])
    
    # Ajouter les métriques dérivées
    for metric in derived_metrics:
        headers.extend([f'prismchrono_{metric}', f'x86_{metric}', f'ratio_{metric}'])
    
    # Écrire le fichier CSV avec horodatage
    with open(csv_file, 'w', newline='') as f:
        writer = csv.DictWriter(f, fieldnames=headers)
        writer.writeheader()
        for data in combined_data:
            # Filtrer les clés pour ne garder que celles dans les en-têtes
            filtered_data = {k: v for k, v in data.items() if k in headers}
            writer.writerow(filtered_data)
    
    # Écrire le fichier CSV "latest"
    with open(csv_latest_file, 'w', newline='') as f:
        writer = csv.DictWriter(f, fieldnames=headers)
        writer.writeheader()
        for data in combined_data:
            filtered_data = {k: v for k, v in data.items() if k in headers}
            writer.writerow(filtered_data)
            
    print(f"Données CSV sauvegardées dans:\n  - {csv_file}\n  - {csv_latest_file}")
except Exception as e:
    print(f"Erreur lors de la sauvegarde du fichier CSV: {e}")

# Générer des statistiques globales
def generate_global_stats(combined_data):
    stats = {
        'total_benchmarks': len(combined_data),
        'standard_benchmarks': sum(1 for d in combined_data if d.get('category') == 'standard'),
        'ternary_specific_benchmarks': sum(1 for d in combined_data if d.get('category') == 'ternary_specific'),
        'avg_ratios': {}
    }
    
    # Calculer les ratios moyens pour chaque métrique
    for metric in metrics + derived_metrics:
        ratio_values = [d.get(f'ratio_{metric}', 0) for d in combined_data 
                      if d.get(f'ratio_{metric}', 0) != float('inf') and d.get(f'ratio_{metric}', 0) != 0]
        
        if ratio_values:
            stats['avg_ratios'][metric] = round(sum(ratio_values) / len(ratio_values), 4)
        else:
            stats['avg_ratios'][metric] = 0
    
    # Calculer les ratios moyens par catégorie
    stats['category_avg_ratios'] = {}
    for category in ['standard', 'ternary_specific']:
        stats['category_avg_ratios'][category] = {}
        for metric in metrics + derived_metrics:
            ratio_values = [d.get(f'ratio_{metric}', 0) for d in combined_data 
                          if d.get('category') == category 
                          and d.get(f'ratio_{metric}', 0) != float('inf') 
                          and d.get(f'ratio_{metric}', 0) != 0]
            
            if ratio_values:
                stats['category_avg_ratios'][category][metric] = round(sum(ratio_values) / len(ratio_values), 4)
            else:
                stats['category_avg_ratios'][category][metric] = 0
    
    return stats

# Calculer les statistiques globales
global_stats = generate_global_stats(combined_data)

# Sauvegarder les statistiques globales
stats_file = COMBINED_RESULTS_DIR / f"stats_{TIMESTAMP}.json"
stats_latest_file = COMBINED_RESULTS_DIR / "stats_latest.json"

try:
    with open(stats_file, 'w') as f:
        json.dump(global_stats, f, indent=2)
    
    with open(stats_latest_file, 'w') as f:
        json.dump(global_stats, f, indent=2)
        
    print(f"Statistiques globales sauvegardées dans:\n  - {stats_file}\n  - {stats_latest_file}")
except Exception as e:
    print(f"Erreur lors de la sauvegarde des statistiques: {e}")

# Résumé des résultats
print(f"\n=== Résumé de la combinaison des métriques ===")
print(f"Benchmarks traités avec succès: {success_count}/{total_count}")
print(f"Métriques de base collectées: {len(metrics)}")
print(f"Métriques dérivées calculées: {len(derived_metrics)}")
print(f"Fichiers de sortie générés: {COMBINED_RESULTS_DIR}")

# Afficher quelques statistiques globales
print("\n=== Statistiques globales ===")
print(f"Benchmarks standard: {global_stats['standard_benchmarks']}")
print(f"Benchmarks spécifiques ternaires: {global_stats['ternary_specific_benchmarks']}")
print("\nRatios moyens (PrismChrono/x86):")
for metric, value in global_stats['avg_ratios'].items():
    print(f"  {metric}: {value}")

print("\nRatios moyens par catégorie:")
for category, metrics_data in global_stats['category_avg_ratios'].items():
    print(f"  {category.capitalize()}:")
    for metric, value in metrics_data.items():
        print(f"    {metric}: {value}")

if success_count == total_count:
    print("\nCombination des métriques terminée avec succès!")
elif success_count > 0:
    print(f"\nCombination des métriques terminée avec des avertissements ({total_count - success_count} benchmarks incomplets)")
else:
    print("\nCombination des métriques terminée avec des erreurs (aucun benchmark complet)")
    sys.exit(1)

print("\nVous pouvez maintenant exécuter les scripts suivants:")
print("  - python3 generate_graphs.py  # Pour générer des graphiques comparatifs")
print("  - python3 generate_report.py  # Pour générer un rapport détaillé")