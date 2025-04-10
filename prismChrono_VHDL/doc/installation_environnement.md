# Guide d'Installation de l'Environnement VHDL pour PrismChrono

## Introduction

Ce document explique comment installer et configurer l'environnement de développement VHDL nécessaire pour le projet PrismChrono. Les outils principaux requis sont GHDL (simulateur VHDL) et GTKWave (visualiseur de formes d'onde).

## Prérequis

- Un système d'exploitation compatible (Linux, macOS, Windows)
- Droits d'administrateur pour installer des logiciels
- Connexion Internet pour télécharger les outils

## Installation de GHDL

### Sur macOS

1. **Via Homebrew** (recommandé)
   ```bash
   brew install ghdl
   ```

2. **Compilation depuis les sources**
   ```bash
   git clone https://github.com/ghdl/ghdl.git
   cd ghdl
   ./configure --prefix=/usr/local
   make
   sudo make install
   ```

### Sur Linux

1. **Ubuntu/Debian**
   ```bash
   sudo apt-get update
   sudo apt-get install ghdl
   ```

2. **Fedora/CentOS**
   ```bash
   sudo dnf install ghdl
   ```

### Sur Windows

1. **Télécharger l'installateur** depuis le [site officiel de GHDL](https://github.com/ghdl/ghdl/releases)
2. Exécuter l'installateur et suivre les instructions
3. Ajouter le chemin d'installation à la variable d'environnement PATH

## Installation de GTKWave

### Sur macOS

1. **Via Homebrew** (recommandé)
   ```bash
   brew install gtkwave
   ```

### Sur Linux

1. **Ubuntu/Debian**
   ```bash
   sudo apt-get update
   sudo apt-get install gtkwave
   ```

2. **Fedora/CentOS**
   ```bash
   sudo dnf install gtkwave
   ```

### Sur Windows

1. **Télécharger l'installateur** depuis le [site officiel de GTKWave](https://sourceforge.net/projects/gtkwave/files/)
2. Exécuter l'installateur et suivre les instructions
3. Ajouter le chemin d'installation à la variable d'environnement PATH

## Vérification de l'Installation

Pour vérifier que GHDL et GTKWave sont correctement installés, ouvrez un terminal et exécutez les commandes suivantes :

```bash
ghdl --version
gtkwave --version
```

Si les commandes affichent les informations de version, l'installation est réussie.

## Configuration de l'Éditeur

### VSCode

1. Installer l'extension "VHDL" par Pu Zhao ou "VHDL LS" pour la coloration syntaxique et l'autocomplétion
2. Configurer les chemins vers GHDL dans les paramètres de l'extension

### Autres Éditeurs

- **Sublime Text** : Installer le package "VHDL" via Package Control
- **Atom** : Installer le package "language-vhdl"
- **Vim/Neovim** : Utiliser des plugins comme "vim-vhdl" ou "vim-polyglot"

## Structure du Projet

La structure du projet PrismChrono_VHDL est déjà en place avec les dossiers suivants :

```
prismChrono_VHDL/
├── README.md
├── doc/
├── rtl/
│   ├── pkg/
│   ├── core/
│   └── ...
├── sim/
│   ├── testbenches/
│   ├── scripts/
│   └── ...
└── ...
```

## Utilisation des Scripts

Une fois GHDL et GTKWave installés, vous pouvez utiliser les scripts fournis :

1. **Compilation** : Compile tous les fichiers VHDL dans l'ordre de dépendance
   ```bash
   cd prismChrono_VHDL/sim/scripts
   ./compile.sh
   ```

2. **Simulation** : Exécute un testbench spécifique et génère un fichier VCD
   ```bash
   ./simulate.sh tb_trit_inverter trit_inverter.vcd
   ```

3. **Visualisation** : Ouvre le fichier VCD généré avec GTKWave
   ```bash
   gtkwave ../vcd/trit_inverter.vcd
   ```

## Conclusion

Une fois ces outils installés, vous serez en mesure de compiler, simuler et visualiser les résultats des modules VHDL du projet PrismChrono. Pour toute question ou problème d'installation, veuillez consulter la documentation officielle des outils ou ouvrir une issue dans le dépôt du projet.