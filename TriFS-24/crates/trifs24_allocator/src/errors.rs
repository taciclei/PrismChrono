/// Définition des erreurs pour `trifs24_allocator`.
#[derive(Debug, PartialEq)]
pub enum Error {
    /// Plus d'espace disponible.
    OutOfSpace,
    /// Index invalide pour libération.
    InvalidIndex,
}

impl std::fmt::Display for Error {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "{:?}", self)
    }
}

impl std::error::Error for Error {}

#[cfg(test)]
mod tests {
    use super::Error;

    #[test]
    fn test_error_display() {
        assert_eq!(format!("{}", Error::OutOfSpace), "OutOfSpace");
        assert_eq!(format!("{}", Error::InvalidIndex), "InvalidIndex");
    }
}
