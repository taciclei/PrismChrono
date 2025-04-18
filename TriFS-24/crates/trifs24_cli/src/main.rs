use clap::{Parser, Subcommand};
use trifs24_allocator::{Allocator, Vfs, Status};

/// CLI pour TriFS-24.
#[derive(Parser)]
#[command(name = "trifs24_cli")]
#[command(version = "0.1.0")]
#[command(about = "Interface en ligne de commande pour TriFS-24", long_about = None)]
struct Cli {
    #[command(subcommand)]
    command: Commands,
}

#[derive(Subcommand)]
enum Commands {
    /// Monte le système de fichiers TriFS-24.
    Mount {
        /// Dossier source des données.
        source: String,
        /// Point de montage.
        mount_point: String,
    },
    /// Alloue un tricluster libre.
    Alloc {
        /// Nombre total de triclusters (par défaut: 100).
        #[arg(short, long)]
        total: Option<usize>,
    },
    /// Libère un tricluster à l'index donné.
    Free {
        /// Index du tricluster à libérer.
        index: usize,
        /// Nombre total de triclusters (par défaut: 100).
        #[arg(short, long)]
        total: Option<usize>,
    },
    /// Affiche le statut du système de fichiers.
    Status {
        /// Nombre total de triclusters (par défaut: 100).
        #[arg(short, long)]
        total: Option<usize>,
    },
}

fn main() {
    let cli = Cli::parse();
    match cli.command {
        Commands::Mount { source, mount_point } => {
            let _vfs = Vfs::mount(&source, &mount_point);
            println!("Mounted FS at {}", mount_point);
        }
        Commands::Alloc { total } => {
            let mut alloc = Allocator::new(total.unwrap_or(100));
            match alloc.allocate() {
                Some(idx) => println!("{}", idx),
                None => eprintln!("No free blocks"),
            }
        }
        Commands::Free { index, total } => {
            let mut alloc = Allocator::new(total.unwrap_or(100));
            let ok = alloc.free(index);
            println!("{}", ok);
        }
        Commands::Status { total } => {
            let alloc = Allocator::new(total.unwrap_or(100));
            let st: Status = alloc.status();
            println!("free: {}, used: {}, reserved: {}", st.free, st.used, st.reserved);
        }
    }
}
