# Exemple d'utilisation du registre sstatus_t et du champ SPP_t

# Configuration initiale en mode Machine (M-mode)
start:  
        # Configuration des vecteurs de trap
        LUI     R1, 0x1        # Partie haute de l'adresse du gestionnaire M-mode (0x1000)
        CSRRW_T R0, MTVEC_T, R1 # Configure mtvec_t avec l'adresse du gestionnaire M-mode

        LUI     R1, 0x2        # Partie haute de l'adresse du gestionnaire S-mode (0x2000)
        CSRRW_T R0, STVEC_T, R1 # Configure stvec_t avec l'adresse du gestionnaire S-mode

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
        # Configurer sstatus_t pour le retour en mode User
        LUI     R1, 0
        ADDI    R1, R1, 1      # SPP_t = 0 (User mode)
        CSRRW_T R0, SSTATUS_T, R1

        # Sauvegarder l'adresse de retour dans sepc_t
        LUI     R1, 0
        ADDI    R1, R1, user_code
        CSRRW_T R0, SEPC_T, R1  # Configure sepc_t avec l'adresse du code utilisateur

        # Retour au mode User
        SRET_T                  # Retourne au mode User et saute à l'adresse dans sepc_t

# Code exécuté en mode User (U-mode)
user_code:
        # Appel système depuis le mode User
        ECALL                   # Déclenche un appel système (EcallU)

        # Cette instruction ne sera exécutée qu'après le retour du gestionnaire
        HALT                    # Fin du programme

# Gestionnaire de trap en mode Supervisor (S-mode)
# Cette adresse doit être alignée sur 0x2000
        .org 0x2000
supervisor_handler:
        # Lire la cause du trap
        CSRRS_T R1, SCAUSE_T, R0 # Lit la cause du trap dans R1
        CSRRS_T R2, SEPC_T, R0   # Lit l'adresse de retour dans R2

        # Vérifier que sstatus_t.SPP_t contient bien le niveau de privilège précédent (User)
        CSRRS_T R3, SSTATUS_T, R0 # Lit sstatus_t dans R3
        # Dans un cas réel, on vérifierait que le bit SPP_t est à 0 (User)

        # Incrémenter l'adresse de retour pour passer l'instruction ECALL
        ADDI    R2, R2, 4        # Incrémente l'adresse de retour
        CSRRW_T R0, SEPC_T, R2   # Écrit la nouvelle adresse de retour

        # Retour au mode User
        SRET_T                   # Retourne au mode User et saute à l'adresse dans sepc_t

# Gestionnaire de trap en mode Machine (M-mode)
# Cette adresse doit être alignée sur 0x1000
        .org 0x1000
machine_handler:
        # Lire la cause du trap
        CSRRS_T R1, MCAUSE_T, R0 # Lit la cause du trap dans R1
        CSRRS_T R2, MEPC_T, R0   # Lit l'adresse de retour dans R2

        # Traitement générique pour tous les traps non délégués
        # Incrémenter l'adresse de retour
        ADDI    R2, R2, 4        # Incrémente l'adresse de retour
        CSRRW_T R0, MEPC_T, R2   # Écrit la nouvelle adresse de retour

        # Retour au mode précédent
        MRET_T                   # Retourne au mode précédent et saute à l'adresse dans mepc_t