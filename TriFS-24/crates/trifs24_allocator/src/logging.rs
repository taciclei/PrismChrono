use log::{debug, LevelFilter};
use env_logger;
use std::sync::Once;

static INIT: Once = Once::new();

/// Initialise le logger global (niveau Debug).
pub fn init_logging() {
    INIT.call_once(|| {
        let _ = env_logger::Builder::from_default_env()
            .filter_level(LevelFilter::Debug)
            .try_init();
    });
}

/// Log une opération prédictive au niveau DEBUG.
pub fn log_predictive(msg: &str) {
    debug!("{}", msg);
}
