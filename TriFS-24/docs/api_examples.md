# Exemples d’API TriFS-24‑AI

## 1. Allocation ternaire

```rust
use trifs24_allocator::Allocator;

#[tokio::main]
async fn main() {
    // Initialise un allocateur ternaire avec 100 triclusters
    let mut allocator = Allocator::new(100);
    
    // Allouer un tricluster
    match allocator.allocate() {
        Ok(idx) => println!("Allocé : {}", idx),
        Err(e) => eprintln!("Erreur d’allocation : {}", e),
    }
}
```

## 2. Lecture du statut

```rust
use trifs24_allocator::{Allocator, Status};

fn main() {
    let allocator = Allocator::new(50);
    let status: Status = allocator.status();
    println!("Libre: {}, Occupé: {}, Réservé: {}", status.free, status.used, status.reserved);
}
```

## 3. Résolution d’erreur

```rust
use trifs24_allocator::{Allocator, Error};

fn main() {
    let mut alloc = Allocator::new(0);
    if let Err(e) = alloc.allocate() {
        assert_eq!(format!("{}", e), "OutOfSpace");
    }
}
```

## 4. Logs de debug (BDD)

```rust
// Dans tests/bdd.rs, TestLogger capture les messages
#[given("un module initialisé")]
async fn init_module(world: &mut TriFsWorld) {
    let _ = log::set_boxed_logger(Box::new(TestLogger));
    log::set_max_level(LevelFilter::Debug);
}

#[when("j'appelle `predictive_alloc()`")]
async fn call_predictive(world: &mut TriFsWorld) {
    world.predictive = Some(PredictiveAllocator::new());
    world.predictive.as_mut().unwrap().predictive_alloc();
}

#[then("on logge un message DEBUG contenant \"predictive_alloc\"")]
async fn check_log(world: &mut TriFsWorld) {
    let info = "predictive_alloc";
    assert!(LOGS.lock().unwrap().iter().any(|l| l.contains(&info)));
}
```
