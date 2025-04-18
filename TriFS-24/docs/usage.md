# Guide d'utilisation - TriFS-24 CLI

## Installation

```sh
cargo install --path crates/trifs24_cli
```

## Commandes

- `trifs24_cli mount <source> <mount_point>`  
  Monte le FS TriFS-24.

- `trifs24_cli alloc [--total N]`  
  Alloue un tricluster (par défaut total=100).

- `trifs24_cli free <index> [--total N]`  
  Libère le tricluster à l'index donné.

- `trifs24_cli status [--total N]`  
  Affiche le nombre de blocs libres, utilisés et réservés.
