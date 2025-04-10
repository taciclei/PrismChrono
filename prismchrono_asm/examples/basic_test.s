# Test des instructions de base de PrismChrono

# Test des instructions arithmétiques
start:
    ADDI R1, R0, 5      # R1 = 5
    ADDI R2, R0, 3      # R2 = 3
    ADD R3, R1, R2      # R3 = R1 + R2 = 8
    SUB R4, R3, R2      # R4 = R3 - R2 = 5

# Test des instructions de chargement/stockage
    LUI R5, 0x100       # Charge une adresse de base
    STOREW R5, R1, 0    # Stocke R1 à l'adresse dans R5
    STOREW R5, R2, 4    # Stocke R2 à l'adresse R5 + 4

# Test des instructions de branchement
    BRANCH R1, R2, GT, greater   # Branche si R1 > R2 (GT = Greater Than)
    BRANCH R1, R2, EQ, equal     # Branche si R1 = R2 (EQ = Equal)
    JAL R0, end                  # Sinon, saute à la fin

greater:
    ADDI R6, R0, 1      # R6 = 1 (R1 était plus grand)
    JAL R0, end         # Saute à la fin

equal:
    ADDI R6, R0, 0      # R6 = 0 (R1 était égal à R2)

end:
    HALT                # Fin du programme