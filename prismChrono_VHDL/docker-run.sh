#!/bin/bash

# Script pour construire et exécuter le conteneur Docker avec GHDL et GTKWave
# pour le projet PrismChrono VHDL

# Définir le répertoire racine du projet
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Construire l'image Docker
echo "Construction de l'image Docker pour PrismChrono VHDL..."
docker build -t prismchrono-vhdl "$ROOT_DIR"

# Vérifier si la construction a réussi
if [ $? -ne 0 ]; then
    echo "Erreur lors de la construction de l'image Docker"
    exit 1
fi

# Fonction pour exécuter une commande dans le conteneur
run_in_container() {
    # Ajout des options pour limiter la mémoire et les ressources du conteneur
    # --memory : limite la mémoire totale disponible pour le conteneur
    # --memory-swap : limite la mémoire + swap disponible
    # --cpus : limite le nombre de CPUs utilisables
    # --shm-size : augmente la taille de la mémoire partagée pour améliorer les performances
    # --ulimit : définit des limites de ressources système pour le conteneur
    # --rm : supprime automatiquement le conteneur après son exécution
    # --stop-timeout : force l'arrêt du conteneur après ce délai (en secondes)
    docker run --rm \
        --memory=16g \
        --memory-swap=20g \
        --cpus=6 \
        --shm-size=2g \
        --ulimit memlock=-1 \
        --ulimit stack=67108864 \
        --stop-timeout=30 \
        -v "$ROOT_DIR:/workspace" \
        -e "GHDL_MACOS_HOST=1" \
        prismchrono-vhdl "$@"
}

# Vérifier les arguments
if [ $# -eq 0 ]; then
    # Aucun argument, exécuter tous les tests
    echo "Exécution de tous les tests..."
    run_in_container /workspace/sim/scripts/run_all_tests.sh
else
    # Exécuter la commande spécifiée
    case "$1" in
        "compile")
            echo "Compilation des fichiers VHDL..."
            run_in_container /workspace/sim/scripts/compile.sh
            ;;
        "simulate")
            if [ $# -lt 3 ]; then
                echo "Usage: $0 simulate <testbench_name> <vcd_filename>"
                echo "Exemple: $0 simulate tb_trit_inverter trit_inverter.vcd"
                exit 1
            fi
            echo "Simulation du testbench $2..."
            run_in_container /workspace/sim/scripts/simulate.sh "$2" "$3"
            ;;
        "clean")
            echo "Nettoyage des fichiers de travail GHDL..."
            run_in_container /workspace/sim/scripts/clean.sh
            ;;
        "shell")
            echo "Démarrage d'un shell dans le conteneur..."
            docker run -it --rm \
                --memory=12g \
                --memory-swap=14g \
                --cpus=4 \
                --stop-timeout=30 \
                -v "$ROOT_DIR:/workspace" prismchrono-vhdl /bin/bash
            ;;
        "compile-incremental")
            echo "Compilation incrémentale des fichiers VHDL avec optimisations mémoire..."
            run_in_container /workspace/sim/scripts/compile.sh --incremental
            ;;
        "memory-clean")
            echo "Nettoyage des fichiers temporaires et libération de la mémoire..."
            run_in_container /workspace/sim/scripts/clean.sh --full
            ;;
        *)
            echo "Commande inconnue: $1"
            echo "Commandes disponibles: compile, compile-incremental, simulate, clean, memory-clean, shell"
            exit 1
            ;;
    esac
fi

echo "Terminé."