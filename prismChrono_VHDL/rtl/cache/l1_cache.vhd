library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Import des packages personnalisés
library work;
use work.prismchrono_types_pkg.all;
use work.cache_coherence_pkg.all;

-- Cache L1 pour PrismChrono
-- Ce module implémente un cache L1 unifié simple entre le CPU et la mémoire externe
-- Il utilise une politique de remplacement LRU et une politique d'écriture Write-Back
entity l1_cache is
    generic (
        -- Paramètres du cache
        CACHE_SIZE_TRYTES : integer := 8192;                -- Taille totale du cache en trytes (8 kTrytes)
        LINE_SIZE_WORDS   : integer := 4;                   -- Taille d'une ligne de cache en mots (4 mots = 32 trytes)
        ASSOCIATIVITY     : integer := 2                    -- Associativité du cache (2-way set associative)
    );
    port (
        clk             : in  std_logic;                     -- Horloge système
        rst             : in  std_logic;                     -- Reset asynchrone
        
        -- Interface avec le cœur du processeur
        cpu_addr        : in  EncodedAddress;                -- Adresse mémoire demandée par le CPU
        cpu_data_in     : in  EncodedWord;                   -- Données à écrire en mémoire
        cpu_read        : in  std_logic;                     -- Signal de lecture mémoire
        cpu_write       : in  std_logic;                     -- Signal d'écriture mémoire
        cpu_data_out    : out EncodedWord;                   -- Données lues de la mémoire
        cpu_ready       : out std_logic;                     -- Signal indiquant que le cache est prêt
        cpu_stall       : out std_logic;                     -- Signal pour staller le CPU en cas de miss
        
        -- Interface avec la mémoire externe (SDRAM/DDR3L via contrôleur)
        mem_addr        : out EncodedAddress;                -- Adresse pour la mémoire externe
        mem_data_in     : in  EncodedWord;                   -- Données de la mémoire externe (lecture)
        mem_data_out    : out EncodedWord;                   -- Données pour la mémoire externe (écriture)
        mem_read        : out std_logic;                     -- Signal de lecture mémoire externe
        mem_write       : out std_logic;                     -- Signal d'écriture mémoire externe
        mem_ready       : in  std_logic;                     -- Signal indiquant que la mémoire externe est prête
        
        -- Interface de cohérence de cache
        core_id         : in  integer;                       -- Identifiant unique du cœur
        snoop_msg       : in  CoherenceMessageRecord;        -- Message de cohérence entrant
        snoop_msg_valid : in  std_logic;                     -- Message de cohérence valide
        snoop_resp      : out CoherenceMessageRecord;        -- Réponse de cohérence
        snoop_resp_valid: out std_logic                      -- Réponse de cohérence valide
    );
end entity l1_cache;

architecture rtl of l1_cache is
    -- Constantes dérivées des génériques
    constant WORD_SIZE_TRYTES    : integer := 8;                                -- Taille d'un mot en trytes
    constant LINE_SIZE_TRYTES    : integer := LINE_SIZE_WORDS * WORD_SIZE_TRYTES; -- Taille d'une ligne en trytes
    constant NUM_LINES           : integer := CACHE_SIZE_TRYTES / LINE_SIZE_TRYTES; -- Nombre de lignes dans le cache
    constant NUM_SETS            : integer := NUM_LINES / ASSOCIATIVITY;        -- Nombre de sets dans le cache
    
    -- Nombre de bits pour les différentes parties de l'adresse
    constant OFFSET_BITS         : integer := 3;                                -- Bits pour l'offset dans un mot (8 trytes)
    constant LINE_OFFSET_BITS    : integer := integer(log2(real(LINE_SIZE_WORDS))); -- Bits pour l'offset dans une ligne
    constant INDEX_BITS          : integer := integer(log2(real(NUM_SETS)));    -- Bits pour l'index du set
    constant TAG_BITS            : integer := 32 - INDEX_BITS - LINE_OFFSET_BITS - OFFSET_BITS; -- Bits pour le tag
    
    -- Types pour les structures du cache
    type CacheLineType is record
        valid   : std_logic;                                 -- Bit de validité
        dirty   : std_logic;                                 -- Bit de dirty (pour write-back)
        tag     : std_logic_vector(TAG_BITS-1 downto 0);     -- Tag de la ligne
        lru     : std_logic;                                 -- Bit LRU (pour 2-way set associative)
        data    : EncodedWord_Array(0 to LINE_SIZE_WORDS-1); -- Données de la ligne
        state   : CacheLineStateType;                        -- État MSI de la ligne
    end record;
    
    type CacheSetType is array(0 to ASSOCIATIVITY-1) of CacheLineType;
    type CacheType is array(0 to NUM_SETS-1) of CacheSetType;
    
    -- Mémoire du cache
    signal cache : CacheType := (others => (others => (valid => '0', dirty => '0', 
                                                      tag => (others => '0'), lru => '0', 
                                                      data => (others => (others => '0')),
                                                      state => I)));
    
    -- Types pour la FSM du contrôleur de cache
    type CacheStateType is (
        IDLE,           -- État d'attente
        CHECK_TAG,      -- Vérification du tag
        READ_MEM,       -- Lecture depuis la mémoire externe (miss)
        WRITE_MEM,      -- Écriture vers la mémoire externe (writeback)
        UPDATE_CACHE,   -- Mise à jour du cache
        WAIT_MEM,       -- Attente de la mémoire externe
        HANDLE_SNOOP,   -- Traitement d'un message de cohérence
        SNOOP_WB        -- Write-back suite à un snoop
    );
    
    -- Signaux internes
    signal state_reg : CacheStateType := IDLE;
    signal state_next : CacheStateType := IDLE;
    
    -- Signaux pour le décodage d'adresse
    signal addr_tag     : std_logic_vector(TAG_BITS-1 downto 0);
    signal addr_index   : integer range 0 to NUM_SETS-1;
    signal addr_offset  : integer range 0 to LINE_SIZE_WORDS-1;
    signal word_offset  : integer range 0 to WORD_SIZE_TRYTES-1;
    
    -- Signaux pour la gestion du cache
    signal hit              : std_logic := '0';
    signal hit_way          : integer range 0 to ASSOCIATIVITY-1 := 0;
    signal replace_way      : integer range 0 to ASSOCIATIVITY-1 := 0;
    signal current_line     : CacheLineType;
    signal mem_addr_line    : EncodedAddress;
    signal mem_addr_word    : EncodedAddress;
    signal line_counter     : integer range 0 to LINE_SIZE_WORDS-1 := 0;
    signal need_writeback   : std_logic := '0';
    
    -- Signaux pour la cohérence de cache
    signal snoop_hit        : std_logic := '0';
    signal snoop_hit_way    : integer range 0 to ASSOCIATIVITY-1 := 0;
    signal snoop_addr_tag   : std_logic_vector(TAG_BITS-1 downto 0);
    signal snoop_addr_index : integer range 0 to NUM_SETS-1;
    signal snoop_need_wb    : std_logic := '0';
    signal snoop_msg_reg    : CoherenceMessageRecord;
    signal snoop_resp_reg   : CoherenceMessageRecord;
    
    -- Fonction pour extraire le tag d'une adresse
    function get_tag(addr : EncodedAddress) return std_logic_vector is
    begin
        return addr(31 downto 32-TAG_BITS);
    end function;
    
    -- Fonction pour extraire l'index d'une adresse
    function get_index(addr : EncodedAddress) return integer is
    begin
        return to_integer(unsigned(addr(32-TAG_BITS-1 downto LINE_OFFSET_BITS+OFFSET_BITS)));
    end function;
    
    -- Fonction pour extraire l'offset de ligne d'une adresse
    function get_line_offset(addr : EncodedAddress) return integer is
    begin
        return to_integer(unsigned(addr(LINE_OFFSET_BITS+OFFSET_BITS-1 downto OFFSET_BITS)));
    end function;
    
    -- Fonction pour extraire l'offset de mot d'une adresse
    function get_word_offset(addr : EncodedAddress) return integer is
    begin
        return to_integer(unsigned(addr(OFFSET_BITS-1 downto 0)));
    end function;
    
    -- Fonction pour construire une adresse de ligne à partir du tag et de l'index
    function make_line_addr(tag : std_logic_vector; index : integer) return EncodedAddress is
        variable addr : EncodedAddress := (others => '0');
    begin
        addr(31 downto 32-TAG_BITS) := tag;
        addr(32-TAG_BITS-1 downto LINE_OFFSET_BITS+OFFSET_BITS) := std_logic_vector(to_unsigned(index, INDEX_BITS));
        return addr;
    end function;
    
    -- Fonction pour construire une adresse de mot à partir de l'adresse de ligne et de l'offset
    function make_word_addr(line_addr : EncodedAddress; offset : integer) return EncodedAddress is
        variable addr : EncodedAddress := line_addr;
    begin
        addr(LINE_OFFSET_BITS+OFFSET_BITS-1 downto OFFSET_BITS) := std_logic_vector(to_unsigned(offset, LINE_OFFSET_BITS));
        return addr;
    end function;
    
begin
    -- Décodage de l'adresse
    addr_tag <= get_tag(cpu_addr);
    addr_index <= get_index(cpu_addr);
    addr_offset <= get_line_offset(cpu_addr);
    word_offset <= get_word_offset(cpu_addr);
    
    -- Processus synchrone pour mettre à jour l'état
    process(clk, rst)
    begin
        if rst = '1' then
            -- Réinitialisation de l'état et du cache
            state_reg <= IDLE;
            cache <= (others => (others => (valid => '0', dirty => '0', 
                                           tag => (others => '0'), lru => '0', 
                                           data => (others => (others => '0')),
                                           state => I)));
            snoop_resp_valid <= '0';
            snoop_msg_reg <= (
                msg_type => MSG_READ,
                address => (others => '0'),
                source_id => 0,
                data => (others => '0')
            );
            line_counter <= 0;
        elsif rising_edge(clk) then
            -- Mise à jour de l'état
            state_reg <= state_next;
            
            -- Actions spécifiques à chaque état
            case state_reg is
                when CHECK_TAG =>
                    -- Mise à jour du bit LRU en cas de hit
                    if hit = '1' then
                        -- Mettre à jour le bit LRU pour marquer cette voie comme récemment utilisée
                        if hit_way = 0 then
                            cache(addr_index)(0).lru <= '0';
                            cache(addr_index)(1).lru <= '1';
                        else
                            cache(addr_index)(0).lru <= '1';
                            cache(addr_index)(1).lru <= '0';
                        end if;
                        
                        -- En cas d'écriture, mettre à jour les données et marquer comme dirty
                        if cpu_write = '1' then
                            cache(addr_index)(hit_way).data(addr_offset) <= cpu_data_in;
                            cache(addr_index)(hit_way).dirty <= '1';
                        end if;
                    end if;
                    
                when WAIT_MEM =>
                    -- En cas de lecture mémoire, stocker les données reçues
                    if state_next = UPDATE_CACHE and mem_ready = '1' then
                        cache(addr_index)(replace_way).data(line_counter) <= mem_data_in;
                        
                        -- Incrémenter le compteur de ligne
                        if line_counter < LINE_SIZE_WORDS-1 then
                            line_counter <= line_counter + 1;
                        else
                            line_counter <= 0;
                            -- Marquer la ligne comme valide et mettre à jour l'état MSI
                            cache(addr_index)(replace_way).valid <= '1';
                            cache(addr_index)(replace_way).dirty <= '0';
                            cache(addr_index)(replace_way).tag <= addr_tag;
                            cache(addr_index)(replace_way).state <= next_state_on_read(I, MSG_READ_SHARED);
                            
                when HANDLE_SNOOP =>
                    if snoop_hit = '1' then
                        -- Mettre à jour l'état de la ligne selon le message de snoop
                        cache(snoop_addr_index)(snoop_hit_way).state <= 
                            next_state_on_snoop(cache(snoop_addr_index)(snoop_hit_way).state,
                                                snoop_msg_reg.msg_type);
                        
                        -- Si nécessaire, préparer le write-back
                        if snoop_need_wb = '1' then
                            state_reg <= SNOOP_WB;
                            snoop_resp_reg.msg_type <= MSG_WB_RESP;
                            snoop_resp_reg.data <= cache(snoop_addr_index)(snoop_hit_way).data(0);
                            snoop_resp_valid <= '1';
                        end if;
                        
                when SNOOP_WB =>
                    -- Envoyer les données de write-back
                    if mem_ready = '1' then
                        if line_counter < LINE_SIZE_WORDS-1 then
                            line_counter <= line_counter + 1;
                            snoop_resp_reg.data <= cache(snoop_addr_index)(snoop_hit_way).data(line_counter + 1);
                        else
                            line_counter <= 0;
                            state_reg <= IDLE;
                            snoop_resp_valid <= '0';
                        end if;
                            
                            -- Mettre à jour les bits LRU
                            if replace_way = 0 then
                                cache(addr_index)(0).lru <= '0';
                                cache(addr_index)(1).lru <= '1';
                            else
                                cache(addr_index)(0).lru <= '1';
                                cache(addr_index)(1).lru <= '0';
                            end if;
                        end if;
                    end if;
                    
                when UPDATE_CACHE =>
                    -- Si c'était une écriture, mettre à jour les données et marquer comme dirty
                    if cpu_write = '1' then
                        cache(addr_index)(replace_way).data(addr_offset) <= cpu_data_in;
                        cache(addr_index)(replace_way).dirty <= '1';
                    end if;
                    
                when others =>
                    null;
            end case;
        end if;
    end process;
    
    -- Processus combinatoire pour vérifier le hit/miss et déterminer la voie à remplacer
    process(cache, addr_tag, addr_index)
    begin
        -- Par défaut, pas de hit
        hit <= '0';
        hit_way <= 0;
        replace_way <= 0;
        need_writeback <= '0';
        
        -- Vérifier si l'adresse est dans le cache
        for i in 0 to ASSOCIATIVITY-1 loop
            if cache(addr_index)(i).valid = '1' and cache(addr_index)(i).tag = addr_tag then
                hit <= '1';
                hit_way <= i;
            end if;
        end loop;
        
        -- Déterminer la voie à remplacer en cas de miss (politique LRU)
        if cache(addr_index)(0).lru = '1' then
            replace_way <= 0;
            -- Vérifier si la ligne à remplacer est dirty (nécessite writeback)
            if cache(addr_index)(0).valid = '1' and cache(addr_index)(0).dirty = '1' then
                need_writeback <= '1';
            end if;
        else
            replace_way <= 1;
            -- Vérifier si la ligne à remplacer est dirty (nécessite writeback)
            if cache(addr_index)(1).valid = '1' and cache(addr_index)(1).dirty = '1' then
                need_writeback <= '1';
            end if;
        end if;
    end process;
    
    -- Sélection de la ligne courante pour les opérations
    current_line <= cache(addr_index)(hit_way) when hit = '1' else cache(addr_index)(replace_way);
    
    -- Construction des adresses pour les accès mémoire
    mem_addr_line <= make_line_addr(current_line.tag, addr_index);
    mem_addr_word <= make_word_addr(mem_addr_line, line_counter);
    
    -- Processus combinatoire pour la FSM du cache
    process(state_reg, cpu_read, cpu_write, hit, need_writeback, mem_ready, 
            snoop_msg_valid, snoop_hit, snoop_need_wb)
    begin
        -- Valeurs par défaut
        state_next <= state_reg;
        mem_read <= '0';
        mem_write <= '0';
        cpu_ready <= '0';
        cpu_stall <= '1';
        snoop_resp_valid <= '0';
        
        case state_reg is
            when IDLE =>
                cpu_stall <= '0';
                if snoop_msg_valid = '1' then
                    state_next <= HANDLE_SNOOP;
                elsif cpu_read = '1' or cpu_write = '1' then
                    state_next <= CHECK_TAG;
                end if;
                
            when CHECK_TAG =>
                if hit = '1' then
                    -- Cache hit
                    if cpu_write = '1' then
                        -- Mettre à jour l'état MSI pour une écriture
                        cache(addr_index)(hit_way).state <= next_state_on_write(
                            cache(addr_index)(hit_way).state, MSG_READ_MODIFIED);
                    end if;
                    cpu_ready <= '1';
                    state_next <= IDLE;
                else
                    -- Cache miss
                    if need_writeback = '1' then
                        state_next <= WRITE_MEM;
                    else
                        state_next <= READ_MEM;
                    end if;
                end if;
                
            when WRITE_MEM =>
                mem_write <= '1';
                if mem_ready = '1' then
                    state_next <= READ_MEM;
                end if;
                
            when READ_MEM =>
                mem_read <= '1';
                if mem_ready = '1' then
                    state_next <= WAIT_MEM;
                end if;
                
            when WAIT_MEM =>
                if mem_ready = '1' then
                    if line_counter = LINE_SIZE_WORDS-1 then
                        state_next <= UPDATE_CACHE;
                    end if;
                end if;
                
            when UPDATE_CACHE =>
                cpu_ready <= '1';
                state_next <= IDLE;
                
            when HANDLE_SNOOP =>
                if snoop_hit = '1' then
                    if snoop_need_wb = '1' then
                        state_next <= SNOOP_WB;
                    else
                        state_next <= IDLE;
                    end if;
                else
                    state_next <= IDLE;
                end if;
                
            when SNOOP_WB =>
                mem_write <= '1';
                if mem_ready = '1' and line_counter = LINE_SIZE_WORDS-1 then
                    state_next <= IDLE;
                end if;
        end case;
    end process;
    
    -- Processus combinatoire pour générer les signaux de sortie
    process(state_reg, cpu_addr, cpu_data_in, hit, hit_way, current_line, addr_offset, 
            mem_addr_line, mem_addr_word, line_counter, mem_data_in)
    begin
        -- Par défaut, tous les signaux de sortie sont désactivés
        cpu_ready <= '0';
        cpu_stall <= '0';
        cpu_data_out <= (others => '0');
        mem_addr <= (others => '0');
        mem_data_out <= (others => '0');
        mem_read <= '0';
        mem_write <= '0';
        
        -- Génération des signaux en fonction de l'état courant
        case state_reg is
            when IDLE =>
                -- Cache prêt à recevoir des requêtes
                cpu_ready <= '1';
                cpu_stall <= '0';
                
            when CHECK_TAG =>
                -- Si hit, retourner les données immédiatement
                if hit = '1' then
                    cpu_data_out <= cache(addr_index)(hit_way).data(addr_offset);
                    cpu_ready <= '1';
                    cpu_stall <= '0';
                else
                    -- Sinon, staller le CPU
                    cpu_stall <= '1';
                end if;
                
            when WRITE_MEM =>
                -- Écriture d'une ligne dirty vers la mémoire externe
                mem_addr <= mem_addr_word;
                mem_data_out <= current_line.data(line_counter);
                mem_write <= '1';
                cpu_stall <= '1';
                
            when READ_MEM =>
                -- Lecture d'une ligne depuis la mémoire externe
                mem_addr <= make_word_addr(make_line_addr(addr_tag, addr_index), line_counter);
                mem_read <= '1';
                cpu_stall <= '1';
                
            when WAIT_MEM =>
                -- Maintien des signaux pendant l'attente
                if state_next = WRITE_MEM then
                    mem_addr <= mem_addr_word;
                    mem_data_out <= current_line.data(line_counter);
                    mem_write <= '1';
                elsif state_next = READ_MEM then
                    mem_addr <= make_word_addr(make_line_addr(addr_tag, addr_index), line_counter);
                    mem_read <= '1';
                end if;
                cpu_stall <= '1';
                
            when UPDATE_CACHE =>
                -- Si c'était une lecture, retourner les données
                if cpu_read = '1' then
                    cpu_data_out <= cache(addr_index)(replace_way).data(addr_offset);
                end if;
                cpu_ready <= '1';
                cpu_stall <= '0';
                
            when others =>
                -- Pour les états non reconnus, staller le CPU
                cpu_stall <= '1';
        end case;
    end process;
    
end architecture rtl;