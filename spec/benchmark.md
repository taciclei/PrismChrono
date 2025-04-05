Ces benchmarks sont inspirés de ceux utilisés dans des suites comme MiBench, CoreMark, ou simplement des algorithmes fondamentaux. L'idée est de choisir des tâches suffisamment simples pour être écrites manuellement en assembleur LGBT+ mais assez représentatives pour tester différents aspects de l'architecture.

---

**Benchmarks Kernels Suggérés :**

1.  **Summation d'un Tableau (Integer)**
    *   **Tâche :** Calculer la somme de tous les éléments d'un tableau d'entiers (représentés par des `Word` de 24 trits sur LGBT+).
    *   **Implémentation LGBT+ :** Boucle chargeant chaque `Word` du tableau, l'ajoutant à un accumulateur (registre), mise à jour du pointeur/index, test de fin de boucle.
    *   **Implémentation x86 :** Code C/Rust simple avec une boucle `for` ou `while`. Compilation avec `gcc` ou `rustc`.
    *   **Variante :** Utiliser des `Tryte` au lieu de `Word` pour tester `LOADT`/`LOADTU`.

2.  **Copie de Mémoire (Memory)**
    *   **Tâche :** Copier un bloc de mémoire d'une zone source vers une zone destination.
    *   **Implémentation LGBT+ :** Boucle utilisant `LOADW`/`STOREW` (ou `LOADT`/`STORET`) pour transférer les données. Gestion des pointeurs source/destination.
    *   **Implémentation x86 :** Utilisation de `memcpy` (optimisé) ou une boucle manuelle en C/Rust.

3.  **Factorielle (Itérative - Arithmetic/Control Flow)**
    *   **Tâche :** Calculer `n!` de manière itérative.
    *   **Implémentation LGBT+ :** Boucle décrémentant `n`, multipliant le résultat courant (si `MUL` existe, sinon simulation via additions/décalages), test de condition `n > 0`.
    *   **Implémentation x86 :** Boucle `for` ou `while` en C/Rust.

4.  **Recherche Linéaire dans un Tableau (Memory/Control Flow)**
    *   **Tâche :** Trouver la première occurrence d'une valeur spécifique dans un tableau.
    *   **Implémentation LGBT+ :** Boucle chargeant chaque élément, comparaison (`CMP`/`SUB`) avec la valeur cible, branchement conditionnel (`BRANCH EQ`) si trouvé, gestion du pointeur/index et de la fin de boucle.
    *   **Implémentation x86 :** Boucle `for`/`while` avec un `if` et `break`.

5.  **Tri par Insertion Simple (Algorithm - Mixte)**
    *   **Tâche :** Trier un petit tableau d'entiers en utilisant le tri par insertion.
    *   **Implémentation LGBT+ :** Boucles imbriquées, comparaisons (`CMP`/`SLT`), branchements (`BRANCH`), échanges d'éléments en mémoire (`LOADW`/`STOREW`).
    *   **Implémentation x86 :** Implémentation standard en C/Rust.

6.  **Appel de Fonction Simple (Control Flow/Stack)**
    *   **Tâche :** Une fonction `main` appelle une fonction `worker` simple (ex: qui ajoute 2 à son argument) plusieurs fois.
    *   **Implémentation LGBT+ :** Utilisation de `JAL` pour l'appel (sauvegarde de PC+4), `JALR` pour le retour. Gestion manuelle de la pile (`SP`, `STOREW`/`LOADW`) pour passer les arguments et sauvegarder/restaurer les registres si nécessaire selon votre convention d'appel.
    *   **Implémentation x86 :** Simple appel de fonction en C/Rust.

---

**Métriques à Mesurer (Pour chaque benchmark) :**

| Métrique                     | Description                                                                 | Mesure sur LGBT+ (Simulateur)                                                                  | Mesure sur x86 (Outils Standard)                                                                                                                               | Ce que ça Compare (potentiellement)                                                                                             |
| :--------------------------- | :-------------------------------------------------------------------------- | :--------------------------------------------------------------------------------------------- | :------------------------------------------------------------------------------------------------------------------------------------------------------------- | :------------------------------------------------------------------------------------------------------------------------------ |
| **1. Nombre d'Instructions (Dynamique)** | Total des instructions exécutées pour compléter la tâche.                 | Compteur global incrémenté dans la boucle `Cpu::step()`.                                       | `perf stat -e instructions:u ./program` <br/> (Linux) ou via GDB, Valgrind `lackey`, Intel VTune, AMD uProf.                                                      | Expressivité de l'ISA, efficacité de la boucle de contrôle, impact des opérations complexes (ex: MUL simulé vs natif).          |
| **2. Taille du Code (Statique)**   | Taille de la section de code exécutable générée.                            | Nombre total de Trytes/Trits du programme machine chargé dans le simulateur.                  | `size ./program` (section `.text`) <br/> `objdump -h ./program` (taille de la section `.text`). Mesurer en octets/bits.                                    | Densité du code, efficacité de l'encodage des instructions (12 trits vs longueur variable x86).                               |
| **3. Nombre de Lectures Mémoire (Dynamique)** | Total des opérations de chargement depuis la mémoire (Load).              | Compteurs spécifiques incrémentés pour `LOADW`, `LOADT`, `LOADTU` dans `Cpu::execute()`.     | `perf stat -e L1-dcache-loads:u ./program` <br/> Valgrind `cachegrind` (compteur `Dr`). Peut nécessiter de filtrer les accès instruction vs données si possible. | Efficacité de l'architecture Load/Store, utilisation des registres (moins de lectures = meilleure utilisation des registres). |
| **4. Nombre d'Écritures Mémoire (Dynamique)**| Total des opérations de stockage vers la mémoire (Store).                 | Compteurs spécifiques incrémentés pour `STOREW`, `STORET` dans `Cpu::execute()`.               | `perf stat -e L1-dcache-stores:u ./program` <br/> Valgrind `cachegrind` (compteur `Dw`).                                                                      | Utilisation des registres vs nécessité de sauvegarder des valeurs intermédiaires en mémoire.                               |
| **5. Nombre de Branches (Dynamique)** | Total des instructions de branchement conditionnel exécutées.             | Compteur spécifique pour l'instruction `BRANCH` dans `Cpu::execute()`.                         | `perf stat -e branch-instructions:u ./program`.                                                                                                                | Complexité du contrôle de flux, structure des boucles/conditions.                                                              |
| **6. Nombre de Branches Prises (Dynamique)** | Total des branches conditionnelles où la condition était vraie.           | Instrumenter la logique de `BRANCH` pour compter quand le saut est effectué.                    | `perf stat -e branch-instructions:u -e branch-misses:u ./program` (Calculer `Taken = Total - Misses`). *Note: `misses` concerne la prédiction, pas juste `taken`.* | Dynamique du contrôle de flux, efficacité des conditions.                                                                       |
| **7. (Dérivé) Instructions / Accès Mémoire** | Ratio `Instructions / (Lectures + Écritures)`.                          | Calcul à partir des métriques 1, 3, 4.                                                         | Calcul à partir des métriques 1, 3, 4.                                                                                                                         | Indicateur brut de l'intensité calculatoire vs l'intensité mémoire. Plus élevé peut signifier plus de travail en registres. |
| **8. (Dérivé) Instructions / Branche**   | Ratio `Instructions / Branches`.                                          | Calcul à partir des métriques 1, 5.                                                         | Calcul à partir des métriques 1, 5.                                                                                                                         | Taille moyenne des "blocs de base" entre les branchements.                                                                    |

---

**Comment Procéder :**

1.  **Implémenter les Kernels :** Écrivez chaque benchmark en assembleur LGBT+ et en C/Rust. Assurez-vous qu'ils font *exactement* la même chose logique et travaillent sur des données d'entrée **identiques** (même taille de tableau, mêmes valeurs initiales, même `n` pour factorielle, etc.).
2.  **Instrumenter le Simulateur :** Ajoutez les compteurs nécessaires dans votre code Rust `lgbt_sim` pour collecter les métriques dynamiques (Instructions, Lectures, Écritures, Branches). Prévoyez un moyen de réinitialiser et d'afficher ces compteurs.
3.  **Exécuter et Mesurer (LGBT+) :** Chargez et exécutez chaque programme assembleur LGBT+ sur le simulateur. Notez les valeurs des compteurs à la fin. Mesurez la taille du fichier de code machine généré par `lgbt_asm`.
4.  **Compiler et Mesurer (x86) :** Compilez les versions C/Rust pour x86 (ex: `gcc -O2 benchmark.c -o benchmark_x86` ou `rustc -C opt-level=2 benchmark.rs -o benchmark_x86`). Utilisez les outils `perf`, `size`, `valgrind` pour mesurer les métriques correspondantes sur l'exécutable x86. *Soyez cohérent avec les options de compilation (notamment le niveau d'optimisation O0, O1, O2, O3) car cela influence énormément les résultats x86.*
5.  **Analyser et Comparer :** Mettez les résultats en tableau et analysez les différences pour chaque benchmark et chaque métrique. Tirez des conclusions *prudentes* sur les caractéristiques architecturales révélées (ex: "Pour la copie mémoire, LGBT+ a nécessité X% d'instructions en plus mais Y% d'accès mémoire en moins par rapport à x86 -O2, suggérant une différence dans la gestion des loads/stores ou des registres").

N'oubliez pas les limitations : vous comparez un design spécifique (LGBT+) à un autre (x86) influencé par des décennies d'optimisation matérielle et logicielle (compilateurs). Les résultats seront spécifiques à vos implémentations et aux outils utilisés.