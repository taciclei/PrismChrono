Feature: VFS TriFS-24
  Scenario: Montage et opérations
    Given un Vfs monté sur un répertoire
    When j'écris "hello" dans /greeting.txt
    Then la lecture de /greeting.txt renvoie "hello"
