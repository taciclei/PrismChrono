#!/usr/bin/env python3
# Script pour générer un rapport détaillé à partir des métriques combinées et des graphiques
# Sprint 13: Benchmarking Comparatif & Analyse Architecturale

import os
import json
import sys
import markdown
from pathlib import Path
from datetime import datetime
import shutil

# Définition des chemins
SCRIPT_DIR = Path(os.path.dirname(os.path.abspath(__file__)))
BENCHMARK_DIR = SCRIPT_DIR.parent
COMBINED_RESULTS_DIR = BENCHMARK_DIR / "results" / "raw" / "combined"
GRAPHS_DIR = BENCHMARK_DIR / "results" / "graphs"
REPORT_DIR = BENCHMARK_DIR / "results" / "reports"

# Créer le répertoire de rapports s'il n'existe pas
REPORT_DIR.mkdir(parents=True, exist_ok=True)
print(f"Répertoire de rapports vérifié/créé: {REPORT_DIR}")

# Horodatage pour les fichiers de sortie
TIMESTAMP = datetime.now().strftime("%Y%m%d_%H%M%S")

# Vérifier que les données et graphiques existent
COMBINED_DATA_FILE = COMBINED_RESULTS_DIR / "combined_metrics_latest.json"
STATS_FILE = COMBINED_RESULTS_DIR / "stats_latest.json"

if not COMBINED_DATA_FILE.exists():
    print(f"Erreur: Fichier de données combinées non trouvé: {COMBINED_DATA_FILE}")
    print("Veuillez d'abord exécuter le script combine_metrics.py")
    sys.exit(1)

if not GRAPHS_DIR.exists() or not any(GRAPHS_DIR.glob("*.png")):
    print(f"Avertissement: Aucun graphique trouvé dans {GRAPHS_DIR}")
    print("Veuillez d'abord exécuter le script generate_graphs.py")
    print("Le rapport sera généré sans graphiques")
    has_graphs = False
else:
    has_graphs = True

# Charger les données
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

# Charger la configuration pour obtenir les descriptions
CONFIG_FILE = SCRIPT_DIR / "config.json"
if not CONFIG_FILE.exists():
    print(f"Avertissement: Fichier de configuration non trouvé: {CONFIG_FILE}")
    config = {}
    benchmark_descriptions = {}
    metric_descriptions = {}
else:
    try:
        with open(CONFIG_FILE, 'r') as f:
            config = json.load(f)
        
        # Extraire les descriptions des benchmarks
        benchmark_descriptions = {}
        for category in ['standard', 'ternary_specific']:
            if category in config.get('benchmarks', {}):
                for benchmark in config['benchmarks'][category]:
                    benchmark_descriptions[benchmark['name']] = benchmark.get('description', '')
        
        # Extraire les descriptions des métriques
        metric_descriptions = {m['name']: m['description'] for m in config.get('metrics', [])}
        
        print(f"Configuration chargée depuis: {CONFIG_FILE}")
    except Exception as e:
        print(f"Avertissement: Erreur lors du chargement de la configuration: {e}")
        config = {}
        benchmark_descriptions = {}
        metric_descriptions = {}

# Extraire les métriques de base et dérivées
base_metrics = []
derived_metrics = ['inst_mem_ratio', 'inst_branch_ratio', 'branch_taken_ratio', 'code_density']

if combined_data and len(combined_data) > 0:
    # Identifier les métriques de base à partir des clés du premier élément
    first_item = combined_data[0]
    for key in first_item.keys():
        if key.startswith('ratio_'):
            metric_name = key[6:]  # Enlever 'ratio_'
            if metric_name not in derived_metrics and metric_name not in ['benchmark', 'platform', 'prismchrono_success', 'x86_success', 'category']:
                base_metrics.append(metric_name)

print(f"Métriques de base identifiées: {', '.join(base_metrics)}")
print(f"Métriques dérivées identifiées: {', '.join(derived_metrics)}")

# Fonction pour générer le rapport en Markdown
def generate_markdown_report():
    # Créer le contenu du rapport
    report = []
    
    # En-tête du rapport
    report.append("# Rapport de Benchmarking Comparatif PrismChrono vs x86")
    report.append(f"*Généré le {datetime.now().strftime('%d/%m/%Y à %H:%M:%S')}*")
    report.append("")
    
    # Introduction
    report.append("## Introduction")
    report.append("Ce rapport présente une analyse comparative des performances entre l'architecture ternaire PrismChrono et l'architecture binaire x86. ")
    report.append("Les benchmarks ont été exécutés sur les deux plateformes et les métriques ont été collectées pour permettre une comparaison directe.")
    report.append("")
    
    # Résumé des résultats
    report.append("## Résumé des Résultats")
    report.append(f"**Nombre total de benchmarks:** {stats['total_benchmarks']}")
    report.append(f"**Benchmarks standard:** {stats['standard_benchmarks']}")
    report.append(f"**Benchmarks spécifiques ternaires:** {stats['ternary_specific_benchmarks']}")
    report.append("")
    
    # Graphique de synthèse
    if has_graphs:
        report.append("### Ratios Moyens PrismChrono/x86")
        report.append("Le graphique ci-dessous présente les ratios moyens des métriques clés entre PrismChrono et x86, par catégorie de benchmark:")
        report.append("")
        report.append("![Ratios Moyens](../graphs/summary_ratios_latest.png)")
        report.append("")
    
    # Tableau des ratios moyens
    report.append("### Tableau des Ratios Moyens")
    report.append("| Métrique | Tous | Standard | Ternaire Spécifique |")
    report.append("| --- | ---: | ---: | ---: |")
    
    all_metrics = base_metrics + derived_metrics
    for metric in all_metrics:
        metric_desc = metric_descriptions.get(metric, metric)
        all_ratio = stats['avg_ratios'].get(metric, 0)
        std_ratio = stats['category_avg_ratios']['standard'].get(metric, 0)
        tern_ratio = stats['category_avg_ratios']['ternary_specific'].get(metric, 0)
        
        report.append(f"| {metric_desc} | {all_ratio:.4f} | {std_ratio:.4f} | {tern_ratio:.4f} |")
    
    report.append("")
    report.append("> Note: Un ratio < 1 indique que PrismChrono est plus performant que x86 pour cette métrique.")
    report.append("> Un ratio > 1 indique que x86 est plus performant que PrismChrono.")
    report.append("")
    
    # Analyse par catégorie de benchmark
    report.append("## Analyse par Catégorie de Benchmark")
    
    # Benchmarks standard
    report.append("### Benchmarks Standard")
    report.append("Les benchmarks standard permettent d'évaluer les performances générales de l'architecture PrismChrono par rapport à x86 sur des tâches communes.")
    report.append("")
    
    # Tableau des benchmarks standard
    standard_benchmarks = [b for b in combined_data if b.get('category') == 'standard']
    if standard_benchmarks:
        report.append("| Benchmark | Description | Ratio Inst | Ratio Mem Ops | Ratio Code Size |")
        report.append("| --- | --- | ---: | ---: | ---: |")
        
        for benchmark in standard_benchmarks:
            name = benchmark['benchmark']
            desc = benchmark_descriptions.get(name, '')
            inst_ratio = benchmark.get('ratio_instruction_count', 0)
            mem_ratio = (benchmark.get('ratio_memory_reads', 0) + benchmark.get('ratio_memory_writes', 0)) / 2 if 'ratio_memory_reads' in benchmark and 'ratio_memory_writes' in benchmark else 0
            size_ratio = benchmark.get('ratio_code_size', 0)
            
            report.append(f"| {name} | {desc} | {inst_ratio:.4f} | {mem_ratio:.4f} | {size_ratio:.4f} |")
        
        report.append("")
    
    # Graphiques pour benchmarks standard
    if has_graphs:
        report.append("#### Graphiques des Benchmarks Standard")
        for metric in base_metrics[:3]:  # Limiter à quelques métriques importantes
            report.append(f"**{metric_descriptions.get(metric, metric)}:**")
            report.append(f"![{metric}](../graphs/{metric}_standard_latest.png)")
            report.append("")
    
    # Benchmarks ternaires spécifiques
    report.append("### Benchmarks Ternaires Spécifiques")
    report.append("Les benchmarks ternaires spécifiques sont conçus pour mettre en évidence les avantages potentiels de l'architecture ternaire dans des cas d'utilisation particuliers.")
    report.append("")
    
    # Tableau des benchmarks ternaires
    ternary_benchmarks = [b for b in combined_data if b.get('category') == 'ternary_specific']
    if ternary_benchmarks:
        report.append("| Benchmark | Description | Ratio Inst | Ratio Mem Ops | Ratio Code Size |")
        report.append("| --- | --- | ---: | ---: | ---: |")
        
        for benchmark in ternary_benchmarks:
            name = benchmark['benchmark']
            desc = benchmark_descriptions.get(name, '')
            inst_ratio = benchmark.get('ratio_instruction_count', 0)
            mem_ratio = (benchmark.get('ratio_memory_reads', 0) + benchmark.get('ratio_memory_writes', 0)) / 2 if 'ratio_memory_reads' in benchmark and 'ratio_memory_writes' in benchmark else 0
            size_ratio = benchmark.get('ratio_code_size', 0)
            
            report.append(f"| {name} | {desc} | {inst_ratio:.4f} | {mem_ratio:.4f} | {size_ratio:.4f} |")
        
        report.append("")
    
    # Graphiques pour benchmarks ternaires
    if has_graphs:
        report.append("#### Graphiques des Benchmarks Ternaires Spécifiques")
        for metric in base_metrics[:3]:  # Limiter à quelques métriques importantes
            report.append(f"**{metric_descriptions.get(metric, metric)}:**")
            report.append(f"![{metric}](../graphs/{metric}_ternary_specific_latest.png)")
            report.append("")
    
    # Analyse des métriques dérivées
    report.append("## Analyse des Métriques Dérivées")
    report.append("Les métriques dérivées permettent d'évaluer l'efficacité relative des architectures au-delà des métriques brutes.")
    report.append("")
    
    # Description des métriques dérivées
    report.append("### Description des Métriques Dérivées")
    report.append("| Métrique | Description |")
    report.append("| --- | --- |")
    report.append("| inst_mem_ratio | Ratio Instructions / Opérations Mémoire - Mesure l'efficacité des instructions par rapport aux accès mémoire |")
    report.append("| inst_branch_ratio | Ratio Instructions / Branches - Mesure la densité des branchements dans le code |")
    report.append("| branch_taken_ratio | Ratio Branches Prises / Total Branches - Mesure l'efficacité de la prédiction de branchement |")
    report.append("| code_density | Densité du Code (Instructions / Taille) - Mesure l'efficacité de l'encodage des instructions |")
    report.append("")
    
    # Graphiques des métriques dérivées
    if has_graphs:
        report.append("### Graphiques des Métriques Dérivées")
        for metric in derived_metrics:
            report.append(f"**{metric}:**")
            report.append(f"![{metric}](../graphs/{metric}_all_latest.png)")
            report.append("")
    
    # Analyse détaillée par benchmark
    report.append("## Analyse Détaillée par Benchmark")
    
    for benchmark in combined_data:
        name = benchmark['benchmark']
        category = benchmark.get('category', 'unknown').capitalize()
        desc = benchmark_descriptions.get(name, '')
        
        report.append(f"### {name} ({category})")
        if desc:
            report.append(f"*{desc}*")
        report.append("")
        
        # Tableau des métriques pour ce benchmark
        report.append("| Métrique | PrismChrono | x86 | Ratio |")
        report.append("| --- | ---: | ---: | ---: |")
        
        # Métriques de base
        for metric in base_metrics:
            metric_desc = metric_descriptions.get(metric, metric)
            prism_value = benchmark.get(f'prismchrono_{metric}', 0)
            x86_value = benchmark.get(f'x86_{metric}', 0)
            ratio = benchmark.get(f'ratio_{metric}', 0)
            
            report.append(f"| {metric_desc} | {prism_value} | {x86_value} | {ratio:.4f} |")
        
        # Métriques dérivées
        for metric in derived_metrics:
            if f'prismchrono_{metric}' in benchmark:
                metric_desc = metric
                prism_value = benchmark.get(f'prismchrono_{metric}', 0)
                x86_value = benchmark.get(f'x86_{metric}', 0)
                ratio = benchmark.get(f'ratio_{metric}', 0)
                
                report.append(f"| {metric_desc} | {prism_value:.4f} | {x86_value:.4f} | {ratio:.4f} |")
        
        report.append("")
    
    # Conclusion
    report.append("## Conclusion")
    report.append("Cette analyse comparative entre PrismChrono et x86 met en évidence plusieurs points importants:")
    report.append("")
    
    # Analyser les résultats pour la conclusion
    better_metrics = [m for m in all_metrics if stats['avg_ratios'].get(m, 0) < 1]
    worse_metrics = [m for m in all_metrics if stats['avg_ratios'].get(m, 0) > 1]
    
    # Points forts de PrismChrono
    if better_metrics:
        report.append("### Points Forts de PrismChrono")
        report.append("PrismChrono montre des avantages dans les métriques suivantes:")
        for metric in better_metrics:
            metric_desc = metric_descriptions.get(metric, metric)
            ratio = stats['avg_ratios'].get(metric, 0)
            report.append(f"- **{metric_desc}**: Ratio moyen de {ratio:.4f} (PrismChrono est {(1-ratio)*100:.1f}% plus efficace)")
        report.append("")
    
    # Points à améliorer
    if worse_metrics:
        report.append("### Points à Améliorer")
        report.append("PrismChrono présente des performances inférieures dans les métriques suivantes:")
        for metric in worse_metrics:
            metric_desc = metric_descriptions.get(metric, metric)
            ratio = stats['avg_ratios'].get(metric, 0)
            report.append(f"- **{metric_desc}**: Ratio moyen de {ratio:.4f} (PrismChrono est {(ratio-1)*100:.1f}% moins efficace)")
        report.append("")
    
    # Avantages spécifiques ternaires
    ternary_better = []
    for metric in all_metrics:
        std_ratio = stats['category_avg_ratios']['standard'].get(metric, 0)
        tern_ratio = stats['category_avg_ratios']['ternary_specific'].get(metric, 0)
        if tern_ratio < std_ratio and tern_ratio < 1:
            ternary_better.append((metric, std_ratio, tern_ratio))
    
    if ternary_better:
        report.append("### Avantages Spécifiques Ternaires")
        report.append("Les benchmarks spécifiques ternaires montrent des avantages particuliers dans:")
        for metric, std_ratio, tern_ratio in ternary_better:
            metric_desc = metric_descriptions.get(metric, metric)
            report.append(f"- **{metric_desc}**: Ratio de {tern_ratio:.4f} pour les benchmarks ternaires vs {std_ratio:.4f} pour les benchmarks standard")
        report.append("")
    
    # Recommandations
    report.append("### Recommandations")
    report.append("Sur la base de cette analyse, voici quelques recommandations pour l'évolution de PrismChrono:")
    report.append("")
    report.append("1. **Optimisation des Points Faibles**: Concentrer les efforts d'optimisation sur les métriques où PrismChrono est moins performant.")
    report.append("2. **Exploitation des Avantages Ternaires**: Développer davantage les cas d'utilisation où l'architecture ternaire montre des avantages significatifs.")
    report.append("3. **Benchmarks Supplémentaires**: Créer des benchmarks plus spécifiques pour mieux évaluer les avantages potentiels de l'architecture ternaire.")
    report.append("4. **Analyse Approfondie**: Examiner en détail les benchmarks où PrismChrono surpasse x86 pour comprendre les facteurs contribuant à cette performance supérieure.")
    
    return "\n".join(report)

# Générer le rapport Markdown
print("\nGénération du rapport Markdown...")
markdown_content = generate_markdown_report()

# Sauvegarder le rapport Markdown
markdown_file = REPORT_DIR / f"benchmark_report_{TIMESTAMP}.md"
markdown_latest_file = REPORT_DIR / "benchmark_report_latest.md"

try:
    with open(markdown_file, 'w', encoding='utf-8') as f:
        f.write(markdown_content)
    
    with open(markdown_latest_file, 'w', encoding='utf-8') as f:
        f.write(markdown_content)
    
    print(f"Rapport Markdown sauvegardé dans:\n  - {markdown_file}\n  - {markdown_latest_file}")
except Exception as e:
    print(f"Erreur lors de la sauvegarde du rapport Markdown: {e}")

# Convertir le rapport en HTML si le module markdown est disponible
try:
    html_content = markdown.markdown(markdown_content, extensions=['tables'])
    
    # Ajouter un peu de style CSS
    html_style = """
    <style>
        body { font-family: Arial, sans-serif; line-height: 1.6; max-width: 1200px; margin: 0 auto; padding: 20px; }
        table { border-collapse: collapse; width: 100%; margin-bottom: 20px; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
        tr:nth-child(even) { background-color: #f9f9f9; }
        img { max-width: 100%; height: auto; }
        h1, h2, h3 { color: #333; }
        .container { display: flex; flex-wrap: wrap; }
        .metric-card { flex: 1; min-width: 300px; margin: 10px; padding: 15px; border: 1px solid #ddd; border-radius: 5px; }
    </style>
    """
    
    html_full = f"<!DOCTYPE html>\n<html>\n<head>\n<meta charset=\"UTF-8\">\n<title>Rapport de Benchmarking PrismChrono vs x86</title>\n{html_style}\n</head>\n<body>\n{html_content}\n</body>\n</html>"
    
    # Sauvegarder le rapport HTML
    html_file = REPORT_DIR / f"benchmark_report_{TIMESTAMP}.html"
    html_latest_file = REPORT_DIR / "benchmark_report_latest.html"
    
    with open(html_file, 'w', encoding='utf-8') as f:
        f.write(html_full)
    
    with open(html_latest_file, 'w', encoding='utf-8') as f:
        f.write(html_full)
    
    print(f"Rapport HTML sauvegardé dans:\n  - {html_file}\n  - {html_latest_file}")
    
    # Créer un répertoire pour les images si nécessaire
    if has_graphs:
        html_images_dir = REPORT_DIR / "images"
        html_images_dir.mkdir(exist_ok=True)
        
        # Copier les images des graphiques
        for graph_file in GRAPHS_DIR.glob("*_latest.png"):
            dest_file = html_images_dir / graph_file.name
            shutil.copy(graph_file, dest_file)
        
        print(f"Images copiées dans: {html_images_dir}")
except ImportError:
    print("Module 'markdown' non trouvé. Le rapport HTML n'a pas été généré.")
    print("Vous pouvez l'installer avec: pip install markdown")
except Exception as e:
    print(f"Erreur lors de la génération du rapport HTML: {e}")

print("\nGénération du rapport terminée avec succès!")
print(f"Tous les rapports ont été sauvegardés dans: {REPORT_DIR}")