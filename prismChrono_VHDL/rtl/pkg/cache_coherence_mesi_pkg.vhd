library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Package pour le protocole de cohérence MESI
package cache_coherence_mesi_pkg is
    -- États MESI pour les lignes de cache
    type CacheLineStateType is (M, E, S, I);
    
    -- Types de messages de cohérence MESI
    type CoherenceMessageType is (
        -- Messages de base
        MSG_READ,           -- Lecture simple
        MSG_WRITE,          -- Écriture
        MSG_INVALIDATE,     -- Demande d'invalidation
        MSG_WB_REQ,         -- Demande de write-back
        -- Messages spécifiques MESI
        MSG_READ_EXCLUSIVE, -- Lecture pour obtenir état Exclusive
        MSG_SHARE,          -- Passage à l'état Shared
        MSG_UPGRADE,        -- Upgrade de Shared vers Modified
        -- Réponses
        MSG_DATA,           -- Réponse avec données
        MSG_ACK,            -- Acquittement simple
        MSG_NACK            -- Réponse négative
    );
    
    -- Structure d'un message de cohérence
    type CoherenceMessageRecord is record
        msg_type    : CoherenceMessageType;    -- Type de message
        address     : std_logic_vector(31 downto 0); -- Adresse concernée
        source_id   : integer;                -- ID du cœur source
        data        : std_logic_vector(63 downto 0); -- Données (si nécessaire)
    end record;
    
    -- Fonctions de transition d'état MESI
    function next_state_on_read(
        current_state : CacheLineStateType;
        shared : boolean
    ) return CacheLineStateType;
    
    function next_state_on_write(
        current_state : CacheLineStateType;
        has_other_copies : boolean
    ) return CacheLineStateType;
    
    function next_state_on_remote_read(
        current_state : CacheLineStateType
    ) return CacheLineStateType;
    
    function next_state_on_remote_write(
        current_state : CacheLineStateType
    ) return CacheLineStateType;
    
    function needs_writeback(
        current_state : CacheLineStateType
    ) return boolean;
    
    function can_modify(
        current_state : CacheLineStateType
    ) return boolean;
end package cache_coherence_mesi_pkg;

package body cache_coherence_mesi_pkg is
    -- Implémentation des fonctions de transition
    function next_state_on_read(
        current_state : CacheLineStateType;
        shared : boolean
    ) return CacheLineStateType is
    begin
        case current_state is
            when I =>
                if shared then
                    return S;
                else
                    return E;
                end if;
            when others =>
                return current_state;
        end case;
    end function;
    
    function next_state_on_write(
        current_state : CacheLineStateType;
        has_other_copies : boolean
    ) return CacheLineStateType is
    begin
        -- Toute écriture met la ligne en état Modified
        return M;
    end function;
    
    function next_state_on_remote_read(
        current_state : CacheLineStateType
    ) return CacheLineStateType is
    begin
        case current_state is
            when M | E =>
                return S;
            when others =>
                return current_state;
        end case;
    end function;
    
    function next_state_on_remote_write(
        current_state : CacheLineStateType
    ) return CacheLineStateType is
    begin
        -- Toute écriture distante invalide la ligne
        return I;
    end function;
    
    function needs_writeback(
        current_state : CacheLineStateType
    ) return boolean is
    begin
        return current_state = M;
    end function;
    
    function can_modify(
        current_state : CacheLineStateType
    ) return boolean is
    begin
        return current_state = M or current_state = E;
    end function;
end package body cache_coherence_mesi_pkg;