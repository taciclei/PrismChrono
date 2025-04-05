#!/bin/bash
# Script pour exécuter les benchmarks x86

# Définition des chemins
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BENCHMARK_DIR="$(dirname "$SCRIPT_DIR")"
X86_DIR="$BENCHMARK_DIR/x86"
RESULTS_DIR="$BENCHMARK_DIR/results/raw/x86"

# Couleurs pour les messages
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
RED="\033[0;31m"
NC="\033[0m" # No Color

# Charger la configuration
CONFIG_FILE="$SCRIPT_DIR/config.json"
if [ ! -f "$CONFIG_FILE" ]; then
    echo -e "${RED}Erreur: Fichier de configuration non trouvé: $CONFIG_FILE${NC}"
    exit 1
fi

# Vérifier que les outils nécessaires sont installés
command -v gcc >/dev/null 2>&1 || { echo -e "${RED}Erreur: gcc n'est pas installé${NC}"; exit 1; }
command -v perf >/dev/null 2>&1 || { echo -e "${YELLOW}Avertissement: perf n'est pas installé, les métriques seront limitées${NC}"; }
command -v size >/dev/null 2>&1 || { echo -e "${YELLOW}Avertissement: size n'est pas installé, les métriques de taille de code seront indisponibles${NC}"; }

# Créer le répertoire de résultats s'il n'existe pas
mkdir -p "$RESULTS_DIR"

# Fonction pour exécuter un benchmark
run_benchmark() {
    local benchmark=$1
    local source_file="$X86_DIR/${benchmark}.c"
    local binary_file="$X86_DIR/${benchmark}.bin"
    local output_file="$RESULTS_DIR/${benchmark}.json"
    local size_file="$RESULTS_DIR/${benchmark}_size.txt"
    local perf_file="$RESULTS_DIR/${benchmark}_perf.txt"
    
    echo -e "${GREEN}Exécution du benchmark: $benchmark${NC}"
    
    # Vérifier que le fichier source existe
    if [ ! -f "$source_file" ]; then
        echo -e "${RED}Erreur: Fichier source non trouvé: $source_file${NC}"
        return 1
    fi
    
    # Compiler le fichier source
    echo -e "${YELLOW}  Compilation: $source_file -> $binary_file${NC}"
    gcc -O2 -Wall "$source_file" -o "$binary_file"
    if [ $? -ne 0 ]; then
        echo -e "${RED}Erreur lors de la compilation de $source_file${NC}"
        return 1
    fi
    
    # Mesurer la taille du code
    echo -e "${YELLOW}  Mesure de la taille du code${NC}"
    size "$binary_file" > "$size_file"
    if [ $? -ne 0 ]; then
        echo -e "${RED}Erreur lors de la mesure de la taille de $binary_file${NC}"
        return 1
    fi
    
    # Exécuter le binaire avec perf pour collecter les métriques
    echo -e "${YELLOW}  Exécution avec perf pour collecter les métriques${NC}"
    if command -v perf >/dev/null 2>&1; then
        perf stat -e instructions,L1-dcache-loads,L1-dcache-stores,branch-instructions,branch-misses -o "$perf_file" "$binary_file"
        if [ $? -ne 0 ]; then
            echo -e "${RED}Erreur lors de l'exécution de $binary_file avec perf${NC}"
            return 1
        fi
    else
        # Si perf n'est pas disponible, exécuter simplement le binaire
        "$binary_file" > /dev/null
        if [ $? -ne 0 ]; then
            echo -e "${RED}Erreur lors de l'exécution de $binary_file${NC}"
            return 1
        fi
        echo -e "${YELLOW}  Avertissement: perf n'est pas disponible, métriques limitées${NC}"
    fi
    
    # Extraire et formater les métriques dans un fichier JSON
    echo -e "${YELLOW}  Extraction et formatage des métriques${NC}"
    echo "{" > "$output_file"
    echo "  \"benchmark\": \"$benchmark\"," >> "$output_file"
    
    # Extraire la taille du code depuis le fichier size
    if [ -f "$size_file" ]; then
        text_size=$(grep -E "^.text" "$size_file" | awk '{print $2}')
        if [ -n "$text_size" ]; then
            echo "  \"code_size\": $text_size," >> "$output_file"
        else
            echo "  \"code_size\": 0," >> "$output_file"
        fi
    else
        echo "  \"code_size\": 0," >> "$output_file"
    fi
    
    # Extraire les métriques depuis le fichier perf
    if [ -f "$perf_file" ]; then
        # Instructions
        instr_count=$(grep -E "instructions" "$perf_file" | awk '{print $1}' | tr -d ',')
        if [ -n "$instr_count" ]; then
            echo "  \"instruction_count\": $instr_count," >> "$output_file"
        else
            echo "  \"instruction_count\": 0," >> "$output_file"
        fi
        
        # Lectures mémoire
        mem_reads=$(grep -E "L1-dcache-loads" "$perf_file" | awk '{print $1}' | tr -d ',')
        if [ -n "$mem_reads" ]; then
            echo "  \"memory_reads\": $mem_reads," >> "$output_file"
        else
            echo "  \"memory_reads\": 0," >> "$output_file"
        fi
        
        # Écritures mémoire
        mem_writes=$(grep -E "L1-dcache-stores" "$perf_file" | awk '{print $1}' | tr -d ',')
        if [ -n "$mem_writes" ]; then
            echo "  \"memory_writes\": $mem_writes," >> "$output_file"
        else
            echo "  \"memory_writes\": 0," >> "$output_file"
        fi
        
        # Branches
        branches=$(grep -E "branch-instructions" "$perf_file" | awk '{print $1}' | tr -d ',')
        if [ -n "$branches" ]; then
            echo "  \"branches\": $branches," >> "$output_file"
        else
            echo "  \"branches\": 0," >> "$output_file"
        fi
        
        # Branches prises (calculé à partir des branches et des branch-misses)
        branch_misses=$(grep -E "branch-misses" "$perf_file" | awk '{print $1}' | tr -d ',')
        if [ -n "$branches" ] && [ -n "$branch_misses" ]; then
            branches_taken=$((branches - branch_misses))
            echo "  \"branches_taken\": $branches_taken" >> "$output_file"
        else
            echo "  \"branches_taken\": 0" >> "$output_file"
        fi
    else
        # Si perf n'est pas disponible, mettre des valeurs par défaut
        echo "  \"instruction_count\": 0," >> "$output_file"
        echo "  \"memory_reads\": 0," >> "$output_file"
        echo "  \"memory_writes\": 0," >> "$output_file"
        echo "  \"branches\": 0," >> "$output_file"
        echo "  \"branches_taken\": 0" >> "$output_file"
    fi
    
    echo "}" >> "$output_file"
    
    echo -e "${GREEN}  Métriques sauvegardées dans: $output_file${NC}"
    return 0
}

# Exécuter tous les benchmarks standards
echo -e "${GREEN}=== Exécution des benchmarks standards ===${NC}"
for benchmark in sum_array memcpy factorial linear_search insertion_sort function_call; do
    if [ -f "$X86_DIR/${benchmark}.c" ]; then
        run_benchmark "$benchmark"
    else
        echo -e "${YELLOW}Avertissement: Benchmark $benchmark non trouvé, ignoré${NC}"
    fi
done

# Exécuter tous les benchmarks spécifiques ternaires
echo -e "${GREEN}=== Exécution des benchmarks spécifiques ternaires ===${NC}"
for benchmark in ternary_logic special_states base24_arithmetic; do
    if [ -f "$X86_DIR/${benchmark}.c" ]; then
        run_benchmark "$benchmark"
    else
        echo -e "${YELLOW}Avertissement: Benchmark $benchmark non trouvé, ignoré${NC}"
    fi
done

echo -e "${GREEN}=== Exécution des benchmarks x86 terminée ===${NC}"
exit 0