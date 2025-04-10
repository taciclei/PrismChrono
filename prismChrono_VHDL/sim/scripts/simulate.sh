#!/bin/bash

# Script de simulation pour les testbenches du projet PrismChrono
# Usage: ./simulate.sh <testbench_name> <vcd_filename>

# Vérifier les arguments
if [ $# -lt 2 ]; then
    echo "Usage: $0 <testbench_name> <vcd_filename>"
    echo "Exemple: $0 tb_trit_inverter trit_inverter.vcd"
    exit 1
 fi

# Définir le répertoire racine du projet
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# Récupérer les arguments
TESTBENCH_NAME=$1
VCD_FILENAME=$2

# Vérifier que le testbench existe
if [ ! -f "$ROOT_DIR/sim/testbenches/${TESTBENCH_NAME}.vhd" ]; then
    echo "Erreur: Le testbench ${TESTBENCH_NAME}.vhd n'existe pas dans $ROOT_DIR/sim/testbenches/"
    exit 1
fi

# Créer le répertoire pour les fichiers VCD si nécessaire
mkdir -p "$ROOT_DIR/sim/vcd"

# Élaborer le testbench
echo "Élaboration du testbench ${TESTBENCH_NAME}..."
ghdl -e --std=08 --workdir="$ROOT_DIR/sim/work" ${TESTBENCH_NAME}
if [ $? -ne 0 ]; then
    echo "Erreur lors de l'élaboration du testbench ${TESTBENCH_NAME}"
    exit 1
fi

# Exécuter le testbench avec génération du fichier VCD
echo "Exécution du testbench ${TESTBENCH_NAME} avec génération du fichier VCD ${VCD_FILENAME}..."
ghdl -r --std=08 --workdir="$ROOT_DIR/sim/work" ${TESTBENCH_NAME} --vcd="$ROOT_DIR/sim/vcd/${VCD_FILENAME}"
if [ $? -ne 0 ]; then
    echo "Erreur lors de l'exécution du testbench ${TESTBENCH_NAME}"
    exit 1
fi

echo "Simulation terminée avec succès"
echo "Fichier VCD généré: $ROOT_DIR/sim/vcd/${VCD_FILENAME}"