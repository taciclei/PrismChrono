library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Package pour les types et constantes spécifiques au projet
library work;
use work.prismchrono_types_pkg.all;

entity l1_icache is
    generic (
        CACHE_SIZE_BYTES : integer := 4096;  -- Taille totale du cache (4KB par défaut)
        LINE_SIZE_BYTES  : integer := 32;     -- Taille d'une ligne de cache (32B)
        ASSOCIATIVITY    : integer := 1       -- Cache direct-mapped pour commencer
    );
    port (
        -- Signaux de contrôle globaux
        clk             : in  std_logic;
        rst_n           : in  std_logic;
        
        -- Interface avec l'étage IF
        if_addr         : in  std_logic_vector(31 downto 0);  -- Adresse physique depuis la MMU
        if_rd_en        : in  std_logic;                      -- Demande de lecture
        if_data         : out std_logic_vector(31 downto 0);  -- Instruction lue
        if_hit          : out std_logic;                      -- Hit/Miss
        if_valid        : out std_logic;                      -- Données valides
        
        -- Interface avec la mémoire externe
        mem_addr        : out std_logic_vector(31 downto 0);  -- Adresse pour le fetch de ligne
        mem_rd_en       : out std_logic;                      -- Demande de lecture mémoire
        mem_data        : in  std_logic_vector(255 downto 0); -- Ligne de cache depuis la mémoire
        mem_valid       : in  std_logic;                      -- Données mémoire valides
        mem_ready       : in  std_logic                       -- Mémoire prête pour transaction
    );
end entity l1_icache;

architecture rtl of l1_icache is
    -- Constantes dérivées
    constant TAG_BITS       : integer := 20;  -- Bits de tag (dépend de la taille cache)
    constant INDEX_BITS     : integer := 7;   -- Bits d'index (128 lignes pour 4KB)
    constant OFFSET_BITS    : integer := 5;   -- Bits d'offset (32B par ligne)
    constant WORDS_PER_LINE : integer := LINE_SIZE_BYTES / 4;
    
    -- Types pour les structures de données du cache
    type tag_array_t is array(0 to (2**INDEX_BITS)-1) of std_logic_vector(TAG_BITS-1 downto 0);
    type valid_array_t is array(0 to (2**INDEX_BITS)-1) of std_logic;
    type data_array_t is array(0 to (2**INDEX_BITS)-1) of std_logic_vector(LINE_SIZE_BYTES*8-1 downto 0);
    
    -- Signaux pour les composants du cache
    signal tag_array   : tag_array_t;
    signal valid_array : valid_array_t;
    signal data_array  : data_array_t;
    
    -- Signaux pour l'extraction d'adresse
    signal addr_tag    : std_logic_vector(TAG_BITS-1 downto 0);
    signal addr_index  : std_logic_vector(INDEX_BITS-1 downto 0);
    signal addr_offset : std_logic_vector(OFFSET_BITS-1 downto 0);
    
    -- Signaux de contrôle interne
    signal hit_internal   : std_logic;
    signal miss_handling  : std_logic;
    signal current_index  : integer range 0 to (2**INDEX_BITS)-1;
    signal current_offset : integer range 0 to WORDS_PER_LINE-1;
    
 begin
    -- Extraction des champs d'adresse
    addr_tag    <= if_addr(31 downto 32-TAG_BITS);
    addr_index  <= if_addr(31-TAG_BITS downto OFFSET_BITS);
    addr_offset <= if_addr(OFFSET_BITS-1 downto 0);
    
    -- Conversion des indices
    current_index  <= to_integer(unsigned(addr_index));
    current_offset <= to_integer(unsigned(addr_offset(OFFSET_BITS-1 downto 2)));
    
    -- Logique de hit/miss
    hit_internal <= '1' when (valid_array(current_index) = '1' and 
                             tag_array(current_index) = addr_tag) else '0';
    
    -- Process principal de contrôle
    process(clk, rst_n)
    begin
        if rst_n = '0' then
            -- Reset asynchrone
            valid_array <= (others => '0');
            miss_handling <= '0';
            if_valid <= '0';
            mem_rd_en <= '0';
            
        elsif rising_edge(clk) then
            if if_rd_en = '1' then
                if hit_internal = '1' then
                    -- Cache hit
                    if_data <= data_array(current_index)((current_offset+1)*32-1 downto current_offset*32);
                    if_valid <= '1';
                    
                elsif not miss_handling then
                    -- Début de miss handling
                    miss_handling <= '1';
                    mem_addr <= if_addr(31 downto OFFSET_BITS) & (OFFSET_BITS-1 downto 0 => '0');
                    mem_rd_en <= '1';
                    if_valid <= '0';
                end if;
                
            elsif miss_handling = '1' and mem_valid = '1' then
                -- Fin de miss handling
                data_array(current_index) <= mem_data;
                tag_array(current_index) <= addr_tag;
                valid_array(current_index) <= '1';
                miss_handling <= '0';
                mem_rd_en <= '0';
                
                -- Fournir directement la donnée demandée
                if_data <= mem_data((current_offset+1)*32-1 downto current_offset*32);
                if_valid <= '1';
            end if;
        end if;
    end process;
    
    -- Sorties combinatoires
    if_hit <= hit_internal;
    
end architecture rtl;