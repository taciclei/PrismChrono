library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Import du package de types personnalisé
library work;
use work.prismchrono_types_pkg.all;

entity memory_controller is
    port (
        clk             : in  std_logic;                     -- Horloge système
        rst             : in  std_logic;                     -- Reset asynchrone
        -- Interface avec le cœur du processeur
        mem_addr        : in  EncodedAddress;                -- Adresse mémoire demandée par le CPU
        mem_data_in     : in  EncodedWord;                   -- Données à écrire en mémoire
        mem_read        : in  std_logic;                     -- Signal de lecture mémoire
        mem_write       : in  std_logic;                     -- Signal d'écriture mémoire
        mem_data_out    : out EncodedWord;                   -- Données lues de la mémoire
        mem_ready       : out std_logic;                     -- Signal indiquant que la mémoire est prête
        -- Interface avec la mémoire externe
        ext_mem_addr    : out EncodedAddress;                -- Adresse pour la mémoire externe
        ext_mem_data_in : in  EncodedWord;                   -- Données de la mémoire externe (lecture)
        ext_mem_data_out: out EncodedWord;                   -- Données pour la mémoire externe (écriture)
        ext_mem_read    : out std_logic;                     -- Signal de lecture mémoire externe
        ext_mem_write   : out std_logic;                     -- Signal d'écriture mémoire externe
        ext_mem_ready   : in  std_logic                      -- Signal indiquant que la mémoire externe est prête
    );
end entity memory_controller;

architecture rtl of memory_controller is
    -- Types pour la FSM du contrôleur de mémoire
    type MemCtrlStateType is (
        IDLE,           -- État d'attente
        READ_REQ,       -- Demande de lecture
        READ_WAIT,      -- Attente de la réponse de lecture
        WRITE_REQ,      -- Demande d'écriture
        WRITE_WAIT      -- Attente de la confirmation d'écriture
    );
    
    -- Signaux internes
    signal state_reg : MemCtrlStateType := IDLE;
    signal state_next : MemCtrlStateType := IDLE;
    
    -- Cache simple (pour extension future)
    signal cache_valid : std_logic := '0';
    signal cache_addr : EncodedAddress := (others => '0');
    signal cache_data : EncodedWord := (others => '0');
    
begin
    -- Processus synchrone pour mettre à jour l'état
    process(clk, rst)
    begin
        if rst = '1' then
            -- Réinitialisation de l'état
            state_reg <= IDLE;
            cache_valid <= '0';
            cache_addr <= (others => '0');
            cache_data <= (others => '0');
        elsif rising_edge(clk) then
            -- Mise à jour de l'état
            state_reg <= state_next;
            
            -- Mise à jour du cache lors d'une lecture réussie
            if state_reg = READ_WAIT and ext_mem_ready = '1' then
                cache_valid <= '1';
                cache_addr <= mem_addr;
                cache_data <= ext_mem_data_in;
            end if;
        end if;
    end process;
    
    -- Processus combinatoire pour calculer le prochain état
    process(state_reg, mem_read, mem_write, ext_mem_ready, mem_addr, cache_valid, cache_addr)
    begin
        -- Par défaut, on reste dans le même état
        state_next <= state_reg;
        
        -- Calcul du prochain état en fonction de l'état courant
        case state_reg is
            when IDLE =>
                -- Si demande de lecture et pas de hit dans le cache
                if mem_read = '1' and (cache_valid = '0' or cache_addr /= mem_addr) then
                    state_next <= READ_REQ;
                -- Si demande d'écriture
                elsif mem_write = '1' then
                    state_next <= WRITE_REQ;
                end if;
                
            when READ_REQ =>
                -- Passage à l'état d'attente
                state_next <= READ_WAIT;
                
            when READ_WAIT =>
                -- Si la mémoire externe est prête, retour à l'état d'attente
                if ext_mem_ready = '1' then
                    state_next <= IDLE;
                end if;
                
            when WRITE_REQ =>
                -- Passage à l'état d'attente
                state_next <= WRITE_WAIT;
                
            when WRITE_WAIT =>
                -- Si la mémoire externe est prête, retour à l'état d'attente
                if ext_mem_ready = '1' then
                    state_next <= IDLE;
                    -- Invalidation du cache si l'adresse écrite correspond à celle en cache
                    if cache_valid = '1' and cache_addr = mem_addr then
                        cache_valid <= '0';
                    end if;
                end if;
                
            when others =>
                -- Pour les états non reconnus, retour à l'état d'attente
                state_next <= IDLE;
        end case;
    end process;
    
    -- Processus combinatoire pour générer les signaux de sortie
    process(state_reg, mem_addr, mem_data_in, ext_mem_data_in, ext_mem_ready, cache_valid, cache_addr, cache_data)
    begin
        -- Par défaut, tous les signaux de sortie sont désactivés
        mem_ready <= '0';
        ext_mem_addr <= (others => '0');
        ext_mem_data_out <= (others => '0');
        ext_mem_read <= '0';
        ext_mem_write <= '0';
        
        -- Si hit dans le cache pour une lecture
        if state_reg = IDLE and cache_valid = '1' and cache_addr = mem_addr then
            mem_data_out <= cache_data;
            mem_ready <= '1';
        -- Sinon, données de la mémoire externe
        elsif state_reg = READ_WAIT and ext_mem_ready = '1' then
            mem_data_out <= ext_mem_data_in;
            mem_ready <= '1';
        else
            mem_data_out <= (others => '0');
        end if;
        
        -- Génération des signaux en fonction de l'état courant
        case state_reg is
            when IDLE =>
                -- Aucun signal actif
                null;
                
            when READ_REQ =>
                -- Demande de lecture à la mémoire externe
                ext_mem_addr <= mem_addr;
                ext_mem_read <= '1';
                
            when READ_WAIT =>
                -- Maintien de la demande de lecture
                ext_mem_addr <= mem_addr;
                ext_mem_read <= '1';
                
            when WRITE_REQ =>
                -- Demande d'écriture à la mémoire externe
                ext_mem_addr <= mem_addr;
                ext_mem_data_out <= mem_data_in;
                ext_mem_write <= '1';
                
            when WRITE_WAIT =>
                -- Maintien de la demande d'écriture
                ext_mem_addr <= mem_addr;
                ext_mem_data_out <= mem_data_in;
                ext_mem_write <= '1';
                -- Signal ready quand l'écriture est terminée
                if ext_mem_ready = '1' then
                    mem_ready <= '1';
                end if;
                
            when others =>
                -- Pour les états non reconnus, aucun signal actif
                null;
        end case;
    end process;
    
end architecture rtl;