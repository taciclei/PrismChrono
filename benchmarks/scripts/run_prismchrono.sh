#!/bin/bash
# Script pour exécuter les benchmarks PrismChrono

# Définition des chemins
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BENCHMARK_DIR="$(dirname "$SCRIPT_DIR")"
PRISMCHRONO_DIR="$BENCHMARK_DIR/prismchrono"
RESULTS_DIR="$BENCHMARK_DIR/results/raw/prismchrono"

# Charger la configuration
CONFIG_FILE="$SCRIPT_DIR/config.json"
if [ ! -f "$CONFIG_FILE" ]; then
    echo "Erreur: Fichier de configuration non trouvé: $CONFIG_FILE"
    exit 1
fi

# Extraire les chemins des outils PrismChrono (à adapter selon la structure réelle du projet)
ASM_PATH="$(dirname "$BENCHMARK_DIR")/prismchrono_asm/target/release/prismchrono_asm"
SIM_PATH="$(dirname "$BENCHMARK_DIR")/prismChrono_sim/target/release/prismchrono_sim"

# Vérifier que les outils existent
if [ ! -f "$ASM_PATH" ]; then
    echo "Erreur: Assembleur PrismChrono non trouvé: $ASM_PATH"
    echo "Veuillez compiler l'assembleur avec 'cargo build --release' dans le répertoire prismchrono_asm"
    exit 1
fi

if [ ! -f "$SIM_PATH" ]; then
    echo "Erreur: Simulateur PrismChrono non trouvé: $SIM_PATH"
    echo "Veuillez compiler le simulateur avec 'cargo build --release' dans le répertoire prismChrono_sim"
    exit 1
fi

# Créer le répertoire de résultats s'il n'existe pas
mkdir -p "$RESULTS_DIR"

# Fonction pour exécuter un benchmark
run_benchmark() {
    local benchmark=$1
    local source_file="$PRISMCHRONO_DIR/${benchmark}.s"
    local binary_file="$PRISMCHRONO_DIR/${benchmark}.tbin"
    local output_file="$RESULTS_DIR/${benchmark}.json"
    
    echo "Exécution du benchmark: $benchmark"
    
    # Vérifier que le fichier source existe
    if [ ! -f "$source_file" ]; then
        echo "Erreur: Fichier source non trouvé: $source_file"
        return 1
    fi
    
    # Assembler le fichier source
    echo "  Assemblage: $source_file -> $binary_file"
    "$ASM_PATH" "$source_file" -o "$binary_file"
    if [ $? -ne 0 ]; then
        echo "Erreur lors de l'assemblage de $source_file"
        return 1
    fi
    
    # Exécuter le binaire sur le simulateur avec instrumentation
    echo "  Exécution sur le simulateur avec instrumentation"
    "$SIM_PATH" "$binary_file" --metrics > "$output_file"
    if [ $? -ne 0 ]; then
        echo "Erreur lors de l'exécution de $binary_file sur le simulateur"
        return 1
    fi
    
    echo "  Métriques sauvegardées dans: $output_file"
    return 0
}

# Exécuter les benchmarks standard
echo "Exécution des benchmarks standard..."
for benchmark in sum_array memcpy factorial linear_search insertion_sort function_call; do
    run_benchmark "$benchmark"
done

# Exécuter les benchmarks spécifiques ternaires
echo "Exécution des benchmarks spécifiques ternaires..."
for benchmark in ternary_logic trit_operations branch3_decision branch3_predictor tvpu_operations tvpu_astro_benchmark compact_format optimized_memory base24_arithmetic special_states base60_arithmetic; do
    run_benchmark "$benchmark"
done

echo "=== Exécution des benchmarks PrismChrono terminée ==="
exit 0