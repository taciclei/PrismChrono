#!/bin/bash

# Script pour nettoyer les fichiers de travail GHDL
# Ce script supprime tous les fichiers générés par GHDL pour forcer une recompilation complète

# Définir le répertoire racine du projet
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# Vérifier si on demande un nettoyage complet
FULL_CLEAN=false
if [ "$1" == "--full" ]; then
    FULL_CLEAN=true
fi

# Supprimer les fichiers de travail
echo "Suppression des fichiers de travail GHDL..."
rm -rf "$ROOT_DIR/sim/work"/*

# Recréer le répertoire de travail
mkdir -p "$ROOT_DIR/sim/work"

# Si nettoyage complet demandé, supprimer aussi les fichiers VCD et autres fichiers temporaires
if [ "$FULL_CLEAN" = true ]; then
    echo "Nettoyage complet demandé, suppression des fichiers VCD..."
    rm -f "$ROOT_DIR/sim/vcd"/*.vcd
    
    # Libérer la mémoire système (cache)
    echo "Libération de la mémoire système..."
    sync  # Synchroniser les systèmes de fichiers
    
    # Afficher l'état de la mémoire avant/après
    echo "État de la mémoire avant libération:"
    free -h || echo "Commande 'free' non disponible"
    
    # Tenter de libérer les caches si on est root (dans le conteneur Docker)
    if [ "$(id -u)" -eq 0 ]; then
        echo 3 > /proc/sys/vm/drop_caches 2>/dev/null || echo "Impossible de libérer les caches (non-root)"
    fi
    
    echo "État de la mémoire après libération:"
    free -h || echo "Commande 'free' non disponible"
fi

echo "Nettoyage terminé. Vous pouvez maintenant recompiler le projet."