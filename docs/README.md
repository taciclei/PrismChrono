# Documentation PrismChrono

Bienvenue dans la documentation du projet PrismChrono, une architecture ternaire innovante utilisant une logique à trois états au lieu de la logique binaire traditionnelle.

## Contenu de la Documentation

Cette documentation est organisée en plusieurs sections pour vous aider à comprendre et à utiliser le projet PrismChrono :

### Guides Généraux

- [Guide d'Utilisation des Benchmarks](./guide_utilisation.md) - Comment exécuter et interpréter les benchmarks
- [Guide de Benchmarking](./benchmarking_guide.md) - Documentation détaillée du système de benchmarking

### Documentation Technique

- [Architecture Technique](./architecture_technique.md) - Description détaillée de l'architecture PrismChrono
- [Système de Privilèges v0.1](./privilege_system_v0.1.md) - Documentation du système de privilèges (version 0.1)
- [Système de Privilèges v0.2](./privilege_system_v0.2.md) - Documentation du système de privilèges (version 0.2)

## Structure du Projet

Le projet PrismChrono est organisé en plusieurs composants :

- **prismchrono_asm/** - Assembleur pour l'architecture PrismChrono
- **prismChrono_sim/** - Simulateur de l'architecture PrismChrono
- **benchmarks/** - Système de benchmarking comparatif
- **docs/** - Documentation du projet
- **spec/** - Spécifications de l'architecture

## Démarrage Rapide

Pour commencer à utiliser PrismChrono :

1. Compilez l'assembleur et le simulateur :
   ```bash
   # Compiler l'assembleur
   cd prismchrono_asm
   cargo build --release
   
   # Compiler le simulateur
   cd ../prismChrono_sim
   cargo build --release
   ```

2. Exécutez les benchmarks :
   ```bash
   ./benchmarks/scripts/run_all.sh
   ```

3. Consultez les résultats :
   ```bash
   open benchmarks/results/reports/benchmark_report_latest.html
   ```

## Contribuer au Projet

Si vous souhaitez contribuer au projet PrismChrono, consultez les spécifications dans le répertoire `spec/` et les documents de planification des sprints dans le répertoire `sprints/`.

## Licence

Consultez le fichier LICENSE à la racine du projet pour les informations de licence.