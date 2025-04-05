# Exemple : Utilisation de ADDI et LUI
# Ce programme charge des valeurs dans les registres et effectue des additions

.org 0x100  # Commencer à l'adresse 0x100

start:
    LUI R1, 42     # Charger la valeur 42 dans le registre R1
    ADDI R2, R1, 10  # R2 = R1 + 10 = 52
    NOP             # Ne rien faire
    HALT            # Arrêter le processeur