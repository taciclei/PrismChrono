#!/usr/bin/env bash
# Script de build pour PrismChrono
# Ce script sert de wrapper pour cargo-make

set -e

# Vérifier si cargo-make est installé
if ! command -v cargo-make &> /dev/null; then
    echo "cargo-make n'est pas installé. Installation en cours..."
    cargo install cargo-make
fi

# Fonction d'aide
show_help() {
    echo "Usage: ./build.sh [commande] [options]"
    echo ""
    echo "Commandes disponibles:"
    echo "  build         Compile tous les composants en mode release"
    echo "  dev           Compile tous les composants en mode développement"
    echo "  test          Exécute tous les tests"
    echo "  clean         Nettoie les artefacts de compilation"
    echo "  doc           Génère la documentation"
    echo "  bench         Exécute les benchmarks"
    echo "  run-example   Assemble et exécute un exemple (utiliser --example=nom_exemple)"
    echo "  install       Installe les binaires dans ~/.cargo/bin"
    echo "  help          Affiche cette aide"
    echo ""
    echo "Options spécifiques:"
    echo "  --example=nom  Spécifie le nom de l'exemple à exécuter (sans l'extension .s)"
    echo ""
    echo "Exemples:"
    echo "  ./build.sh build"
    echo "  ./build.sh run-example --example=halt"
}

# Traiter les arguments
COMMAND=""
EXAMPLE=""

for arg in "$@"; do
    if [[ $arg == --example=* ]]; then
        EXAMPLE="${arg#*=}"
    elif [[ $arg == "help" || $arg == "-h" || $arg == "--help" ]]; then
        show_help
        exit 0
    elif [[ -z "$COMMAND" ]]; then
        COMMAND="$arg"
    fi
done

# Exécuter la commande appropriée
case "$COMMAND" in
    build)
        cargo make build
        ;;
    dev)
        cargo make dev
        ;;
    test)
        cargo make test
        ;;
    clean)
        cargo make clean
        ;;
    doc)
        cargo make doc
        ;;
    bench)
        cargo make bench
        ;;
    run-example)
        if [[ -z "$EXAMPLE" ]]; then
            echo "Erreur: Veuillez spécifier un exemple avec --example=nom_exemple"
            exit 1
        fi
        cargo make run-example --env EXAMPLE="$EXAMPLE"
        ;;
    install)
        cargo make install
        ;;
    "")
        show_help
        ;;
    *)
        echo "Commande inconnue: $COMMAND"
        show_help
        exit 1
        ;;
esac