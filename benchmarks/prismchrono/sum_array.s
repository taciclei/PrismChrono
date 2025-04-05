# Benchmark: Sum Array
# Calcule la somme des éléments d'un tableau d'entiers (Word)

# Définition des constantes
.equ ARRAY_SIZE, 100     # Taille du tableau
.equ ARRAY_ADDR, 0x1000  # Adresse de début du tableau
.equ RESULT_ADDR, 0x1400 # Adresse où stocker le résultat

# Section de données
.section .data
# Le tableau sera initialisé par le simulateur ou le script d'exécution

# Section de code
.section .text
.global _start

_start:
    # Initialisation des registres
    MOVI r1, ARRAY_ADDR   # Adresse du tableau
    MOVI r2, ARRAY_SIZE   # Taille du tableau
    MOVI r3, 0            # Accumulateur (somme)
    MOVI r4, 0            # Index courant

loop:
    # Vérifier si on a parcouru tout le tableau
    CMP r4, r2            # Comparer index et taille
    BRANCH GE, end_loop   # Si index >= taille, sortir de la boucle
    
    # Calculer l'adresse de l'élément courant
    ADD r5, r1, r4        # r5 = adresse de base + index
    
    # Charger l'élément courant
    LOADW r6, r5, 0       # r6 = tableau[index]
    
    # Ajouter à la somme
    ADD r3, r3, r6        # somme += tableau[index]
    
    # Incrémenter l'index
    ADDI r4, r4, 1        # index++
    
    # Retour au début de la boucle
    BRANCH ALWAYS, loop

end_loop:
    # Stocker le résultat
    MOVI r7, RESULT_ADDR
    STOREW r3, r7, 0      # Stocker la somme à l'adresse résultat
    
    # Fin du programme
    HALT