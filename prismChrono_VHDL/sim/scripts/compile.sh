#!/bin/bash

# Script de compilation pour les fichiers VHDL du projet PrismChrono
# Ce script compile tous les fichiers VHDL dans l'ordre de dépendance

# Définir le répertoire racine du projet
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# Vérifier si on demande une compilation incrémentale
INCREMENTAL=false
if [ "$1" == "--incremental" ]; then
    INCREMENTAL=true
    echo "Mode de compilation incrémentale activé"
fi

# Créer un répertoire pour les fichiers compilés si nécessaire
mkdir -p "$ROOT_DIR/sim/work"

# Fonction pour mettre à jour le fichier de dépendances
update_dependencies() {
    local src_file="$1"
    local base_name=$(basename "$src_file")
    local dep_file="$ROOT_DIR/sim/work/.dependencies"
    
    # Créer le fichier de dépendances s'il n'existe pas
    touch "$dep_file"
    
    # Extraire les dépendances (use clauses) du fichier source
    local deps=$(grep -i "use work\.\|use ieee\." "$src_file" | sed 's/.*use work\.\([a-zA-Z0-9_]*\).*/\1.vhd/g' | sort | uniq)
    
    # Mettre à jour le fichier de dépendances
    if [ -n "$deps" ]; then
        # Supprimer l'ancienne entrée pour ce fichier
        sed -i.bak "/^$base_name:/d" "$dep_file" 2>/dev/null || sed -i "" "/^$base_name:/d" "$dep_file"
        
        # Ajouter la nouvelle entrée
        echo "$base_name:$deps" >> "$dep_file"
    fi
}

# Fonction pour vérifier si un fichier a été modifié depuis la dernière compilation
needs_compilation() {
    local src_file="$1"
    local work_file="$ROOT_DIR/sim/work/work-obj08.cf"
    local dep_file="$ROOT_DIR/sim/work/.dependencies"
    
    # Si le fichier work-obj08.cf n'existe pas, on doit compiler
    if [ ! -f "$work_file" ]; then
        return 0 # Vrai, besoin de compilation
    fi
    
    # Si le fichier source est plus récent que le fichier de travail, on doit compiler
    if [ "$src_file" -nt "$work_file" ]; then
        return 0 # Vrai, besoin de compilation
    fi
    
    # Vérifier les dépendances (packages utilisés par ce fichier)
    # Si un package a été modifié, il faut recompiler les fichiers qui en dépendent
    if [ -f "$dep_file" ] && grep -q "$(basename "$src_file")" "$dep_file"; then
        # Extraire les dépendances pour ce fichier
        local deps=$(grep "$(basename "$src_file")" "$dep_file" | cut -d':' -f2)
        
        # Vérifier si une dépendance a été modifiée
        for dep in $deps; do
            if [ -f "$ROOT_DIR/rtl/pkg/$dep" ] && [ "$ROOT_DIR/rtl/pkg/$dep" -nt "$work_file" ]; then
                return 0 # Vrai, besoin de compilation car une dépendance a changé
            fi
        done
    fi
    
    return 1 # Faux, pas besoin de compilation
}

# Compiler les fichiers dans l'ordre de dépendance
echo "Compilation des fichiers VHDL..."

# 1. Package de types (doit être compilé en premier)
echo "Compilation du package de types..."

# Exécuter le script d'optimisation de la mémoire
echo "Optimisation de la mémoire avant compilation..."
SCRIPT_DIR="$(dirname "${BASH_SOURCE[0]}")" 
"$SCRIPT_DIR/optimize_memory.sh"

# Libérer la mémoire avant de compiler le package de types
if [ "$INCREMENTAL" = true ]; then
    echo "Libération supplémentaire de la mémoire avant compilation du package de types..."
    sync
    # Tenter de libérer les caches si on est root (dans le conteneur Docker)
    if [ "$(id -u)" -eq 0 ]; then
        echo 3 > /proc/sys/vm/drop_caches 2>/dev/null || echo "Impossible de libérer les caches (non-root)"
    fi
fi

# Utilisation de ulimit pour limiter la mémoire disponible avant d'exécuter GHDL
# Cette approche peut aider GHDL à mieux gérer sa mémoire
# Sur macOS, ulimit -v n'est pas supporté, donc on le désactive
if [ "$(uname)" != "Darwin" ]; then
    ulimit -v 16000000 2>/dev/null || echo "Impossible de définir la limite de mémoire virtuelle"
fi
ulimit -s 8192 2>/dev/null || echo "Impossible de définir la taille de pile"    # 8MB de taille de pile

# Configuration des variables d'environnement pour GHDL
export GHDL_DISABLE_LARGE_DESIGN=0
export GHDL_GC_PERIOD=50
export GHDL_MEMORY_MANAGEMENT="compact"

# Détection de macOS pour des optimisations spécifiques
if [ "$(uname)" = "Darwin" ]; then
    export GHDL_MACOS_COMPAT=1
    echo "Optimisations spécifiques pour macOS activées"
fi

# Libérer la mémoire avant de commencer la compilation
if [ "$(id -u)" -eq 0 ]; then
    sync
    echo 3 > /proc/sys/vm/drop_caches 2>/dev/null || echo "Impossible de libérer les caches (non-root)"
    echo "Mémoire libérée avant compilation"
fi

# Utilisation de l'option --ieee=synopsys pour réduire l'empreinte mémoire
# Ajout de l'option -Wno-hide pour réduire les avertissements et la charge mémoire
if needs_compilation "$ROOT_DIR/rtl/pkg/prismchrono_types_pkg.vhd" || [ "$INCREMENTAL" = false ]; then
    echo "  Compilation avec options optimisées pour la mémoire..."
    # Mettre à jour les dépendances avant la compilation
    update_dependencies "$ROOT_DIR/rtl/pkg/prismchrono_types_pkg.vhd"
    
    # Utiliser une approche progressive pour la compilation du package de types
    echo "Tentative de compilation avec options optimisées pour macOS..."
    
    # Première tentative avec options hautement optimisées pour macOS
    if [ "$(uname)" = "Darwin" ]; then
        echo "  Utilisation des optimisations spécifiques à macOS..."
        GHDL_MACOS_COMPAT=1 GHDL_DISABLE_LARGE_DESIGN=0 GHDL_GC_PERIOD=50 GHDL_MEMORY_MANAGEMENT="compact" \
        ghdl -a --std=08 --ieee=synopsys -Wno-hide --workdir="$ROOT_DIR/sim/work" "$ROOT_DIR/rtl/pkg/prismchrono_types_pkg.vhd"
    else
        # Première tentative avec options optimisées standard
        GHDL_DISABLE_LARGE_DESIGN=0 GHDL_GC_PERIOD=50 GHDL_MEMORY_MANAGEMENT="compact" \
        ghdl -a --std=08 --ieee=synopsys -Wno-hide --workdir="$ROOT_DIR/sim/work" "$ROOT_DIR/rtl/pkg/prismchrono_types_pkg.vhd"
    fi
    
    if [ $? -ne 0 ]; then
        echo "Erreur lors de la compilation du package de types"
        echo "Tentative avec options intermédiaires..."
        
        # Libérer de la mémoire avant la deuxième tentative
        if [ "$(id -u)" -eq 0 ]; then
            sync
            echo 3 > /proc/sys/vm/drop_caches 2>/dev/null || true
        fi
        
        # Deuxième tentative avec options intermédiaires
        GHDL_DISABLE_LARGE_DESIGN=0 GHDL_GC_PERIOD=100 \
        ghdl -a --std=08 --ieee=synopsys -Wno-hide --workdir="$ROOT_DIR/sim/work" "$ROOT_DIR/rtl/pkg/prismchrono_types_pkg.vhd"
        
        if [ $? -ne 0 ]; then
            echo "Tentative avec options légères..."
            
            # Libérer de la mémoire avant la troisième tentative
            if [ "$(id -u)" -eq 0 ]; then
                sync
                echo 3 > /proc/sys/vm/drop_caches 2>/dev/null || true
            fi
            
            # Troisième tentative avec options légères
            ghdl -a --std=08 --ieee=synopsys -Wno-hide --workdir="$ROOT_DIR/sim/work" "$ROOT_DIR/rtl/pkg/prismchrono_types_pkg.vhd"
            
            if [ $? -ne 0 ]; then
                echo "Tentative avec options minimales..."
                
                # Libérer de la mémoire avant la dernière tentative
                if [ "$(id -u)" -eq 0 ]; then
                    sync
                    echo 3 > /proc/sys/vm/drop_caches 2>/dev/null || true
                fi
                
                # Dernière tentative avec options minimales
                ghdl -a --std=08 --ieee=synopsys --workdir="$ROOT_DIR/sim/work" "$ROOT_DIR/rtl/pkg/prismchrono_types_pkg.vhd"
                
                if [ $? -ne 0 ]; then
                    echo "Échec de la compilation du package de types"
                    exit 1
                fi
            fi
        fi
    fi
    
    # Libérer la mémoire après la compilation du package de types
    if [ "$(id -u)" -eq 0 ]; then
        sync
        echo 1 > /proc/sys/vm/drop_caches 2>/dev/null || true
        echo "Mémoire libérée après compilation du package de types"
    fi
fi

# 2. Modules de base
echo "Compilation des modules de base..."

# Définir les options de compilation en fonction du mode
if [ "$INCREMENTAL" = true ]; then
    # Options optimisées pour la compilation incrémentale
    if [ "$(uname)" = "Darwin" ]; then
        # Options spécifiques pour macOS
        GHDL_OPTIONS="--std=08 --ieee=synopsys -Wno-hide"
        echo "  Utilisation des options optimisées pour macOS: $GHDL_OPTIONS"
        export GHDL_MACOS_COMPAT=1
    else
        # Options pour Linux
        GHDL_OPTIONS="--std=08 --ieee=synopsys -Wno-hide"
        echo "  Utilisation des options optimisées pour la mémoire: $GHDL_OPTIONS"
    fi
    
    # Libérer un peu de mémoire entre les compilations
    if [ "$(id -u)" -eq 0 ]; then
        sync
        echo 3 > /proc/sys/vm/drop_caches 2>/dev/null || true
    fi
    
    # Configuration des variables d'environnement pour la compilation incrémentale
    export GHDL_DISABLE_LARGE_DESIGN=0
    export GHDL_GC_PERIOD=50
    export GHDL_MEMORY_MANAGEMENT="compact"
else
    # Options standard
    GHDL_OPTIONS="--std=08 --ieee=synopsys -Wno-hide"
fi

# Fonction pour faire une pause entre les compilations et libérer la mémoire
pause_and_free_memory() {
    # Petite pause pour permettre au système de libérer la mémoire
    sleep 1
    
    # Libérer la mémoire si possible
    if [ "$(id -u)" -eq 0 ]; then
        sync
        echo 1 > /proc/sys/vm/drop_caches 2>/dev/null || true
    fi
    
    # Sur macOS, afficher un conseil si la mémoire semble faible
    if [ "$(uname)" = "Darwin" ]; then
        # Vérifier la mémoire libre approximative
        FREE_MEM=$(vm_stat | grep "Pages free" | awk '{print $3}' | sed 's/\.//')
        if [ -n "$FREE_MEM" ] && [ "$FREE_MEM" -lt 1000 ]; then
            echo "  Attention: Mémoire système faible, envisagez de fermer d'autres applications"
        fi
    fi
}

# Compilation incrémentale de l'inverseur ternaire
if needs_compilation "$ROOT_DIR/rtl/core/trit_inverter.vhd" || [ "$INCREMENTAL" = false ]; then
    echo "  Compilation de trit_inverter.vhd..."
    update_dependencies "$ROOT_DIR/rtl/core/trit_inverter.vhd"
    ghdl -a $GHDL_OPTIONS --workdir="$ROOT_DIR/sim/work" "$ROOT_DIR/rtl/core/trit_inverter.vhd"
    if [ $? -ne 0 ]; then
        echo "Erreur lors de la compilation de l'inverseur ternaire"
        exit 1
    fi
    
    # Pause après compilation réussie
    pause_and_free_memory
fi

# Compilation incrémentale de l'additionneur complet 1-trit
if needs_compilation "$ROOT_DIR/rtl/core/ternary_full_adder_1t.vhd" || [ "$INCREMENTAL" = false ]; then
    echo "  Compilation de ternary_full_adder_1t.vhd..."
    update_dependencies "$ROOT_DIR/rtl/core/ternary_full_adder_1t.vhd"
    ghdl -a $GHDL_OPTIONS --workdir="$ROOT_DIR/sim/work" "$ROOT_DIR/rtl/core/ternary_full_adder_1t.vhd"
    if [ $? -ne 0 ]; then
        echo "Erreur lors de la compilation de l'additionneur complet 1-trit"
        exit 1
    fi
    
    # Pause après compilation réussie
    pause_and_free_memory
fi

# Nouveaux modules du Sprint 2
# Compilation incrémentale de l'ALU 24 trits
if needs_compilation "$ROOT_DIR/rtl/core/alu_24t.vhd" || [ "$INCREMENTAL" = false ]; then
    echo "  Compilation de alu_24t.vhd..."
    update_dependencies "$ROOT_DIR/rtl/core/alu_24t.vhd"
    
    # Libération de mémoire avant compilation d'un module complexe
    if [ "$INCREMENTAL" = true ] && [ "$(id -u)" -eq 0 ]; then
        echo "  Libération de mémoire avant compilation de l'ALU..."
        sync
        echo 3 > /proc/sys/vm/drop_caches 2>/dev/null || true
    fi
    
    ghdl -a $GHDL_OPTIONS --workdir="$ROOT_DIR/sim/work" "$ROOT_DIR/rtl/core/alu_24t.vhd"
    if [ $? -ne 0 ]; then
        echo "Erreur lors de la compilation de l'ALU 24 trits"
        exit 1
    fi
    
    # Pause après compilation réussie
    pause_and_free_memory
fi

# Compilation incrémentale du banc de registres
if needs_compilation "$ROOT_DIR/rtl/core/register_file.vhd" || [ "$INCREMENTAL" = false ]; then
    echo "  Compilation de register_file.vhd..."
    update_dependencies "$ROOT_DIR/rtl/core/register_file.vhd"
    
    # Libération de mémoire avant compilation d'un module complexe
    if [ "$INCREMENTAL" = true ] && [ "$(id -u)" -eq 0 ]; then
        echo "  Libération de mémoire avant compilation du banc de registres..."
        sync
        echo 3 > /proc/sys/vm/drop_caches 2>/dev/null || true
    fi
    
    ghdl -a $GHDL_OPTIONS --workdir="$ROOT_DIR/sim/work" "$ROOT_DIR/rtl/core/register_file.vhd"
    if [ $? -ne 0 ]; then
        echo "Erreur lors de la compilation du banc de registres"
        exit 1
    fi
    
    # Pause après compilation réussie
    pause_and_free_memory
fi

# 3. Testbenches
echo "Compilation des testbenches..."

# Libérer de la mémoire avant de compiler les testbenches
if [ "$INCREMENTAL" = true ]; then
    echo "  Libération de mémoire avant compilation des testbenches..."
    sync
    if [ "$(id -u)" -eq 0 ]; then
        echo 3 > /proc/sys/vm/drop_caches 2>/dev/null || true
    fi
    
    # Sur macOS, suggérer de libérer de la mémoire manuellement
    if [ "$(uname)" = "Darwin" ]; then
        echo "  Sur macOS: Envisagez de fermer les applications inutilisées pour libérer de la mémoire"
        echo "  Pause de 3 secondes pour permettre au système de se stabiliser..."
        sleep 3
    fi
fi

# Compilation incrémentale du testbench pour le package de types
if needs_compilation "$ROOT_DIR/sim/testbenches/tb_prismchrono_types_pkg.vhd" || [ "$INCREMENTAL" = false ]; then
    echo "  Compilation de tb_prismchrono_types_pkg.vhd..."
    update_dependencies "$ROOT_DIR/sim/testbenches/tb_prismchrono_types_pkg.vhd"
    ghdl -a $GHDL_OPTIONS --workdir="$ROOT_DIR/sim/work" "$ROOT_DIR/sim/testbenches/tb_prismchrono_types_pkg.vhd"
    if [ $? -ne 0 ]; then
        echo "Erreur lors de la compilation du testbench pour le package de types"
        exit 1
    fi
fi

# Compilation incrémentale du testbench pour l'ALU 24 trits
if needs_compilation "$ROOT_DIR/sim/testbenches/tb_alu_24t.vhd" || [ "$INCREMENTAL" = false ]; then
    echo "  Compilation de tb_alu_24t.vhd..."
    update_dependencies "$ROOT_DIR/sim/testbenches/tb_alu_24t.vhd"
    ghdl -a $GHDL_OPTIONS --workdir="$ROOT_DIR/sim/work" "$ROOT_DIR/sim/testbenches/tb_alu_24t.vhd"
    if [ $? -ne 0 ]; then
        echo "Erreur lors de la compilation du testbench pour l'ALU 24 trits"
        exit 1
    fi
fi

# Compilation incrémentale du testbench pour le banc de registres
if needs_compilation "$ROOT_DIR/sim/testbenches/tb_register_file.vhd" || [ "$INCREMENTAL" = false ]; then
    echo "  Compilation de tb_register_file.vhd..."
    update_dependencies "$ROOT_DIR/sim/testbenches/tb_register_file.vhd"
    ghdl -a $GHDL_OPTIONS --workdir="$ROOT_DIR/sim/work" "$ROOT_DIR/sim/testbenches/tb_register_file.vhd"
    if [ $? -ne 0 ]; then
        echo "Erreur lors de la compilation du testbench pour le banc de registres"
        exit 1
    fi
fi

# Compilation incrémentale du testbench pour l'inverseur ternaire
if needs_compilation "$ROOT_DIR/sim/testbenches/tb_trit_inverter.vhd" || [ "$INCREMENTAL" = false ]; then
    echo "  Compilation de tb_trit_inverter.vhd..."
    update_dependencies "$ROOT_DIR/sim/testbenches/tb_trit_inverter.vhd"
    ghdl -a $GHDL_OPTIONS --workdir="$ROOT_DIR/sim/work" "$ROOT_DIR/sim/testbenches/tb_trit_inverter.vhd"
    if [ $? -ne 0 ]; then
        echo "Erreur lors de la compilation du testbench pour l'inverseur ternaire"
        exit 1
    fi
fi

# Compilation incrémentale du testbench pour l'additionneur complet 1-trit
if needs_compilation "$ROOT_DIR/sim/testbenches/tb_ternary_full_adder_1t.vhd" || [ "$INCREMENTAL" = false ]; then
    echo "  Compilation de tb_ternary_full_adder_1t.vhd..."
    update_dependencies "$ROOT_DIR/sim/testbenches/tb_ternary_full_adder_1t.vhd"
    ghdl -a $GHDL_OPTIONS --workdir="$ROOT_DIR/sim/work" "$ROOT_DIR/sim/testbenches/tb_ternary_full_adder_1t.vhd"
    if [ $? -ne 0 ]; then
        echo "Erreur lors de la compilation du testbench pour l'additionneur complet 1-trit"
        exit 1
    fi
fi

# Afficher des informations sur l'utilisation de la mémoire
echo "Compilation terminée avec succès"

# Afficher des statistiques sur l'utilisation de la mémoire
echo "\nInformations sur l'utilisation de la mémoire:"
if [ "$(id -u)" -eq 0 ]; then
    echo "État de la mémoire:"
    free -h || echo "Commande 'free' non disponible"
    
    echo "\nUtilisation du disque pour les fichiers de travail:"
    du -sh "$ROOT_DIR/sim/work" || echo "Commande 'du' non disponible"
    
    echo "\nNombre de fichiers dans le répertoire de travail:"
    find "$ROOT_DIR/sim/work" -type f | wc -l
fi