/// Calcule un checksum ternaire simple (somme mod 3) sur un bloc de trits.
pub fn compute_checksum(block: &[u8]) -> u8 {
    block.iter().copied().sum::<u8>() % 3
}

/// Vérifie qu'un checksum correspond au bloc donné.
pub fn verify_checksum(block: &[u8], checksum: u8) -> bool {
    compute_checksum(block) == checksum
}

#[cfg(test)]
mod tests {
    use super::{compute_checksum, verify_checksum};

    #[test]
    fn test_checksum_functions() {
        let block = &[0, 1, 2];
        let cs = compute_checksum(block);
        assert!(cs < 3);
        assert!(verify_checksum(block, cs));
        assert!(!verify_checksum(block, (cs + 1) % 3));
    }
}
