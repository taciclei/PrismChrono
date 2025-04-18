Feature: Indexation vectorielle
  Scenario: Ajouter et récupérer un vecteur
    Given un VectorIndex initialisé vide
    When j'appelle insert(1, [0.1, 0.2])
    Then query(1) renvoie Some([0.1, 0.2])
