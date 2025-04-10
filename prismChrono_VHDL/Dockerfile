FROM hdlc/ghdl:latest

# Installation des dépendances nécessaires
RUN apt-get update && apt-get install -y \
    gtkwave \
    make \
    git \
    vim \
    procps \
    htop \
    python3 \
    python3-pip \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Configuration de GHDL pour optimiser l'utilisation de la mémoire
ENV GHDL_OPTS="--ieee=synopsys --optimize=3 -Wno-hide --mb-comments"
ENV GHDL_MEMORY_LIMIT=16G

# Configuration pour réduire l'empreinte mémoire du conteneur
ENV MALLOC_ARENA_MAX=1
ENV MALLOC_TRIM_THRESHOLD_=65536
ENV MALLOC_MMAP_THRESHOLD_=65536

# Configuration supplémentaire pour améliorer la gestion de la mémoire
ENV GHDL_DISABLE_LARGE_DESIGN=0
ENV GHDL_GC_PERIOD=50
ENV GHDL_MEMORY_MANAGEMENT="compact"
ENV GHDL_INCREMENTAL_MODE=1

# Configuration pour macOS spécifiquement
ENV GHDL_MACOS_COMPAT=1
ENV GHDL_STACK_SIZE=32M

# Définir le répertoire de travail
WORKDIR /workspace

# Copier les scripts de simulation
COPY ./sim/scripts /workspace/sim/scripts
COPY ./rtl /workspace/rtl
COPY ./sim/testbenches /workspace/sim/testbenches

# Créer le répertoire pour les fichiers de travail et VCD
RUN mkdir -p /workspace/sim/work /workspace/sim/vcd

# Rendre les scripts exécutables
RUN chmod +x /workspace/sim/scripts/*.sh

# Commande par défaut
CMD ["/bin/bash"]