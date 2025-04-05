# Exemple : Boucle avec JAL
# Ce programme implémente une boucle infinie en utilisant JAL

.org 0x100  # Commencer à l'adresse 0x100

start:
    LUI R1, 1      # Initialiser R1 à 1
    JAL R0, loop   # Sauter à 'loop' (R0 est ignoré)

loop:
    ADDI R1, R1, 1  # Incrémenter R1
    NOP             # Ne rien faire
    JAL R0, start   # Retourner au début
    HALT            # Cette instruction ne sera jamais exécutée