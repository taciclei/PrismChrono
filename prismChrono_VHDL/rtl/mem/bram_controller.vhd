library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Import du package de types personnalisé
library work;
use work.prismchrono_types_pkg.all;

-- Contrôleur BRAM pour PrismChrono
-- Ce module gère l'interface avec les primitives BRAM du FPGA
-- Il prend en charge l'encodage/décodage ternaire<->binaire et l'accès par tryte
entity bram_controller is
    port (
        clk             : in  std_logic;                     -- Horloge système
        rst             : in  std_logic;                     -- Reset asynchrone
        
        -- Interface avec le cœur du processeur
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
        
        -- Interface avec la BRAM (primitive FPGA)
        -- Ces signaux seraient connectés à la primitive BRAM spécifique du FPGA
        bram_addr       : out std_logic_vector(15 downto 0); -- Adresse pour la BRAM (binaire)
        bram_data_in    : in  std_logic_vector(47 downto 0); -- Données de la BRAM (binaire)
        bram_data_out   : out std_logic_vector(47 downto 0); -- Données pour la BRAM (binaire)
        bram_we         : out std_logic;                     -- Write enable pour la BRAM
        bram_en         : out std_logic;                     -- Enable pour la BRAM
        bram_tryte_sel  : out std_logic_vector(7 downto 0)   -- Sélection de tryte (8 trytes par mot)
    );
end entity bram_controller;

architecture rtl of bram_controller is
    -- Types pour la FSM du contrôleur BRAM
    type BramCtrlStateType is (
        IDLE,           -- État d'attente
        READ_WORD,      -- Lecture d'un mot complet
        READ_TRYTE,     -- Lecture d'un tryte
        WRITE_WORD,     -- Écriture d'un mot complet
        WRITE_TRYTE,    -- Écriture d'un tryte (nécessite read-modify-write)
        WAIT_BRAM       -- Attente de la BRAM
    );
    
    -- Signaux internes
    signal state_reg : BramCtrlStateType := IDLE;
    signal state_next : BramCtrlStateType := IDLE;
    
    -- Signaux pour le read-modify-write lors de l'écriture d'un tryte
    signal word_buffer : EncodedWord := (others => '0');
    signal tryte_index : integer range 0 to 7 := 0;
    
    -- Constantes pour l'alignement
    constant WORD_ALIGNMENT_MASK : std_logic_vector(31 downto 0) := X"FFFFFFF0"; -- Masque pour vérifier l'alignement sur 8 trytes
    
begin
    -- Processus synchrone pour mettre à jour l'état
    process(clk, rst)
    begin
        if rst = '1' then
            -- Réinitialisation de l'état
            state_reg <= IDLE;
            word_buffer <= (others => '0');
        elsif rising_edge(clk) then
            -- Mise à jour de l'état
            state_reg <= state_next;
            
            -- Mise à jour du buffer lors d'une lecture pour write-tryte
            if state_reg = WAIT_BRAM and state_next = WRITE_TRYTE then
                word_buffer <= bram_data_in;
            end if;
        end if;
    end process;
    
    -- Processus combinatoire pour calculer le prochain état
    process(state_reg, mem_read, mem_write, mem_write_tryte, mem_addr)
    begin
        -- Par défaut, on reste dans le même état
        state_next <= state_reg;
        
        -- Calcul du prochain état en fonction de l'état courant
        case state_reg is
            when IDLE =>
                -- Vérification de l'alignement pour les accès mot
                if (mem_read = '1' or mem_write = '1') and 
                   (mem_addr and not WORD_ALIGNMENT_MASK) /= 0 then
                    -- Erreur d'alignement, on reste en IDLE
                    state_next <= IDLE;
                -- Si demande de lecture mot
                elsif mem_read = '1' then
                    state_next <= READ_WORD;
                -- Si demande d'écriture mot
                elsif mem_write = '1' then
                    state_next <= WRITE_WORD;
                -- Si demande d'écriture tryte
                elsif mem_write_tryte = '1' then
                    -- Pour l'écriture d'un tryte, on doit d'abord lire le mot complet
                    state_next <= READ_TRYTE;
                end if;
                
            when READ_WORD =>
                -- Passage à l'état d'attente
                state_next <= WAIT_BRAM;
                
            when READ_TRYTE =>
                -- Passage à l'état d'attente
                state_next <= WAIT_BRAM;
                
            when WRITE_WORD =>
                -- Passage à l'état d'attente
                state_next <= WAIT_BRAM;
                
            when WRITE_TRYTE =>
                -- Passage à l'état d'attente
                state_next <= WAIT_BRAM;
                
            when WAIT_BRAM =>
                -- Retour à l'état d'attente après un cycle
                -- Dans une implémentation réelle, on attendrait un signal ready de la BRAM
                if state_reg = READ_TRYTE then
                    -- Après la lecture pour write-tryte, on passe à l'écriture
                    state_next <= WRITE_TRYTE;
                else
                    state_next <= IDLE;
                end if;
                
            when others =>
                -- Pour les états non reconnus, retour à l'état d'attente
                state_next <= IDLE;
        end case;
    end process;
    
    -- Calcul de l'index du tryte dans le mot
    -- L'adresse est en little-endian, donc les trytes de poids faible sont aux adresses basses
    tryte_index <= to_integer(unsigned(mem_addr(2 downto 0)));
    
    -- Processus combinatoire pour générer les signaux de sortie
    process(state_reg, mem_addr, mem_data_in, mem_tryte_in, tryte_index, word_buffer)
    begin
        -- Par défaut, tous les signaux de sortie sont désactivés
        mem_ready <= '0';
        alignment_error <= '0';
        bram_addr <= (others => '0');
        bram_data_out <= (others => '0');
        bram_we <= '0';
        bram_en <= '0';
        bram_tryte_sel <= (others => '0');
        mem_data_out <= (others => '0');
        mem_tryte_out <= (others => '0');
        
        -- Vérification de l'alignement pour les accès mot
        if (state_reg = IDLE) and ((mem_read = '1' or mem_write = '1') and 
           (mem_addr and not WORD_ALIGNMENT_MASK) /= 0) then
            -- Erreur d'alignement
            alignment_error <= '1';
            mem_ready <= '1'; -- On signale que la mémoire est prête (avec erreur)
        else
            -- Génération des signaux en fonction de l'état courant
            case state_reg is
                when IDLE =>
                    -- Aucun signal actif
                    null;
                    
                when READ_WORD =>
                    -- Lecture d'un mot complet
                    bram_addr <= mem_addr(15 downto 0) and WORD_ALIGNMENT_MASK(15 downto 0); -- Alignement sur 8 trytes
                    bram_en <= '1';
                    bram_we <= '0';
                    
                when READ_TRYTE =>
                    -- Lecture pour write-tryte (read-modify-write)
                    bram_addr <= mem_addr(15 downto 0) and WORD_ALIGNMENT_MASK(15 downto 0); -- Alignement sur 8 trytes
                    bram_en <= '1';
                    bram_we <= '0';
                    
                when WRITE_WORD =>
                    -- Écriture d'un mot complet
                    bram_addr <= mem_addr(15 downto 0) and WORD_ALIGNMENT_MASK(15 downto 0); -- Alignement sur 8 trytes
                    bram_data_out <= mem_data_in;
                    bram_en <= '1';
                    bram_we <= '1';
                    bram_tryte_sel <= (others => '1'); -- Tous les trytes sont sélectionnés
                    
                when WRITE_TRYTE =>
                    -- Écriture d'un tryte (après read-modify-write)
                    bram_addr <= mem_addr(15 downto 0) and WORD_ALIGNMENT_MASK(15 downto 0); -- Alignement sur 8 trytes
                    
                    -- On modifie uniquement le tryte concerné dans le mot lu précédemment
                    bram_data_out <= word_buffer;
                    case tryte_index is
                        when 0 => bram_data_out(5 downto 0) <= mem_tryte_in;
                        when 1 => bram_data_out(11 downto 6) <= mem_tryte_in;
                        when 2 => bram_data_out(17 downto 12) <= mem_tryte_in;
                        when 3 => bram_data_out(23 downto 18) <= mem_tryte_in;
                        when 4 => bram_data_out(29 downto 24) <= mem_tryte_in;
                        when 5 => bram_data_out(35 downto 30) <= mem_tryte_in;
                        when 6 => bram_data_out(41 downto 36) <= mem_tryte_in;
                        when 7 => bram_data_out(47 downto 42) <= mem_tryte_in;
                        when others => null;
                    end case;
                    
                    bram_en <= '1';
                    bram_we <= '1';
                    
                    -- On sélectionne uniquement le tryte à écrire
                    bram_tryte_sel <= (others => '0');
                    bram_tryte_sel(tryte_index) <= '1';
                    
                when WAIT_BRAM =>
                    -- Pendant l'attente, on maintient les signaux actifs
                    if state_reg = READ_WORD or state_reg = READ_TRYTE then
                        bram_addr <= mem_addr(15 downto 0) and WORD_ALIGNMENT_MASK(15 downto 0);
                        bram_en <= '1';
                        bram_we <= '0';
                        
                        -- Pour la lecture, on renvoie les données lues
                        if state_reg = READ_WORD then
                            mem_data_out <= bram_data_in;
                            mem_ready <= '1';
                        elsif state_reg = READ_TRYTE then
                            -- On extrait le tryte demandé
                            case tryte_index is
                                when 0 => mem_tryte_out <= bram_data_in(5 downto 0);
                                when 1 => mem_tryte_out <= bram_data_in(11 downto 6);
                                when 2 => mem_tryte_out <= bram_data_in(17 downto 12);
                                when 3 => mem_tryte_out <= bram_data_in(23 downto 18);
                                when 4 => mem_tryte_out <= bram_data_in(29 downto 24);
                                when 5 => mem_tryte_out <= bram_data_in(35 downto 30);
                                when 6 => mem_tryte_out <= bram_data_in(41 downto 36);
                                when 7 => mem_tryte_out <= bram_data_in(47 downto 42);
                                when others => mem_tryte_out <= (others => '0');
                            end case;
                            
                            -- On ne signale pas ready car on va passer à WRITE_TRYTE
                        end if;
                    elsif state_reg = WRITE_WORD then
                        bram_addr <= mem_addr(15 downto 0) and WORD_ALIGNMENT_MASK(15 downto 0);
                        bram_data_out <= mem_data_in;
                        bram_en <= '1';
                        bram_we <= '1';
                        bram_tryte_sel <= (others => '1');
                        mem_ready <= '1';
                    elsif state_reg = WRITE_TRYTE then
                        bram_addr <= mem_addr(15 downto 0) and WORD_ALIGNMENT_MASK(15 downto 0);
                        
                        -- On maintient les données modifiées
                        bram_data_out <= word_buffer;
                        case tryte_index is
                            when 0 => bram_data_out(5 downto 0) <= mem_tryte_in;
                            when 1 => bram_data_out(11 downto 6) <= mem_tryte_in;
                            when 2 => bram_data_out(17 downto 12) <= mem_tryte_in;
                            when 3 => bram_data_out(23 downto 18) <= mem_tryte_in;
                            when 4 => bram_data_out(29 downto 24) <= mem_tryte_in;
                            when 5 => bram_data_out(35 downto 30) <= mem_tryte_in;
                            when 6 => bram_data_out(41 downto 36) <= mem_tryte_in;
                            when 7 => bram_data_out(47 downto 42) <= mem_tryte_in;
                            when others => null;
                        end case;
                        
                        bram_en <= '1';
                        bram_we <= '1';
                        bram_tryte_sel <= (others => '0');
                        bram_tryte_sel(tryte_index) <= '1';
                        mem_ready <= '1';
                    end if;
                    
                when others =>
                    -- Pour les états non reconnus, aucun signal actif
                    null;
            end case;
        end if;
    end process;
    
end architecture rtl;