#!/bin/bash
# Script principal pour exécuter tous les benchmarks sur les deux plateformes

# Définition des chemins
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BENCHMARK_DIR="$(dirname "$SCRIPT_DIR")"
RESULTS_DIR="$BENCHMARK_DIR/results/raw"

# Couleurs pour les messages
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
RED="\033[0;31m"
NC="\033[0m" # No Color

echo -e "${GREEN}=== Démarrage de la campagne de benchmarking PrismChrono vs x86 ===${NC}"

# Vérifier que les répertoires nécessaires existent
mkdir -p "$BENCHMARK_DIR/results/raw/prismchrono"
mkdir -p "$BENCHMARK_DIR/results/raw/x86"
mkdir -p "$BENCHMARK_DIR/results/raw/combined"
mkdir -p "$BENCHMARK_DIR/results/graphs/instructions"
mkdir -p "$BENCHMARK_DIR/results/graphs/memory_access"
mkdir -p "$BENCHMARK_DIR/results/graphs/code_size"
mkdir -p "$BENCHMARK_DIR/results/graphs/branches"
mkdir -p "$BENCHMARK_DIR/results/graphs/ratios"
mkdir -p "$BENCHMARK_DIR/results/reports"

# Étape 1: Exécuter les benchmarks PrismChrono
echo -e "${YELLOW}Étape 1: Exécution des benchmarks PrismChrono...${NC}"
if [ -f "$SCRIPT_DIR/run_prismchrono.sh" ]; then
    bash "$SCRIPT_DIR/run_prismchrono.sh"
    if [ $? -ne 0 ]; then
        echo -e "${YELLOW}Avertissement: Erreur lors de l'exécution des benchmarks PrismChrono. Poursuite avec les benchmarks x86 uniquement.${NC}"
        # Créer un fichier JSON vide pour chaque benchmark PrismChrono attendu
        for benchmark in sum_array memcpy factorial ternary_logic; do
            echo '{"benchmark": "'$benchmark'", "instruction_count": 0, "memory_reads": 0, "memory_writes": 0, "code_size": 0, "branches": 0, "branches_taken": 0}' > "$RESULTS_DIR/prismchrono/$benchmark.json"
        done
    fi
else
    echo -e "${YELLOW}Avertissement: Le script run_prismchrono.sh n'existe pas. Poursuite avec les benchmarks x86 uniquement.${NC}"
    # Créer un fichier JSON vide pour chaque benchmark PrismChrono attendu
    for benchmark in sum_array memcpy factorial ternary_logic; do
        echo '{"benchmark": "'$benchmark'", "instruction_count": 0, "memory_reads": 0, "memory_writes": 0, "code_size": 0, "branches": 0, "branches_taken": 0}' > "$RESULTS_DIR/prismchrono/$benchmark.json"
    done
fi

# Étape 2: Exécuter les benchmarks x86
echo -e "${YELLOW}Étape 2: Exécution des benchmarks x86...${NC}"
if [ -f "$SCRIPT_DIR/run_x86.sh" ]; then
    bash "$SCRIPT_DIR/run_x86.sh"
    if [ $? -ne 0 ]; then
        echo -e "${RED}Erreur lors de l'exécution des benchmarks x86${NC}"
        exit 1
    fi
else
    echo -e "${RED}Le script run_x86.sh n'existe pas${NC}"
    exit 1
fi

# Étape 3: Combiner les métriques
echo -e "${YELLOW}Étape 3: Combinaison des métriques...${NC}"
if [ -f "$SCRIPT_DIR/combine_metrics.py" ]; then
    python3 "$SCRIPT_DIR/combine_metrics.py"
    if [ $? -ne 0 ]; then
        echo -e "${RED}Erreur lors de la combinaison des métriques${NC}"
        exit 1
    fi
else
    echo -e "${RED}Le script combine_metrics.py n'existe pas${NC}"
    exit 1
fi

# Étape 4: Générer les graphiques
echo -e "${YELLOW}Étape 4: Génération des graphiques...${NC}"
if [ -f "$SCRIPT_DIR/generate_graphs.py" ]; then
    python3 "$SCRIPT_DIR/generate_graphs.py"
    if [ $? -ne 0 ]; then
        echo -e "${RED}Erreur lors de la génération des graphiques${NC}"
        exit 1
    fi
else
    echo -e "${RED}Le script generate_graphs.py n'existe pas${NC}"
    exit 1
fi

# Étape 5: Générer le rapport
echo -e "${YELLOW}Étape 5: Génération du rapport...${NC}"
if [ -f "$SCRIPT_DIR/generate_report.py" ]; then
    python3 "$SCRIPT_DIR/generate_report.py"
    if [ $? -ne 0 ]; then
        echo -e "${RED}Erreur lors de la génération du rapport${NC}"
        exit 1
    fi
else
    echo -e "${RED}Le script generate_report.py n'existe pas${NC}"
    exit 1
fi

echo -e "${GREEN}=== Campagne de benchmarking terminée avec succès ===${NC}"
echo -e "${GREEN}Rapport disponible dans: $BENCHMARK_DIR/results/reports/benchmark_results_v1.md${NC}"

exit 0