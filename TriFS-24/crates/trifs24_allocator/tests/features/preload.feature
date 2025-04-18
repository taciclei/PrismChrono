Feature: Pipeline de préchargement
  Scenario: Préchargement de blocs à venir
    Given un PreloadPipeline initialisé
    When j'appelle preload([0,1,2])
    Then la méthode renvoie [0,1,2]
