# Benchmark: Factorial
# Calcule la factorielle d'un nombre de manière itérative

# Définition des constantes
.equ N, 10               # Nombre dont on calcule la factorielle
.equ RESULT_ADDR, 0x1000 # Adresse où stocker le résultat

# Section de code
.section .text
.global _start

_start:
    # Initialisation des registres
    MOVI r1, N            # Nombre dont on calcule la factorielle
    MOVI r2, 1            # Accumulateur (résultat)
    MOVI r3, 1            # Compteur (i)

loop:
    # Vérifier si on a terminé
    CMP r3, r1            # Comparer i et N
    BRANCH GT, end_loop   # Si i > N, sortir de la boucle
    
    # Multiplier l'accumulateur par i
    # Note: PrismChrono n'a pas d'instruction MUL native,
    # donc on simule la multiplication par des additions répétées
    MOVI r4, 0            # Résultat temporaire
    MOVI r5, 0            # Compteur pour l'addition répétée

mul_loop:
    CMP r5, r3            # Comparer compteur et i
    BRANCH GE, mul_end    # Si compteur >= i, sortir de la boucle
    
    ADD r4, r4, r2        # Ajouter l'accumulateur au résultat temporaire
    ADDI r5, r5, 1        # Incrémenter le compteur
    
    BRANCH ALWAYS, mul_loop

mul_end:
    MOV r2, r4            # Mettre à jour l'accumulateur avec le résultat de la multiplication
    
    # Incrémenter i
    ADDI r3, r3, 1        # i++
    
    # Retour au début de la boucle
    BRANCH ALWAYS, loop

end_loop:
    # Stocker le résultat
    MOVI r6, RESULT_ADDR
    STOREW r2, r6, 0      # Stocker la factorielle à l'adresse résultat
    
    # Fin du programme
    HALT