# Benchmark: Optimized Memory Access
# Démonstration des accès mémoire optimisés avec LOADT3/STORET3 et LOADTM/STORETM
# Ce benchmark compare les performances des instructions mémoire standard vs optimisées

# Définition des constantes
.equ ARRAY_SIZE, 100      # Taille du tableau
.equ SRC_ADDR, 0x1000     # Adresse source
.equ DST_ADDR, 0x1400     # Adresse destination
.equ MASK_ADDR, 0x1800    # Adresse des masques

# Section de données
.section .data
# Les données seront initialisées par le simulateur ou le script d'exécution

# Section de code
.section .text
.global _start

_start:
    # Initialisation des registres
    MOVI r1, SRC_ADDR      # Adresse source
    MOVI r2, DST_ADDR      # Adresse destination
    MOVI r3, ARRAY_SIZE    # Taille du tableau
    MOVI r4, MASK_ADDR     # Adresse des masques

# Partie 1: Copie standard (tryte par tryte)
standard_copy:
    MOVI r5, 0             # Index courant

standard_loop:
    # Vérifier si on a copié tout le tableau
    CMP r5, r3
    BRANCH GE, optimized_copy # Si index >= taille, passer à la partie suivante
    
    # Calculer les adresses courantes
    ADD r6, r1, r5        # r6 = adresse_source + index
    ADD r7, r2, r5        # r7 = adresse_destination + index
    
    # Copier un tryte à la fois
    LOADT r8, r6, 0       # r8 = source[index]
    STORET r8, r7, 0      # destination[index] = r8
    
    # Incrémenter l'index
    ADDI r5, r5, 1
    BRANCH AL, standard_loop # Continuer la boucle

# Partie 2: Copie optimisée avec LOADT3/STORET3
optimized_copy:
    MOVI r5, 0             # Index courant

optimized_loop:
    # Vérifier si on a copié tout le tableau
    CMP r5, r3
    BRANCH GE, masked_copy # Si index >= taille, passer à la partie suivante
    
    # Calculer les adresses courantes
    ADD r6, r1, r5        # r6 = adresse_source + index
    ADD r7, r2, r5        # r7 = adresse_destination + index
    
    # Copier 3 trytes à la fois avec LOADT3/STORET3
    LOADT3 r8, r6, 0      # r8 = source[index..index+2]
    STORET3 r8, r7, 0     # destination[index..index+2] = r8
    
    # Incrémenter l'index de 3
    ADDI r5, r5, 3
    BRANCH AL, optimized_loop # Continuer la boucle

# Partie 3: Copie avec masque utilisant LOADTM/STORETM
masked_copy:
    MOVI r5, 0             # Index courant

masked_loop:
    # Vérifier si on a copié tout le tableau
    CMP r5, r3
    BRANCH GE, tmemcpy_test # Si index >= taille, passer à la partie suivante
    
    # Calculer les adresses courantes
    ADD r6, r1, r5        # r6 = adresse_source + index
    ADD r7, r2, r5        # r7 = adresse_destination + index
    ADD r8, r4, r5        # r8 = adresse_masque + index
    
    # Charger le masque
    LOADW r9, r8, 0       # r9 = masque[index]
    
    # Copier avec masque utilisant LOADTM/STORETM
    LOADTM r10, r9, r6, 0  # r10 = source[index] avec masque r9
    STORETM r10, r9, r7, 0 # destination[index] = r10 avec masque r9
    
    # Incrémenter l'index
    ADDI r5, r5, 1
    BRANCH AL, masked_loop # Continuer la boucle

# Partie 4: Test de TMEMCPY (copie mémoire ternaire optimisée)
tmemcpy_test:
    # Utiliser TMEMCPY pour copier un bloc de mémoire
    MOVI r5, 50           # Nombre de trytes à copier
    TMEMCPY r2, r1, r5    # Copier r5 trytes de r1 vers r2
    
    # Fin du programme
    HALT