# Guide d'utilisation de cargo-make pour PrismChrono

## Installation

Cargo-make est déjà installé sur votre système. Si vous avez besoin de l'installer sur un autre système, utilisez la commande suivante :

```bash
cargo install cargo-make
```

## Utilisation

Cargo-make permet d'exécuter des tâches de build, test et autres opérations de manière cohérente et reproductible. Voici les principales commandes disponibles :

### Commandes de base

```bash
# Compiler tous les composants (assembleur et simulateur) en mode release
cargo make build

# Compiler en mode développement
cargo make dev

# Exécuter tous les tests
cargo make test

# Nettoyer les artefacts de compilation
cargo make clean

# Générer la documentation
cargo make doc
```

### Commandes spécifiques

```bash
# Compiler uniquement l'assembleur
cargo make build-asm

# Compiler uniquement le simulateur
cargo make build-sim

# Exécuter les tests de l'assembleur
cargo make test-asm

# Exécuter les tests du simulateur
cargo make test-sim
```

### Exécuter un exemple

Pour assembler et exécuter un exemple spécifique :

```bash
cargo make run-example --env EXAMPLE=nom_exemple
```

Par exemple, pour exécuter l'exemple "halt.s" :

```bash
cargo make run-example --env EXAMPLE=halt
```

### Exécuter les benchmarks

```bash
cargo make bench
```

### Installer les binaires

Pour installer les binaires compilés dans ~/.cargo/bin :

```bash
cargo make install
```

## Structure du Makefile.toml

Le fichier Makefile.toml à la racine du projet définit toutes les tâches disponibles. Il est organisé en sections :

- Configuration générale
- Tâches de compilation (build)
- Tâches de développement (dev)
- Tâches de test
- Tâches de nettoyage (clean)
- Tâches de documentation (doc)
- Tâches de benchmark
- Tâches d'exécution d'exemples
- Tâches d'installation

Vous pouvez facilement étendre ce fichier pour ajouter de nouvelles tâches selon vos besoins.