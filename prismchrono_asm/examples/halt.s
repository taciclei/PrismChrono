# Exemple simple : Programme HALT
# Ce programme ne fait rien et s'arrête immédiatement

.org 0x100  # Commencer à l'adresse 0x100

start:
    HALT     # Arrêter le processeur