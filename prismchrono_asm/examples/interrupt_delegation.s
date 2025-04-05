# Exemple d'utilisation du système de privilèges v0.2 avec délégation des interruptions

# Configuration initiale en mode Machine (M-mode)
start:  
        # Configuration des vecteurs de trap
        LUI     R1, 0x1        # Partie haute de l'adresse du gestionnaire M-mode (0x1000)
        CSRRW_T R0, MTVEC_T, R1 # Configure mtvec_t avec l'adresse du gestionnaire M-mode

        LUI     R1, 0x2        # Partie haute de l'adresse du gestionnaire S-mode (0x2000)
        CSRRW_T R0, STVEC_T, R1 # Configure stvec_t avec l'adresse du gestionnaire S-mode

        # Configuration de la délégation des interruptions
        # Activer la délégation pour les interruptions timer (code 1) dans mideleg_t
        LUI     R1, 0          # Initialiser R1 à 0
        ADDI    R1, R1, 2      # R1 = 2 (pour activer le deuxième trit)
        CSRRW_T R0, MIDELEG_T, R1 # Configure mideleg_t pour déléguer les interruptions timer au mode S

        # Activer les interruptions globalement
        LUI     R1, 0
        ADDI    R1, R1, 3      # MIE_t = 1, MPIE_t = 1
        CSRRW_T R0, MSTATUS_T, R1

        # Passage en mode Supervisor (S-mode)
        # Sauvegarder l'adresse de retour dans mepc_t
        LUI     R1, 0
        ADDI    R1, R1, supervisor_code
        CSRRW_T R0, MEPC_T, R1  # Configure mepc_t avec l'adresse du code supervisor

        # Configurer le niveau de privilège précédent dans mstatus_t.MPP_t
        LUI     R1, 0
        ADDI    R1, R1, 2      # MPP = 01 (Supervisor mode)
        CSRRW_T R0, MSTATUS_T, R1

        # Retour au mode Supervisor
        MRET_T                  # Retourne au mode Supervisor et saute à l'adresse dans mepc_t

# Code exécuté en mode Supervisor (S-mode)
supervisor_code:
        # Activer les interruptions en mode Supervisor
        LUI     R1, 0
        ADDI    R1, R1, 3      # SIE_t = 1, SPIE_t = 1
        CSRRW_T R0, SSTATUS_T, R1

        # Passage en mode User (U-mode)
        # Sauvegarder l'adresse de retour dans sepc_t
        LUI     R1, 0
        ADDI    R1, R1, user_code
        CSRRW_T R0, SEPC_T, R1  # Configure sepc_t avec l'adresse du code utilisateur

        # Configurer le niveau de privilège précédent dans sstatus_t.SPP_t
        # SPP = 0 (User mode) - déjà configuré

        # Retour au mode User
        SRET_T                  # Retourne au mode User et saute à l'adresse dans sepc_t

# Code exécuté en mode User (U-mode)
user_code:
        # Boucle d'attente - dans un système réel, une interruption timer pourrait survenir ici
        LUI     R1, 0
        ADDI    R1, R1, 100    # Compteur de boucle

loop:   
        ADDI    R1, R1, -1     # Décrémenter le compteur
        BNE     R1, R0, loop   # Boucler si le compteur n'est pas à zéro

        # Cette instruction sera exécutée après la boucle ou après le retour du gestionnaire d'interruption
        HALT                    # Fin du programme

# Gestionnaire de trap en mode Supervisor (S-mode)
# Cette adresse doit être alignée sur 0x2000
        .org 0x2000
supervisor_handler:
        # Sauvegarder les registres importants
        ADDI    R7, R0, -4     # Décrémenter le pointeur de pile
        SW      R1, 0(R7)      # Sauvegarder R1

        # Lire la cause du trap
        CSRRS_T R1, SCAUSE_T, R0 # Lit la cause du trap dans R1

        # Traitement spécifique pour les interruptions timer
        # Dans un cas réel, on vérifierait la valeur de R1

        # Restaurer les registres
        LW      R1, 0(R7)      # Restaurer R1
        ADDI    R7, R0, 4      # Incrémenter le pointeur de pile

        # Retour au mode précédent
        SRET_T                  # Retourne au mode précédent et saute à l'adresse dans sepc_t

# Gestionnaire de trap en mode Machine (M-mode)
# Cette adresse doit être alignée sur 0x1000
        .org 0x1000
machine_handler:
        # Sauvegarder les registres importants
        ADDI    R7, R0, -4     # Décrémenter le pointeur de pile
        SW      R1, 0(R7)      # Sauvegarder R1

        # Lire la cause du trap
        CSRRS_T R1, MCAUSE_T, R0 # Lit la cause du trap dans R1

        # Traitement générique pour tous les traps non délégués
        # Dans un cas réel, on vérifierait la valeur de R1

        # Restaurer les registres
        LW      R1, 0(R7)      # Restaurer R1
        ADDI    R7, R0, 4      # Incrémenter le pointeur de pile

        # Retour au mode précédent
        MRET_T                  # Retourne au mode précédent et saute à l'adresse dans mepc_t