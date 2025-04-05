# Benchmark: Memcpy
# Copie un bloc de mémoire d'une zone source vers une zone destination

# Définition des constantes
.equ BLOCK_SIZE, 100     # Taille du bloc à copier (en Words)
.equ SRC_ADDR, 0x1000    # Adresse source
.equ DEST_ADDR, 0x1400   # Adresse destination

# Section de données
.section .data
# Les données source seront initialisées par le simulateur ou le script d'exécution

# Section de code
.section .text
.global _start

_start:
    # Initialisation des registres
    MOVI r1, SRC_ADDR     # Adresse source
    MOVI r2, DEST_ADDR    # Adresse destination
    MOVI r3, BLOCK_SIZE   # Taille du bloc
    MOVI r4, 0            # Index courant

loop:
    # Vérifier si on a copié tout le bloc
    CMP r4, r3            # Comparer index et taille
    BRANCH GE, end_loop   # Si index >= taille, sortir de la boucle
    
    # Calculer les adresses source et destination pour l'élément courant
    ADD r5, r1, r4        # r5 = adresse source + index
    ADD r6, r2, r4        # r6 = adresse destination + index
    
    # Charger l'élément depuis la source
    LOADW r7, r5, 0       # r7 = source[index]
    
    # Stocker l'élément dans la destination
    STOREW r7, r6, 0      # destination[index] = r7
    
    # Incrémenter l'index
    ADDI r4, r4, 1        # index++
    
    # Retour au début de la boucle
    BRANCH ALWAYS, loop

end_loop:
    # Fin du programme
    HALT