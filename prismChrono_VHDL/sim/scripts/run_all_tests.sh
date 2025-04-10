#!/bin/bash

# Script pour exécuter tous les testbenches du projet PrismChrono
# Ce script compile tous les fichiers VHDL puis exécute chaque testbench

# Définir le répertoire racine du projet
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# Créer un répertoire pour les fichiers VCD si nécessaire
mkdir -p "$ROOT_DIR/sim/vcd"

# Compiler tous les fichiers VHDL
echo "Compilation de tous les fichiers VHDL..."
"$ROOT_DIR/sim/scripts/compile.sh"
if [ $? -ne 0 ]; then
    echo "Erreur lors de la compilation des fichiers VHDL"
    exit 1
fi

# Liste des testbenches à exécuter
TESTBENCHES=(
    "tb_prismchrono_types_pkg"
    "tb_trit_inverter"
    "tb_ternary_full_adder_1t"
    "tb_alu_24t"
    "tb_register_file"
    "tb_prismchrono_core"
    "tb_memory_controller"
    "tb_pipeline_controller"
    "tb_csr_registers"
)

# Exécuter chaque testbench
echo "Exécution des testbenches..."
for tb in "${TESTBENCHES[@]}"; do
    echo "\nExécution du testbench $tb..."
    "$ROOT_DIR/sim/scripts/simulate.sh" "$tb" "${tb}.vcd"
    if [ $? -ne 0 ]; then
        echo "Erreur lors de l'exécution du testbench $tb"
        exit 1
    fi
done

echo "\nTous les testbenches ont été exécutés avec succès"
echo "Les fichiers VCD ont été générés dans $ROOT_DIR/sim/vcd/"
echo "Vous pouvez les visualiser avec GTKWave, par exemple:"
echo "gtkwave $ROOT_DIR/sim/vcd/tb_trit_inverter.vcd"

echo "\nFermeture du script et du conteneur Docker..."
# Sortie explicite pour fermer le conteneur automatiquement
exit 0