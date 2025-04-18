use async_trait::async_trait;
use std::convert::Infallible;
use cucumber::{given, when, then, WorldInit};
use trifs24_allocator::{Allocator, PredictiveAllocator, Error, get_alloc_total, reset_alloc_counter};
use log::{Record, Level, Metadata, LevelFilter};
use lazy_static::lazy_static;
use std::sync::Mutex;

#[derive(WorldInit)]
pub struct TriFsWorld {
    allocator: Option<Allocator>,
    predictive: Option<PredictiveAllocator>,
    error: Option<Error>,
}

// `Debug` required by derive(WorldInit)
impl std::fmt::Debug for TriFsWorld {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "TriFsWorld")
    }
}

#[async_trait(?Send)]
impl cucumber::World for TriFsWorld {
    type Error = Infallible;
    async fn new() -> Result<Self, Self::Error> {
        Ok(TriFsWorld { allocator: None, predictive: None, error: None })
    }
}

lazy_static! {
    static ref LOGS: Mutex<Vec<String>> = Mutex::new(Vec::new());
}

struct TestLogger;
impl log::Log for TestLogger {
    fn enabled(&self, metadata: &Metadata) -> bool {
        metadata.level() <= Level::Debug
    }
    fn log(&self, record: &Record) {
        if self.enabled(record.metadata()) {
            LOGS.lock().unwrap().push(format!("{}", record.args()));
        }
    }
    fn flush(&self) {}
}

#[given(regex = r"^un Allocator initialisé avec (\d+) tricluster$")]
async fn allocator_initialized(world: &mut TriFsWorld, total: usize) {
    world.allocator = Some(Allocator::new(total));
    world.error = None;
}

#[when(regex = r"^j'appelle allocate\(\)$")]
async fn call_allocate(world: &mut TriFsWorld) {
    if let Err(e) = world.allocator.as_mut().unwrap().allocate() {
        world.error = Some(e);
    }
}

#[then(regex = r#"^la méthode retourne une erreur "(.+)"$"#)]
async fn method_returns_error(world: &mut TriFsWorld, expected: String) {
    let e = world.error.as_ref().unwrap();
    assert_eq!(format!("{}", e), expected);
}

#[given("un module initialisé")]
async fn module_initialized(_world: &mut TriFsWorld) {
    let _ = log::set_boxed_logger(Box::new(TestLogger));
    log::set_max_level(LevelFilter::Debug);
}

#[when("j'appelle `predictive_alloc()`")]
async fn call_predictive(_world: &mut TriFsWorld) {
    let mut pa = PredictiveAllocator::new();
    pa.predictive_alloc();
}

#[then(regex = r#"^on logge un message DEBUG contenant "(.+)"$"#)]
async fn logs_contains(_world: &mut TriFsWorld, info: String) {
    assert!(LOGS.lock().unwrap().iter().any(|l| l.contains(&info)));
}

#[given("un compteur remis à zéro")]
async fn reset_counter(_world: &mut TriFsWorld) {
    reset_alloc_counter();
}

#[when("j'appelle `allocate()` trois fois")]
async fn allocate_three(_world: &mut TriFsWorld) {
    let mut alloc = Allocator::new(100);
    for _ in 0..3 {
        alloc.allocate().unwrap();
    }
}

#[then(regex = r#"^la métrique `allocator_alloc_total` vaut (\d+)$"#)]
async fn counter_value(_world: &mut TriFsWorld, expected: u64) {
    assert_eq!(get_alloc_total(), expected);
}

#[tokio::main]
async fn main() {
    TriFsWorld::run("./tests/features").await;
}
