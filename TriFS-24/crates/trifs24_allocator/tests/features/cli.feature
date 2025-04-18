Feature: CLI TriFS-24
  Scenario: Montage via CLI
    Given un répertoire vide
    When j'exécute `trifs24_cli mount ./data /mnt`
    Then le FS monte sans erreur

  Scenario: Allouer un bloc
    Given un FS monté
    When j'exécute `trifs24_cli alloc --total 3`
    Then il renvoie l'index du bloc
