library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Import du package de types personnalisé
library work;
use work.prismchrono_types_pkg.all;

package cache_coherence_pkg is
    -- Types pour le protocole MSI
    type CacheLineStateType is (M, S, I);  -- Modified, Shared, Invalid
    
    -- Encodage ternaire des états MSI (2 trits)
    constant MSI_M : std_logic_vector(3 downto 0) := "0001";  -- Modified  (1)
    constant MSI_S : std_logic_vector(3 downto 0) := "0000";  -- Shared    (0)
    constant MSI_I : std_logic_vector(3 downto 0) := "1111";  -- Invalid   (-1)
    
    -- Types de messages pour le protocole de cohérence
    type CoherenceMessageType is (
        MSG_READ,           -- Lecture simple
        MSG_READ_SHARED,    -- Lecture avec intention de partager
        MSG_READ_MODIFIED,  -- Lecture avec intention de modifier
        MSG_INVALIDATE,     -- Demande d'invalidation
        MSG_WB_REQ,        -- Demande de write-back
        MSG_WB_RESP        -- Réponse de write-back avec données
    );
    
    -- Structure pour les messages de cohérence
    type CoherenceMessageRecord is record
        msg_type    : CoherenceMessageType;
        address     : EncodedAddress;
        source_id   : integer;              -- ID du cœur source
        data        : EncodedWord;          -- Données (pour write-back)
    end record;
    
    -- Fonctions pour la gestion des états MSI
    function encode_msi_state(state : CacheLineStateType) return std_logic_vector;
    function decode_msi_state(encoded : std_logic_vector) return CacheLineStateType;
    
    -- Fonctions pour les transitions d'état
    function next_state_on_read(
        current_state : CacheLineStateType;
        msg : CoherenceMessageType
    ) return CacheLineStateType;
    
    function next_state_on_write(
        current_state : CacheLineStateType;
        msg : CoherenceMessageType
    ) return CacheLineStateType;
    
    function next_state_on_snoop(
        current_state : CacheLineStateType;
        msg : CoherenceMessageType
    ) return CacheLineStateType;
    
end package cache_coherence_pkg;

package body cache_coherence_pkg is
    -- Implémentation de l'encodage des états MSI
    function encode_msi_state(state : CacheLineStateType) return std_logic_vector is
    begin
        case state is
            when M => return MSI_M;
            when S => return MSI_S;
            when I => return MSI_I;
        end case;
    end function;
    
    -- Implémentation du décodage des états MSI
    function decode_msi_state(encoded : std_logic_vector) return CacheLineStateType is
    begin
        case encoded is
            when MSI_M => return M;
            when MSI_S => return S;
            when others => return I;
        end case;
    end function;
    
    -- Implémentation des transitions d'état pour une lecture
    function next_state_on_read(
        current_state : CacheLineStateType;
        msg : CoherenceMessageType
    ) return CacheLineStateType is
    begin
        case current_state is
            when I =>
                case msg is
                    when MSG_READ_SHARED => return S;
                    when MSG_READ_MODIFIED => return M;
                    when others => return I;
                end case;
            when S =>
                case msg is
                    when MSG_READ_MODIFIED => return M;
                    when others => return S;
                end case;
            when M =>
                return M;
        end case;
    end function;
    
    -- Implémentation des transitions d'état pour une écriture
    function next_state_on_write(
        current_state : CacheLineStateType;
        msg : CoherenceMessageType
    ) return CacheLineStateType is
    begin
        case current_state is
            when I | S => return M;
            when M => return M;
        end case;
    end function;
    
    -- Implémentation des transitions d'état pour un snoop
    function next_state_on_snoop(
        current_state : CacheLineStateType;
        msg : CoherenceMessageType
    ) return CacheLineStateType is
    begin
        case current_state is
            when M =>
                case msg is
                    when MSG_READ_SHARED => return S;
                    when MSG_INVALIDATE | MSG_READ_MODIFIED => return I;
                    when others => return M;
                end case;
            when S =>
                case msg is
                    when MSG_INVALIDATE | MSG_READ_MODIFIED => return I;
                    when others => return S;
                end case;
            when I =>
                return I;
        end case;
    end function;
    
end package body cache_coherence_pkg;