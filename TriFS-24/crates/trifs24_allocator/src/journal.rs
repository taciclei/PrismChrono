use std::collections::VecDeque;

/// Journalisation ternaire des opérations.
pub struct Journal {
    events: VecDeque<String>,
}

impl Journal {
    /// Crée un nouveau Journal vide.
    pub fn new() -> Self {
        Journal { events: VecDeque::new() }
    }

    /// Enregistre un événement.
    pub fn record(&mut self, event: &str) {
        self.events.push_back(event.to_string());
    }

    /// Renvoie le dernier événement si présent.
    pub fn last_event(&self) -> Option<&String> {
        self.events.back()
    }
}

#[cfg(test)]
mod tests {
    use super::Journal;

    #[test]
    fn test_journal() {
        let mut j = Journal::new();
        assert_eq!(j.last_event(), None);
        j.record("t1");
        assert_eq!(j.last_event(), Some(&"t1".to_string()));
    }
}
