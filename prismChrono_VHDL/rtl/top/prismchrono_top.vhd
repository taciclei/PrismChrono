library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Import du package de types personnalisé
library work;
use work.prismchrono_types_pkg.all;

-- Module top-level pour PrismChrono
entity prismchrono_top is
    port (
        clk             : in  std_logic;                     -- Horloge système
        rst_n           : in  std_logic;                     -- Reset asynchrone (actif bas)
        uart_tx_pin     : out std_logic;                     -- Pin TX UART (sortie série)
        uart_rx_pin     : in  std_logic;                     -- Pin RX UART (entrée série)
        debug_led       : out std_logic_vector(7 downto 0);  -- LEDs de debug
        
        -- Interface DDR (ajoutée pour le sprint 8)
        ddr_cmd_valid   : out std_logic;                     -- Commande valide
        ddr_cmd_ready   : in  std_logic;                     -- Contrôleur prêt à recevoir une commande
        ddr_cmd_we      : out std_logic;                     -- Write enable (1 pour écriture, 0 pour lecture)
        ddr_cmd_addr    : out std_logic_vector(27 downto 0); -- Adresse pour le contrôleur DDR
        
        ddr_wdata_valid : out std_logic;                     -- Données d'écriture valides
        ddr_wdata_ready : in  std_logic;                     -- Contrôleur prêt à recevoir des données
        ddr_wdata       : out std_logic_vector(63 downto 0); -- Données à écrire (64 bits pour DDR3)
        ddr_wdata_mask  : out std_logic_vector(7 downto 0);  -- Masque d'écriture (8 bits pour 64 bits)
        
        ddr_rdata_valid : in  std_logic;                     -- Données de lecture valides
        ddr_rdata_ready : out std_logic;                     -- Cache prêt à recevoir des données
        ddr_rdata       : in  std_logic_vector(63 downto 0)  -- Données lues (64 bits pour DDR3)
    );
end entity prismchrono_top;

architecture rtl of prismchrono_top is
    -- Signal de reset (actif haut)
    signal rst             : std_logic;
    
    -- Composant cœur CPU
    component prismchrono_core is
        port (
            clk             : in  std_logic;                     -- Horloge système
            rst             : in  std_logic;                     -- Reset asynchrone
            instr_data      : in  EncodedWord;                   -- Données d'instruction de la mémoire
            mem_data_in     : in  EncodedWord;                   -- Données de la mémoire (lecture)
            instr_addr      : out EncodedAddress;                -- Adresse pour la mémoire d'instructions
            mem_addr        : out EncodedAddress;                -- Adresse pour la mémoire de données
            mem_data_out    : out EncodedWord;                   -- Données pour la mémoire (écriture)
            mem_read        : out std_logic;                     -- Signal de lecture mémoire
            mem_write       : out std_logic;                     -- Signal d'écriture mémoire
            halted          : out std_logic;                     -- Signal indiquant que le CPU est arrêté
            debug_state     : out FsmStateType                   -- État courant de la FSM (pour debug)
        );
    end component;
    
    -- Composant contrôleur BRAM
    component bram_controller is
        port (
            clk             : in  std_logic;                     -- Horloge système
            rst             : in  std_logic;                     -- Reset asynchrone
            mem_addr        : in  EncodedAddress;                -- Adresse mémoire demandée par le CPU
            mem_data_in     : in  EncodedWord;                   -- Données à écrire en mémoire (mot complet)
            mem_tryte_in    : in  EncodedTryte;                  -- Tryte à écrire en mémoire (pour STORET)
            mem_read        : in  std_logic;                     -- Signal de lecture mémoire
            mem_write       : in  std_logic;                     -- Signal d'écriture mémoire (mot complet)
            mem_write_tryte : in  std_logic;                     -- Signal d'écriture mémoire (tryte)
            mem_data_out    : out EncodedWord;                   -- Données lues de la mémoire (mot complet)
            mem_tryte_out   : out EncodedTryte;                  -- Tryte lu de la mémoire (pour LOADT/LOADTU)
            mem_ready       : out std_logic;                     -- Signal indiquant que la mémoire est prête
            alignment_error : out std_logic;                     -- Signal indiquant une erreur d'alignement
            bram_addr       : out std_logic_vector(15 downto 0); -- Adresse pour la BRAM (binaire)
            bram_data_in    : in  std_logic_vector(47 downto 0); -- Données de la BRAM (binaire)
            bram_data_out   : out std_logic_vector(47 downto 0); -- Données pour la BRAM (binaire)
            bram_we         : out std_logic;                     -- Write enable pour la BRAM
            bram_en         : out std_logic;                     -- Enable pour la BRAM
            bram_tryte_sel  : out std_logic_vector(7 downto 0)   -- Sélection de tryte (8 trytes par mot)
        );
    end component;
    
    -- Composant contrôleur UART
    component uart_controller is
        generic (
            CLK_FREQ    : integer := 25000000;  -- Fréquence d'horloge en Hz
            BAUD_RATE   : integer := 115200      -- Débit en bauds
        );
        port (
            clk             : in  std_logic;                     -- Horloge système
            rst             : in  std_logic;                     -- Reset asynchrone
            addr            : in  EncodedAddress;                -- Adresse relative (offset depuis UART_BASE_ADDR)
            data_in         : in  EncodedWord;                   -- Données à écrire (depuis le CPU)
            data_out        : out EncodedWord;                   -- Données à lire (vers le CPU)
            read_en         : in  std_logic;                     -- Signal de lecture
            write_en        : in  std_logic;                     -- Signal d'écriture
            uart_tx_serial  : out std_logic;                     -- Sortie série TX
            uart_rx_serial  : in  std_logic                      -- Entrée série RX
        );
    end component;
    
    -- Composant cache L1 (ajouté pour le sprint 8)
    component l1_cache is
        generic (
            CACHE_SIZE_TRYTES : integer := 8192;
            LINE_SIZE_WORDS   : integer := 4;
            ASSOCIATIVITY     : integer := 2
        );
        port (
            clk             : in  std_logic;
            rst             : in  std_logic;
            -- Interface avec le cœur du processeur
            cpu_addr        : in  EncodedAddress;
            cpu_data_in     : in  EncodedWord;
            cpu_read        : in  std_logic;
            cpu_write       : in  std_logic;
            cpu_data_out    : out EncodedWord;
            cpu_ready       : out std_logic;
            cpu_stall       : out std_logic;
            -- Interface avec la mémoire externe
            mem_addr        : out EncodedAddress;
            mem_data_in     : in  EncodedWord;
            mem_data_out    : out EncodedWord;
            mem_read        : out std_logic;
            mem_write       : out std_logic;
            mem_ready       : in  std_logic
        );
    end component;
    
    -- Composant contrôleur DDR (ajouté pour le sprint 8)
    component ddr_controller is
        port (
            clk             : in  std_logic;
            rst             : in  std_logic;
            -- Interface avec le cache L1
            cache_addr      : in  EncodedAddress;
            cache_data_in   : in  EncodedWord;
            cache_read      : in  std_logic;
            cache_write     : in  std_logic;
            cache_data_out  : out EncodedWord;
            cache_ready     : out std_logic;
            -- Interface avec le contrôleur LiteDRAM
            ddr_cmd_valid   : out std_logic;
            ddr_cmd_ready   : in  std_logic;
            ddr_cmd_we      : out std_logic;
            ddr_cmd_addr    : out std_logic_vector(27 downto 0);
            ddr_wdata_valid : out std_logic;
            ddr_wdata_ready : in  std_logic;
            ddr_wdata       : out std_logic_vector(63 downto 0);
            ddr_wdata_mask  : out std_logic_vector(7 downto 0);
            ddr_rdata_valid : in  std_logic;
            ddr_rdata_ready : out std_logic;
            ddr_rdata       : in  std_logic_vector(63 downto 0)
        );
    end component;
    
    -- Signaux pour la mémoire d'instructions (BRAM)
    signal instr_addr      : EncodedAddress := (others => '0');
    signal instr_data      : EncodedWord := (others => '0');
    
    -- Signaux pour la mémoire de données (BRAM ou UART via MMIO)
    signal mem_addr        : EncodedAddress := (others => '0');
    signal mem_data_out    : EncodedWord := (others => '0');
    signal mem_data_in     : EncodedWord := (others => '0');
    signal mem_read        : std_logic := '0';
    signal mem_write       : std_logic := '0';
    
    -- Signaux pour le décodeur d'adresse MMIO
    signal bram_access     : std_logic := '0';
    signal uart_access     : std_logic := '0';
    signal uart_addr       : EncodedAddress := (others => '0');
    
    -- Signaux pour la BRAM
    signal bram_addr       : std_logic_vector(15 downto 0) := (others => '0');
    signal bram_data_in    : std_logic_vector(47 downto 0) := (others => '0');
    signal bram_data_out   : std_logic_vector(47 downto 0) := (others => '0');
    signal bram_we         : std_logic := '0';
    signal bram_en         : std_logic := '0';
    signal bram_tryte_sel  : std_logic_vector(7 downto 0) := (others => '0');
    signal bram_data_out_encoded : EncodedWord := (others => '0');
    
    -- Signaux pour l'UART
    signal uart_data_out   : EncodedWord := (others => '0');
    
    -- Signaux divers
    signal halted          : std_logic := '0';
    signal debug_state     : FsmStateType := RESET;
    signal mem_tryte_in    : EncodedTryte := (others => '0');
    signal mem_write_tryte : std_logic := '0';
    signal mem_tryte_out   : EncodedTryte := (others => '0');
    signal mem_ready       : std_logic := '0';
    signal alignment_error : std_logic := '0';
    
    -- Signaux pour le décodeur d'adresse DDR (ajoutés pour le sprint 8)
    signal ddr_access      : std_logic := '0';
    
    -- Signaux pour le cache L1 (ajoutés pour le sprint 8)
    signal cache_addr      : EncodedAddress := (others => '0');
    signal cache_data_in   : EncodedWord := (others => '0');
    signal cache_data_out  : EncodedWord := (others => '0');
    signal cache_read      : std_logic := '0';
    signal cache_write     : std_logic := '0';
    signal cache_ready     : std_logic := '0';
    signal cache_stall     : std_logic := '0';
    
    -- Signaux pour le contrôleur DDR (ajoutés pour le sprint 8)
    signal ddr_mem_addr    : EncodedAddress := (others => '0');
    signal ddr_mem_data_in : EncodedWord := (others => '0');
    signal ddr_mem_data_out: EncodedWord := (others => '0');
    signal ddr_mem_read    : std_logic := '0';
    signal ddr_mem_write   : std_logic := '0';
    signal ddr_mem_ready   : std_logic := '0';
    
begin
    -- Inversion du reset (actif bas -> actif haut)
    rst <= not rst_n;
    
    -- Décodeur d'adresse pour MMIO
    process(mem_addr)
    begin
        -- Par défaut, accès à la BRAM
        bram_access <= '0';
        uart_access <= '0';
        ddr_access <= '0';
        
        -- Vérification de la plage d'adresses UART
        if mem_addr >= UART_BASE_ADDR then
            uart_access <= '1';
        -- Vérification de la plage d'adresses DDR (au-delà de la BRAM)
        -- Supposons que la BRAM occupe les 64 kTrytes inférieurs (0x00000000 - 0x0000FFFF)
        elsif mem_addr(31 downto 16) /= X"0000" then
            ddr_access <= '1';
        else
            bram_access <= '1';
        end if;
    end process;
    
    -- Calcul de l'adresse relative pour l'UART
    uart_addr <= mem_addr - UART_BASE_ADDR;
    
    -- Multiplexeur pour les données lues (BRAM, UART ou DDR via cache)
    process(bram_access, uart_access, ddr_access, bram_data_out_encoded, uart_data_out, cache_data_out)
    begin
        if bram_access = '1' then
            mem_data_in <= bram_data_out_encoded;
        elsif uart_access = '1' then
            mem_data_in <= uart_data_out;
        elsif ddr_access = '1' then
            mem_data_in <= cache_data_out;
        else
            mem_data_in <= (others => '0');
        end if;
    end process;
    
    -- Multiplexeur pour le signal ready
    process(bram_access, uart_access, ddr_access, mem_ready, cache_ready)
    begin
        if ddr_access = '1' then
            mem_ready <= cache_ready;
        else
            mem_ready <= mem_ready;
        end if;
    end process;
    
    -- Instanciation du cœur CPU
    inst_prismchrono_core : prismchrono_core
        port map (
            clk => clk,
            rst => rst,
            instr_data => instr_data,
            mem_data_in => mem_data_in,
            instr_addr => instr_addr,
            mem_addr => mem_addr,
            mem_data_out => mem_data_out,
            mem_read => mem_read,
            mem_write => mem_write,
            halted => halted,
            debug_state => debug_state
        );
    
    -- Instanciation du contrôleur BRAM pour la mémoire d'instructions et de données
    inst_bram_controller : bram_controller
        port map (
            clk => clk,
            rst => rst,
            mem_addr => mem_addr,
            mem_data_in => mem_data_out,
            mem_tryte_in => mem_tryte_in,
            mem_read => mem_read and bram_access,
            mem_write => mem_write and bram_access,
            mem_write_tryte => mem_write_tryte,
            mem_data_out => bram_data_out_encoded,
            mem_tryte_out => mem_tryte_out,
            mem_ready => mem_ready,
            alignment_error => alignment_error,
            bram_addr => bram_addr,
            bram_data_in => bram_data_in,
            bram_data_out => bram_data_out,
            bram_we => bram_we,
            bram_en => bram_en,
            bram_tryte_sel => bram_tryte_sel
        );
    
    -- Instanciation du contrôleur UART
    inst_uart_controller : uart_controller
        generic map (
            CLK_FREQ => 25000000,  -- 25 MHz
            BAUD_RATE => 115200    -- 115200 bauds
        )
        port map (
            clk => clk,
            rst => rst,
            addr => uart_addr,
            data_in => mem_data_out,
            data_out => uart_data_out,
            read_en => mem_read and uart_access,
            write_en => mem_write and uart_access,
            uart_tx_serial => uart_tx_pin,
            uart_rx_serial => uart_rx_pin
        );
    
    -- Instanciation du cache L1 (ajouté pour le sprint 8)
    inst_l1_cache : l1_cache
        generic map (
            CACHE_SIZE_TRYTES => 8192,  -- 8 kTrytes
            LINE_SIZE_WORDS => 4,       -- 4 mots par ligne
            ASSOCIATIVITY => 2          -- 2-way set associative
        )
        port map (
            clk => clk,
            rst => rst,
            -- Interface avec le CPU
            cpu_addr => mem_addr,
            cpu_data_in => mem_data_out,
            cpu_read => mem_read and ddr_access,
            cpu_write => mem_write and ddr_access,
            cpu_data_out => cache_data_out,
            cpu_ready => cache_ready,
            cpu_stall => cache_stall,  -- À connecter au pipeline pour le staller
            -- Interface avec la mémoire externe
            mem_addr => ddr_mem_addr,
            mem_data_in => ddr_mem_data_out,
            mem_data_out => ddr_mem_data_in,
            mem_read => ddr_mem_read,
            mem_write => ddr_mem_write,
            mem_ready => ddr_mem_ready
        );
    
    -- Instanciation du contrôleur DDR (ajouté pour le sprint 8)
    inst_ddr_controller : ddr_controller
        port map (
            clk => clk,
            rst => rst,
            -- Interface avec le cache L1
            cache_addr => ddr_mem_addr,
            cache_data_in => ddr_mem_data_in,
            cache_read => ddr_mem_read,
            cache_write => ddr_mem_write,
            cache_data_out => ddr_mem_data_out,
            cache_ready => ddr_mem_ready,
            -- Interface avec le contrôleur LiteDRAM
            ddr_cmd_valid => ddr_cmd_valid,
            ddr_cmd_ready => ddr_cmd_ready,
            ddr_cmd_we => ddr_cmd_we,
            ddr_cmd_addr => ddr_cmd_addr,
            ddr_wdata_valid => ddr_wdata_valid,
            ddr_wdata_ready => ddr_wdata_ready,
            ddr_wdata => ddr_wdata,
            ddr_wdata_mask => ddr_wdata_mask,
            ddr_rdata_valid => ddr_rdata_valid,
            ddr_rdata_ready => ddr_rdata_ready,
            ddr_rdata => ddr_rdata
        );
    
    -- Connexion des LEDs de debug
    debug_led(0) <= halted;                  -- CPU arrêté
    debug_led(1) <= mem_read;                -- Lecture mémoire
    debug_led(2) <= mem_write;               -- Écriture mémoire
    debug_led(3) <= cache_stall;             -- Stall du cache
    debug_led(4) <= bram_access;             -- Accès BRAM
    debug_led(5) <= uart_access;             -- Accès UART
    debug_led(6) <= ddr_access;              -- Accès DDR
    debug_led(7) <= ddr_mem_ready;           -- DDR prête
    
end architecture rtl;