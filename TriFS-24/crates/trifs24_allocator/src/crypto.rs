/// Stub de chiffrement / déchiffrement de bloc par bloc.
pub fn encrypt_block(_key: &str, block: &[u8]) -> Vec<u8> {
    // Stub: retourne simplement une copie du bloc
    block.to_vec()
}

pub fn decrypt_block(_key: &str, data: &[u8]) -> Vec<u8> {
    // Stub: retourne une copie des données
    data.to_vec()
}

#[cfg(test)]
mod tests {
    use super::{encrypt_block, decrypt_block};

    #[test]
    fn test_encrypt_decrypt() {
        let key = "clef";
        let block = &[0,1,2];
        let enc = encrypt_block(key, block);
        assert_eq!(enc, block);
        let dec = decrypt_block(key, &enc);
        assert_eq!(dec, block);
    }
}
