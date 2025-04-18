use std::collections::HashMap;

/// Noeud de métadonnées d'un fichier.
pub struct FNode {
    attrs: HashMap<String, String>,
}

impl FNode {
    /// Crée un nouveau FNode vide.
    pub fn new() -> Self {
        FNode { attrs: HashMap::new() }
    }

    /// Définit un attribut, retourne l'ancienne valeur si existante.
    pub fn set_attr(&mut self, key: &str, value: &str) -> Option<String> {
        self.attrs.insert(key.to_string(), value.to_string())
    }

    /// Récupère la valeur d'un attribut.
    pub fn get_attr(&self, key: &str) -> Option<String> {
        self.attrs.get(key).cloned()
    }
}

#[cfg(test)]
mod tests {
    use super::FNode;

    #[test]
    fn test_set_and_get_attr() {
        let mut node = FNode::new();
        assert_eq!(node.get_attr("clef"), None);
        node.set_attr("clef", "valeur");
        assert_eq!(node.get_attr("clef"), Some("valeur".to_string()));
    }
}
