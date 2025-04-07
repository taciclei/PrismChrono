# PrismChrono VHDL Implementation

## 🎯 Objectif Principal

Ce projet vise à implémenter une version **matérielle** de l'architecture CPU ternaire **PrismChrono** en utilisant le langage de description matérielle **VHDL**, ciblant initialement les **FPGA** (Field-Programmable Gate Arrays), notamment la carte **OrangeCrab r0.2 (Lattice ECP5-85F)**.

L'objectif ultime n'est pas seulement de créer un CPU fonctionnel, mais d'**explorer et potentiellement de démontrer matériellement les avantages théoriques** de ses caractéristiques uniques :

1.  **Logique Ternaire Équilibrée ({N, Z, P}) :** Exploiter la densité d'information, la symétrie arithmétique, et le potentiel pour la logique multi-valuée.
2.  **Base 24 / Base 60 (via Trytes) :** Étudier l'efficacité de la manipulation native de ces bases pour des applications spécifiques (ex: temps, angles, encodages).
3.  **États Spéciaux Intégrés (`UNDEF`, `NULL`, `NaN`) :** Explorer une gestion matérielle robuste des erreurs et des cas limites.
4.  **ISA PrismChrono Riche :** Implémenter le jeu d'instructions défini (incluant potentiellement le format compact et les instructions ternaires spécialisées) pour évaluer son expressivité et son efficacité.

## 💡 Philosophie de Conception

*   **Simulation Ternaire sur Binaire :** L'implémentation sur FPGA utilisera la logique binaire sous-jacente pour *simuler* le comportement ternaire. Chaque trit sera typiquement encodé sur 2 bits. L'ALU, les registres et les bus internes opéreront sur ces représentations binaires.
*   **Modularité et Testabilité :** Le design sera décomposé en modules VHDL clairs (ALU, Registres, Contrôle, Mémoire, etc.), chacun avec son propre testbench pour une validation rigoureuse en simulation avant la synthèse.
*   **Approche Progressive :** Compte tenu de la complexité et des limites des ressources FPGA, l'implémentation sera **itérative**. Nous commencerons par un cœur minimal fonctionnel et ajouterons progressivement les fonctionnalités avancées (pipeline, MMU, caches, instructions spécialisées, support DDR3L) dans des sprints ultérieurs.
*   **Priorisation des Forces Ternaires/B24 :** Les choix de conception viseront, lorsque possible, à optimiser les opérations ou les structures de données qui bénéficient le plus de la logique ternaire ou de la base 24/60.
*   **Open Source :** L'ensemble du code VHDL, des testbenches, des scripts de synthèse et de la documentation sera open source pour encourager l'expérimentation et la collaboration.

## 🛠️ Environnement de Développement Cible (Initial)

*   **Langage HDL :** VHDL (probablement standard VHDL-2008).
*   **Carte FPGA Cible :** OrangeCrab r0.2 (Lattice ECP5-85F).
*   **Chaîne d'Outils Open Source :**
    *   **Simulation :** GHDL (pour VHDL).
    *   **Visualisation :** GTKWave (pour les fichiers VCD).
    *   **Synthèse :** Yosys.
    *   **Placement & Routage :** nextpnr (avec support ECP5).
    *   **Génération Bitstream :** Project Trellis (`ecppack`).
*   **Communication Hôte Initiale :** UART (via pont USB intégré à l'OrangeCrab ou autre carte) ou Soft USB Core (CDC-ACM) si les ressources le permettent dès le début.

## 🚀 Feuille de Route (Haut Niveau)

1.  **Fondations VHDL :** Définition des types ternaires encodés, modules de base (ALU simple, Registres).
2.  **Cœur CPU Minimal :** Intégration d'un CPU mono-cycle ou pipeline très simple, ISA de base (subset).
3.  **Interface Mémoire BRAM :** Accès à la mémoire interne du FPGA.
4.  **Interface E/S Simple :** Communication série (UART ou Soft USB).
5.  **Validation sur FPGA :** Exécution de petits programmes de test via l'interface série.
6.  **Extensions Progressives :** Ajout du pipeline complet, caches, MMU, instructions spécialisées, support DDR3L, etc., en fonction des ressources et priorités.
7.  **Benchmarking Matériel :** Mesure de la performance (fréquence max, utilisation ressources) et comparaison (si possible) avec des designs binaires équivalents sur la même plateforme FPGA.

## 📂 Structure du Dossier (Proposée)

```
prismChrono_VHDL/
├── README.md          # Ce fichier
├── doc/               # Documentation de conception VHDL, specs interfaces...
├── rtl/               # Code source VHDL (.vhd)
│   ├── pkg/           # Packages VHDL (ex: prismchrono_types_pkg.vhd)
│   ├── core/          # Modules du coeur CPU (alu, regfile, control, pipeline...)
│   ├── mem/           # Contrôleur mémoire (BRAM, DDR3...)
│   ├── io/            # Contrôleurs d'E/S (UART, USB Soft Core...)
│   └── top/           # Entité Top-Level pour le FPGA cible
├── sim/               # Simulation
│   ├── testbenches/   # Testbenches VHDL pour chaque module et top-level
│   ├── waveforms/     # (Optionnel) Scripts pour visualiser les VCD
│   └── scripts/       # Scripts pour lancer les simulations GHDL
├── constraints/       # Fichiers de contraintes pour la carte cible (ex: .lpf pour OrangeCrab)
├── synth/             # Scripts pour la synthèse (Yosys), P&R (nextpnr), bitstream (ecppack)
│   └── orangecrab/    # Scripts spécifiques à la cible OrangeCrab
└── sprints/            # Description des sprints de développement VHDL
    ├── sprint-1.md
    └── ...
```