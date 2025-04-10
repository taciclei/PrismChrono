library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Package pour les types et constantes spécifiques au projet
library work;
use work.prismchrono_types_pkg.all;

entity l1_dcache is
    generic (
        CACHE_SIZE_BYTES : integer := 4096;  -- Taille totale du cache (4KB par défaut)
        LINE_SIZE_BYTES  : integer := 32;     -- Taille d'une ligne de cache (32B)
        ASSOCIATIVITY    : integer := 1       -- Cache direct-mapped pour commencer
    );
    port (
        -- Signaux de contrôle globaux
        clk             : in  std_logic;
        rst_n           : in  std_logic;
        
        -- Interface avec l'étage MEM
        mem_addr        : in  std_logic_vector(31 downto 0);  -- Adresse physique depuis la MMU
        mem_rd_en       : in  std_logic;                      -- Demande de lecture
        mem_wr_en       : in  std_logic;                      -- Demande d'écriture
        mem_wr_data     : in  std_logic_vector(31 downto 0);  -- Données à écrire
        mem_wr_mask     : in  std_logic_vector(3 downto 0);   -- Masque d'écriture (byte enable)
        mem_rd_data     : out std_logic_vector(31 downto 0);  -- Données lues
        mem_hit         : out std_logic;                      -- Hit/Miss
        mem_valid       : out std_logic;                      -- Données valides
        
        -- Interface avec la mémoire externe
        ext_addr        : out std_logic_vector(31 downto 0);  -- Adresse mémoire externe
        ext_rd_en       : out std_logic;                      -- Demande de lecture
        ext_wr_en       : out std_logic;                      -- Demande d'écriture (write-back)
        ext_wr_data     : out std_logic_vector(255 downto 0); -- Ligne à écrire
        ext_rd_data     : in  std_logic_vector(255 downto 0); -- Ligne lue
        ext_valid       : in  std_logic;                      -- Données externes valides
        ext_ready       : in  std_logic                       -- Mémoire externe prête
    );
end entity l1_dcache;

architecture rtl of l1_dcache is
    -- Constantes dérivées
    constant TAG_BITS       : integer := 20;  -- Bits de tag
    constant INDEX_BITS     : integer := 7;   -- Bits d'index (128 lignes)
    constant OFFSET_BITS    : integer := 5;   -- Bits d'offset (32B par ligne)
    constant WORDS_PER_LINE : integer := LINE_SIZE_BYTES / 4;
    
    -- Types pour les structures du cache
    type tag_array_t is array(0 to (2**INDEX_BITS)-1) of std_logic_vector(TAG_BITS-1 downto 0);
    type valid_array_t is array(0 to (2**INDEX_BITS)-1) of std_logic;
    type dirty_array_t is array(0 to (2**INDEX_BITS)-1) of std_logic;
    type data_array_t is array(0 to (2**INDEX_BITS)-1) of std_logic_vector(LINE_SIZE_BYTES*8-1 downto 0);
    
    -- Signaux pour les composants du cache
    signal tag_array   : tag_array_t;
    signal valid_array : valid_array_t;
    signal dirty_array : dirty_array_t;
    signal data_array  : data_array_t;
    
    -- Signaux pour l'extraction d'adresse
    signal addr_tag    : std_logic_vector(TAG_BITS-1 downto 0);
    signal addr_index  : std_logic_vector(INDEX_BITS-1 downto 0);
    signal addr_offset : std_logic_vector(OFFSET_BITS-1 downto 0);
    
    -- Signaux de contrôle interne
    signal hit_internal   : std_logic;
    signal current_index  : integer range 0 to (2**INDEX_BITS)-1;
    signal current_offset : integer range 0 to WORDS_PER_LINE-1;
    
    -- FSM pour la gestion des miss et write-back
    type state_t is (IDLE, WRITE_BACK, FETCH_LINE, UPDATE_CACHE);
    signal state : state_t;
    
begin
    -- Extraction des champs d'adresse
    addr_tag    <= mem_addr(31 downto 32-TAG_BITS);
    addr_index  <= mem_addr(31-TAG_BITS downto OFFSET_BITS);
    addr_offset <= mem_addr(OFFSET_BITS-1 downto 0);
    
    -- Conversion des indices
    current_index  <= to_integer(unsigned(addr_index));
    current_offset <= to_integer(unsigned(addr_offset(OFFSET_BITS-1 downto 2)));
    
    -- Logique de hit/miss
    hit_internal <= '1' when (valid_array(current_index) = '1' and 
                             tag_array(current_index) = addr_tag) else '0';
    
    -- Process principal de contrôle
    process(clk, rst_n)
        variable word_offset : integer;
        variable byte_offset : integer;
    begin
        if rst_n = '0' then
            -- Reset asynchrone
            valid_array <= (others => '0');
            dirty_array <= (others => '0');
            state <= IDLE;
            mem_valid <= '0';
            ext_rd_en <= '0';
            ext_wr_en <= '0';
            
        elsif rising_edge(clk) then
            case state is
                when IDLE =>
                    if (mem_rd_en = '1' or mem_wr_en = '1') then
                        if hit_internal = '1' then
                            -- Cache hit
                            if mem_rd_en = '1' then
                                -- Lecture
                                mem_rd_data <= data_array(current_index)((current_offset+1)*32-1 downto current_offset*32);
                                mem_valid <= '1';
                            else
                                -- Écriture
                                word_offset := current_offset * 32;
                                for i in 0 to 3 loop
                                    if mem_wr_mask(i) = '1' then
                                        byte_offset := word_offset + (i * 8);
                                        data_array(current_index)(byte_offset+7 downto byte_offset) <=
                                            mem_wr_data((i+1)*8-1 downto i*8);
                                    end if;
                                end loop;
                                dirty_array(current_index) <= '1';
                                mem_valid <= '1';
                            end if;
                        else
                            -- Cache miss
                            mem_valid <= '0';
                            if dirty_array(current_index) = '1' then
                                -- Write-back nécessaire
                                state <= WRITE_BACK;
                                ext_addr <= tag_array(current_index) & 
                                           addr_index & 
                                           (OFFSET_BITS-1 downto 0 => '0');
                                ext_wr_data <= data_array(current_index);
                                ext_wr_en <= '1';
                            else
                                -- Fetch direct
                                state <= FETCH_LINE;
                                ext_addr <= mem_addr(31 downto OFFSET_BITS) & 
                                           (OFFSET_BITS-1 downto 0 => '0');
                                ext_rd_en <= '1';
                            end if;
                        end if;
                    else
                        mem_valid <= '0';
                    end if;
                    
                when WRITE_BACK =>
                    if ext_valid = '1' then
                        -- Write-back terminé, on peut fetch
                        ext_wr_en <= '0';
                        state <= FETCH_LINE;
                        ext_addr <= mem_addr(31 downto OFFSET_BITS) & 
                                   (OFFSET_BITS-1 downto 0 => '0');
                        ext_rd_en <= '1';
                    end if;
                    
                when FETCH_LINE =>
                    if ext_valid = '1' then
                        -- Ligne récupérée
                        ext_rd_en <= '0';
                        state <= UPDATE_CACHE;
                        data_array(current_index) <= ext_rd_data;
                        tag_array(current_index) <= addr_tag;
                        valid_array(current_index) <= '1';
                        dirty_array(current_index) <= '0';
                    end if;
                    
                when UPDATE_CACHE =>
                    -- Mise à jour terminée
                    state <= IDLE;
                    if mem_rd_en = '1' then
                        mem_rd_data <= ext_rd_data((current_offset+1)*32-1 downto current_offset*32);
                        mem_valid <= '1';
                    elsif mem_wr_en = '1' then
                        word_offset := current_offset * 32;
                        for i in 0 to 3 loop
                            if mem_wr_mask(i) = '1' then
                                byte_offset := word_offset + (i * 8);
                                data_array(current_index)(byte_offset+7 downto byte_offset) <=
                                    mem_wr_data((i+1)*8-1 downto i*8);
                            end if;
                        end loop;
                        dirty_array(current_index) <= '1';
                        mem_valid <= '1';
                    end if;
            end case;
        end if;
    end process;
    
    -- Sorties combinatoires
    mem_hit <= hit_internal;
    
end architecture rtl;