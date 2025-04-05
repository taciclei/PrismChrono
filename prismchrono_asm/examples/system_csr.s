# Exemple d'utilisation des instructions système et CSR

# Configuration du vecteur de trap
start:  CSRRW_T R0, MTVEC_T, R1    # Configure le vecteur de trap avec la valeur de R1

# Appel système
        ECALL                      # Déclenche un appel système

# Gestion des traps
handler:
        CSRRS_T R1, MCAUSE_T, R0   # Lit la cause du trap dans R1
        CSRRS_T R2, MEPC_T, R0     # Lit l'adresse de retour dans R2
        ADDI    R2, R2, 4          # Incrémente l'adresse de retour (passe l'instruction ECALL)
        CSRRW_T R0, MEPC_T, R2     # Écrit la nouvelle adresse de retour

# Retour de trap
        MRET_T                     # Retourne au mode précédent et à l'adresse MEPC

# Fin du programme
        HALT