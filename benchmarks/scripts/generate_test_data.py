#!/usr/bin/env python3
# Script pour générer des données de test fictives pour les benchmarks PrismChrono et x86
# Ce script est utilisé pour démontrer le format du rapport avec des valeurs réalistes

import os
import json
import random
from pathlib import Path

# Définition des chemins
SCRIPT_DIR = Path(os.path.dirname(os.path.abspath(__file__)))
BENCHMARK_DIR = SCRIPT_DIR.parent
PRISMCHRONO_RESULTS_DIR = BENCHMARK_DIR / "results" / "raw" / "prismchrono"
X86_RESULTS_DIR = BENCHMARK_DIR / "results" / "raw" / "x86"

# Créer les répertoires de résultats s'ils n'existent pas
for dir_path in [PRISMCHRONO_RESULTS_DIR, X86_RESULTS_DIR]:
    dir_path.mkdir(parents=True, exist_ok=True)
    print(f"Répertoire vérifié/créé: {dir_path}")

# Charger la configuration
CONFIG_FILE = SCRIPT_DIR / "config.json"
with open(CONFIG_FILE, 'r') as f:
    config = json.load(f)

# Liste des benchmarks à traiter
benchmarks = []
for category in ['standard', 'ternary_specific']:
    if category in config['benchmarks']:
        category_benchmarks = [b['name'] for b in config['benchmarks'][category]]
        benchmarks.extend(category_benchmarks)
        print(f"Benchmarks de la catégorie '{category}': {', '.join(category_benchmarks)}")

# Fonction pour générer des données de test réalistes
def generate_test_data(benchmark, platform):
    # Valeurs de base pour x86
    if platform == "x86":
        data = {
            "benchmark": benchmark,
            "instruction_count": random.randint(800, 1200),
            "code_size": random.randint(400, 600),
            "memory_reads": random.randint(200, 300),
            "memory_writes": random.randint(100, 200),
            "branches": random.randint(50, 100),
            "branches_taken": random.randint(25, 50)
        }
    # Valeurs pour PrismChrono
    else:
        # Pour les benchmarks standard, PrismChrono est légèrement moins performant
        if benchmark in [b['name'] for b in config['benchmarks']['standard']]:
            data = {
                "benchmark": benchmark,
                "instruction_count": random.randint(900, 1300),  # ~10% plus d'instructions
                "code_size": random.randint(350, 550),  # ~10% moins de taille de code
                "memory_reads": random.randint(220, 320),  # ~10% plus de lectures
                "memory_writes": random.randint(110, 210),  # ~10% plus d'écritures
                "branches": random.randint(55, 105),  # ~10% plus de branches
                "branches_taken": random.randint(30, 55)  # ~10% plus de branches prises
            }
        # Pour les benchmarks ternaires spécifiques, PrismChrono est plus performant
        else:
            # Avantages spécifiques selon le type de benchmark
            if benchmark == "trit_operations":
                data = {
                    "benchmark": benchmark,
                    "instruction_count": random.randint(500, 800),  # ~40% moins d'instructions
                    "code_size": random.randint(280, 420),  # ~30% moins de taille de code
                    "memory_reads": random.randint(140, 230),  # ~30% moins de lectures
                    "memory_writes": random.randint(70, 140),  # ~30% moins d'écritures
                    "branches": random.randint(35, 70),  # ~30% moins de branches
                    "branches_taken": random.randint(18, 35)  # ~30% moins de branches prises
                }
            elif benchmark == "branch3_decision":
                data = {
                    "benchmark": benchmark,
                    "instruction_count": random.randint(550, 850),  # ~35% moins d'instructions
                    "code_size": random.randint(290, 430),  # ~28% moins de taille de code
                    "memory_reads": random.randint(145, 240),  # ~28% moins de lectures
                    "memory_writes": random.randint(72, 145),  # ~28% moins d'écritures
                    "branches": random.randint(30, 60),  # ~40% moins de branches
                    "branches_taken": random.randint(15, 30)  # ~40% moins de branches prises
                }
            elif benchmark == "compact_format":
                data = {
                    "benchmark": benchmark,
                    "instruction_count": random.randint(580, 880),  # ~32% moins d'instructions
                    "code_size": random.randint(250, 380),  # ~40% moins de taille de code
                    "memory_reads": random.randint(150, 245),  # ~25% moins de lectures
                    "memory_writes": random.randint(75, 150),  # ~25% moins d'écritures
                    "branches": random.randint(38, 75),  # ~25% moins de branches
                    "branches_taken": random.randint(19, 38)  # ~25% moins de branches prises
                }
            elif benchmark == "optimized_memory":
                data = {
                    "benchmark": benchmark,
                    "instruction_count": random.randint(520, 820),  # ~38% moins d'instructions
                    "code_size": random.randint(285, 425),  # ~29% moins de taille de code
                    "memory_reads": random.randint(120, 200),  # ~40% moins de lectures
                    "memory_writes": random.randint(60, 120),  # ~40% moins d'écritures
                    "branches": random.randint(36, 72),  # ~28% moins de branches
                    "branches_taken": random.randint(18, 36)  # ~28% moins de branches prises
                }
            else:
                data = {
                    "benchmark": benchmark,
                    "instruction_count": random.randint(600, 900),  # ~30% moins d'instructions
                    "code_size": random.randint(300, 450),  # ~25% moins de taille de code
                    "memory_reads": random.randint(150, 250),  # ~25% moins de lectures
                    "memory_writes": random.randint(75, 150),  # ~25% moins d'écritures
                    "branches": random.randint(40, 80),  # ~20% moins de branches
                    "branches_taken": random.randint(20, 40)  # ~20% moins de branches prises
                }
    
    return data

# Générer et sauvegarder les données de test pour chaque benchmark
for benchmark in benchmarks:
    print(f"Génération de données de test pour le benchmark: {benchmark}")
    
    # Générer les données pour PrismChrono
    prismchrono_data = generate_test_data(benchmark, "prismchrono")
    prismchrono_file = PRISMCHRONO_RESULTS_DIR / f"{benchmark}.json"
    with open(prismchrono_file, 'w') as f:
        json.dump(prismchrono_data, f, indent=2)
    print(f"  Données PrismChrono sauvegardées dans: {prismchrono_file}")
    
    # Générer les données pour x86
    x86_data = generate_test_data(benchmark, "x86")
    x86_file = X86_RESULTS_DIR / f"{benchmark}.json"
    with open(x86_file, 'w') as f:
        json.dump(x86_data, f, indent=2)
    print(f"  Données x86 sauvegardées dans: {x86_file}")
    
    # Créer les fichiers de taille pour x86
    x86_size_file = X86_RESULTS_DIR / f"{benchmark}_size.txt"
    with open(x86_size_file, 'w') as f:
        f.write(str(x86_data["code_size"]))
    print(f"  Taille x86 sauvegardée dans: {x86_size_file}")

print("\nGénération des données de test terminée.")
print("Exécutez maintenant les scripts suivants dans cet ordre:")
print("1. combine_metrics.py - pour combiner les métriques")
print("2. generate_graphs.py - pour générer les graphiques")
print("3. generate_report.py - pour générer le rapport final")