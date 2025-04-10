#!/bin/bash

# Script d'optimisation de la mémoire pour macOS avant la compilation VHDL
# Ce script libère la mémoire système et optimise les ressources pour GHDL

# Fonction pour afficher l'utilisation de la mémoire
show_memory_usage() {
    echo "\nUtilisation actuelle de la mémoire:"
    if [ "$(uname)" = "Darwin" ]; then
        # macOS
        vm_stat | perl -ne '/page size of (\d+)/ and $size=$1; /Pages free: (\d+)/ and printf("Mémoire libre: %.2f GB\n", $1 * $size / 1048576 / 1024)'
        top -l 1 -s 0 | grep PhysMem
    else
        # Linux
        free -h
    fi
}

# Afficher l'utilisation de la mémoire avant optimisation
echo "État de la mémoire avant optimisation:"
show_memory_usage

# Optimisations pour macOS
if [ "$(uname)" = "Darwin" ]; then
    echo "\nOptimisation de la mémoire pour macOS..."
    
    # Purger la mémoire inactive (nécessite les droits d'administrateur)
    echo "Tentative de purge de la mémoire inactive..."
    sudo purge 2>/dev/null || echo "Impossible de purger la mémoire (droits insuffisants)"
    
    # Fermer les applications en arrière-plan qui consomment beaucoup de mémoire
    echo "Conseil: Fermez les applications gourmandes en mémoire avant la compilation"
    
    # Optimisations pour Docker sur macOS
    if pgrep -q "Docker"; then
        echo "Docker détecté - Optimisation des ressources Docker..."
        echo "Conseil: Assurez-vous que Docker dispose d'au moins 16GB de mémoire dans ses préférences"
    fi
else
    # Optimisations pour Linux (dans le conteneur Docker)
    echo "\nOptimisation de la mémoire pour Linux..."
    
    # Libérer les caches si on est root
    if [ "$(id -u)" -eq 0 ]; then
        echo "Libération des caches système..."
        sync
        echo 3 > /proc/sys/vm/drop_caches 2>/dev/null || echo "Impossible de libérer les caches (non-root)"
        echo "Caches système libérés"
    fi
    
    # Optimiser les paramètres du noyau pour GHDL
    if [ -w /proc/sys/vm/overcommit_memory ]; then
        echo "Configuration de la politique de surengagement mémoire..."
        echo 1 > /proc/sys/vm/overcommit_memory
    fi
    
    if [ -w /proc/sys/vm/swappiness ]; then
        echo "Réduction de la swappiness pour améliorer les performances..."
        echo 10 > /proc/sys/vm/swappiness
    fi
fi

# Configurer les variables d'environnement pour GHDL
echo "\nConfiguration des variables d'environnement pour GHDL..."
export GHDL_DISABLE_LARGE_DESIGN=0
export GHDL_GC_PERIOD=50
export GHDL_MEMORY_MANAGEMENT="compact"

# Configurer ulimit pour limiter la mémoire virtuelle
echo "Configuration des limites de ressources système..."
ulimit -v 16000000 # 16GB de mémoire virtuelle
ulimit -s 32768    # 32MB de taille de pile

# Afficher l'utilisation de la mémoire après optimisation
echo "\nÉtat de la mémoire après optimisation:"
show_memory_usage

echo "\nOptimisation de la mémoire terminée"