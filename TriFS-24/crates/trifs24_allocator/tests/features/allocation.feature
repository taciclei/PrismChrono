Feature: Gestion complète des triclusters
  Scenario: Libération d'un tricluster occupé
    Given un allocateur initialisé avec 1 tricluster alloué et 1 réservé
    When j'appelle free(0)
    Then l'état du tricluster 0 passe à "libre"

  Scenario: Lecture du statut global
    Given un allocateur initialisé avec [libre, occupé, réservé]
    When j'appelle status()
    Then la structure renvoie {free:1, used:1, reserved:1}
