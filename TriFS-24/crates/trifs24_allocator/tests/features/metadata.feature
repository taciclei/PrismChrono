Feature: Gestion des métadonnées
  Scenario: Ajouter et récupérer un attribut
    Given un FNode initialisé vide
    When j'appelle set_attr("clef", "valeur")
    Then get_attr("clef") renvoie Some("valeur")
