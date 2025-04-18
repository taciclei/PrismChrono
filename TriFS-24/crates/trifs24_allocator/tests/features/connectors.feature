Feature: Connecteurs IA
  Scenario: Prédiction TensorFlow et PyTorch
    Given un Connectors initialisé
    When j'appelle tf_predict([1.0,2.0]) et pt_predict([1.0,2.0])
    Then tf_predict renvoie [2.0,4.0] et pt_predict renvoie [3.0,6.0]
