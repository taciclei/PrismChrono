library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Import du package de types personnalisé
library work;
use work.prismchrono_types_pkg.all;

-- Contrôleur de mémoire externe (SDRAM/DDR3L) pour PrismChrono
-- Ce module sert d'adaptateur entre l'interface du cache L1 et le contrôleur LiteDRAM
-- Il gère la conversion des signaux et protocoles entre les deux interfaces
entity ddr_controller is
    port (
        clk             : in  std_logic;                     -- Horloge système
        rst             : in  std_logic;                     -- Reset asynchrone
        
        -- Interface avec le cache L1
        cache_addr      : in  EncodedAddress;                -- Adresse mémoire demandée par le cache
        cache_data_in   : in  EncodedWord;                   -- Données à écrire en mémoire
        cache_read      : in  std_logic;                     -- Signal de lecture mémoire
        cache_write     : in  std_logic;                     -- Signal d'écriture mémoire
        cache_data_out  : out EncodedWord;                   -- Données lues de la mémoire
        cache_ready     : out std_logic;                     -- Signal indiquant que la mémoire est prête
        
        -- Interface avec le contrôleur LiteDRAM (ou autre contrôleur DDR/SDRAM)
        -- Ces signaux seraient adaptés selon l'interface spécifique du contrôleur utilisé
        -- Interface simplifiée pour l'exemple (à adapter selon le contrôleur réel)
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
end entity ddr_controller;

architecture rtl of ddr_controller is
    -- Types pour la FSM du contrôleur DDR
    type DdrCtrlStateType is (
        IDLE,           -- État d'attente
        CMD_ISSUE,      -- Émission de la commande
        WRITE_DATA,     -- Envoi des données d'écriture
        READ_WAIT,      -- Attente des données de lecture
        COMPLETE        -- Opération terminée
    );
    
    -- Signaux internes
    signal state_reg : DdrCtrlStateType := IDLE;
    signal state_next : DdrCtrlStateType := IDLE;
    
    -- Registres pour stocker les requêtes
    signal addr_reg : EncodedAddress := (others => '0');
    signal data_reg : EncodedWord := (others => '0');
    signal we_reg   : std_logic := '0';
    
    -- Fonction pour convertir l'adresse ternaire en adresse binaire pour le DDR
    function convert_address(addr : EncodedAddress) return std_logic_vector is
        variable result : std_logic_vector(27 downto 0);
    begin
        -- Conversion simplifiée - à adapter selon le mapping mémoire réel
        -- Typiquement, on ignorerait les bits de poids faible pour l'alignement
        -- et on décalerait l'adresse selon la largeur du bus DDR
        result := std_logic_vector(resize(unsigned(addr(27 downto 0)), 28));
        return result;
    end function;
    
    -- Fonction pour convertir les données ternaires en données binaires pour le DDR
    function convert_data_to_ddr(data : EncodedWord) return std_logic_vector is
        variable result : std_logic_vector(63 downto 0);
    begin
        -- Conversion simplifiée - à adapter selon l'encodage ternaire réel
        -- Pour l'exemple, on suppose que EncodedWord fait 48 bits (8 trytes * 6 bits)
        -- et on l'étend à 64 bits pour le DDR3
        result := std_logic_vector(resize(unsigned(data), 64));
        return result;
    end function;
    
    -- Fonction pour convertir les données binaires du DDR en données ternaires
    function convert_data_from_ddr(data : std_logic_vector(63 downto 0)) return EncodedWord is
        variable result : EncodedWord;
    begin
        -- Conversion simplifiée - à adapter selon l'encodage ternaire réel
        -- Pour l'exemple, on prend les 48 bits de poids faible
        result := data(47 downto 0);
        return result;
    end function;
    
begin
    -- Processus synchrone pour mettre à jour l'état
    process(clk, rst)
    begin
        if rst = '1' then
            -- Réinitialisation de l'état
            state_reg <= IDLE;
            addr_reg <= (others => '0');
            data_reg <= (others => '0');
            we_reg <= '0';
        elsif rising_edge(clk) then
            -- Mise à jour de l'état
            state_reg <= state_next;
            
            -- Enregistrement des requêtes
            if state_reg = IDLE and (cache_read = '1' or cache_write = '1') then
                addr_reg <= cache_addr;
                data_reg <= cache_data_in;
                we_reg <= cache_write;
            end if;
        end if;
    end process;
    
    -- Processus combinatoire pour calculer le prochain état
    process(state_reg, cache_read, cache_write, ddr_cmd_ready, ddr_wdata_ready, ddr_rdata_valid, we_reg)
    begin
        -- Par défaut, on reste dans le même état
        state_next <= state_reg;
        
        -- Calcul du prochain état en fonction de l'état courant
        case state_reg is
            when IDLE =>
                -- Si demande de lecture ou d'écriture
                if cache_read = '1' or cache_write = '1' then
                    state_next <= CMD_ISSUE;
                end if;
                
            when CMD_ISSUE =>
                -- Si le contrôleur DDR est prêt à recevoir une commande
                if ddr_cmd_ready = '1' then
                    -- Si c'est une écriture, passer à l'envoi des données
                    if we_reg = '1' then
                        state_next <= WRITE_DATA;
                    -- Si c'est une lecture, attendre les données
                    else
                        state_next <= READ_WAIT;
                    end if;
                end if;
                
            when WRITE_DATA =>
                -- Si le contrôleur DDR est prêt à recevoir des données
                if ddr_wdata_ready = '1' then
                    state_next <= COMPLETE;
                end if;
                
            when READ_WAIT =>
                -- Si les données de lecture sont valides
                if ddr_rdata_valid = '1' then
                    state_next <= COMPLETE;
                end if;
                
            when COMPLETE =>
                -- Opération terminée, retour à l'état d'attente
                state_next <= IDLE;
                
            when others =>
                -- Pour les états non reconnus, retour à l'état d'attente
                state_next <= IDLE;
        end case;
    end process;
    
    -- Processus combinatoire pour générer les signaux de sortie
    process(state_reg, addr_reg, data_reg, we_reg, ddr_rdata, ddr_rdata_valid)
    begin
        -- Par défaut, tous les signaux de sortie sont désactivés
        cache_data_out <= (others => '0');
        cache_ready <= '0';
        ddr_cmd_valid <= '0';
        ddr_cmd_we <= '0';
        ddr_cmd_addr <= (others => '0');
        ddr_wdata_valid <= '0';
        ddr_wdata <= (others => '0');
        ddr_wdata_mask <= (others => '0');
        ddr_rdata_ready <= '0';
        
        -- Génération des signaux en fonction de l'état courant
        case state_reg is
            when IDLE =>
                -- Contrôleur prêt à recevoir des requêtes
                cache_ready <= '1';
                
            when CMD_ISSUE =>
                -- Émission de la commande au contrôleur DDR
                ddr_cmd_valid <= '1';
                ddr_cmd_we <= we_reg;
                ddr_cmd_addr <= convert_address(addr_reg);
                
            when WRITE_DATA =>
                -- Envoi des données d'écriture au contrôleur DDR
                ddr_wdata_valid <= '1';
                ddr_wdata <= convert_data_to_ddr(data_reg);
                ddr_wdata_mask <= (others => '0');  -- Pas de masquage pour l'exemple
                
            when READ_WAIT =>
                -- Attente des données de lecture du contrôleur DDR
                ddr_rdata_ready <= '1';
                
                -- Si les données sont valides, les convertir et les envoyer au cache
                if ddr_rdata_valid = '1' then
                    cache_data_out <= convert_data_from_ddr(ddr_rdata);
                end if;
                
            when COMPLETE =>
                -- Opération terminée, signaler au cache
                cache_ready <= '1';
                
                -- Si c'était une lecture, maintenir les données valides
                if we_reg = '0' then
                    cache_data_out <= convert_data_from_ddr(ddr_rdata);
                end if;
                
            when others =>
                -- Pour les états non reconnus, aucun signal actif
                null;
        end case;
    end process;
    
end architecture rtl;