library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.prismchrono_types_pkg.all;

entity tlb is
  generic (
    ENTRIES : integer := 8  -- Nombre d'entrées TLB (puissance de 2)
  );
  port (
    -- Signaux de contrôle
    clk           : in  std_logic;
    rst_n         : in  std_logic;
    flush         : in  std_logic;  -- Pour SFENCE.VMA_T
    
    -- Interface recherche
    va_in         : in  std_logic_vector(23 downto 0);  -- Adresse virtuelle
    priv_mode     : in  std_logic_vector(1 downto 0);   -- Mode privilège
    access_type   : in  std_logic_vector(1 downto 0);   -- Type d'accès
    
    -- Interface mise à jour
    update        : in  std_logic;  -- Signal de mise à jour
    update_va     : in  std_logic_vector(23 downto 0);  -- VA à mettre à jour
    update_pa     : in  std_logic_vector(23 downto 0);  -- PA correspondante
    update_perms  : in  std_logic_vector(2 downto 0);   -- Permissions RWX
    
    -- Sorties
    hit           : out std_logic;  -- '1' si trouvé dans TLB
    pa_out        : out std_logic_vector(23 downto 0);  -- PA traduite
    perms_out     : out std_logic_vector(2 downto 0);   -- Permissions
    fault         : out std_logic   -- '1' si violation de permission
  );
end entity tlb;

architecture rtl of tlb is
  -- Structure d'une entrée TLB
  type tlb_entry_t is record
    valid   : std_logic;
    va_tag  : std_logic_vector(17 downto 0);  -- Tag VA (18 trits)
    pa_base : std_logic_vector(17 downto 0);  -- Base PA (18 trits)
    rwx     : std_logic_vector(2 downto 0);   -- Permissions R/W/X
    asid    : std_logic_vector(5 downto 0);   -- ASID (optionnel)
  end record;
  
  type tlb_array_t is array(0 to ENTRIES-1) of tlb_entry_t;
  signal tlb_array : tlb_array_t;
  
  -- Compteur pour politique de remplacement simple
  signal replace_ptr : integer range 0 to ENTRIES-1;
  
begin
  -- Processus principal
  process(clk, rst_n)
  begin
    if rst_n = '0' then
      -- Reset toutes les entrées
      for i in 0 to ENTRIES-1 loop
        tlb_array(i).valid <= '0';
      end loop;
      replace_ptr <= 0;
      hit <= '0';
      fault <= '0';
      
    elsif rising_edge(clk) then
      -- Reset signaux de sortie
      hit <= '0';
      fault <= '0';
      
      -- Flush TLB si demandé
      if flush = '1' then
        for i in 0 to ENTRIES-1 loop
          tlb_array(i).valid <= '0';
        end loop;
        
      -- Mise à jour TLB
      elsif update = '1' then
        tlb_array(replace_ptr).valid <= '1';
        tlb_array(replace_ptr).va_tag <= update_va(23 downto 6);
        tlb_array(replace_ptr).pa_base <= update_pa(23 downto 6);
        tlb_array(replace_ptr).rwx <= update_perms;
        
        -- Incrémenter pointeur de remplacement
        if replace_ptr = ENTRIES-1 then
          replace_ptr <= 0;
        else
          replace_ptr <= replace_ptr + 1;
        end if;
        
      -- Recherche dans TLB
      else
        for i in 0 to ENTRIES-1 loop
          if tlb_array(i).valid = '1' and tlb_array(i).va_tag = va_in(23 downto 6) then
            hit <= '1';
            pa_out <= tlb_array(i).pa_base & va_in(5 downto 0);
            perms_out <= tlb_array(i).rwx;
            
            -- Vérifier permissions
            case access_type is
              when "00" => -- Read
                fault <= not tlb_array(i).rwx(2);
              when "01" => -- Write
                fault <= not tlb_array(i).rwx(1);
              when "10" => -- Execute
                fault <= not tlb_array(i).rwx(0);
              when others =>
                fault <= '1';
            end case;
            
            exit;
          end if;
        end loop;
      end if;
    end if;
  end process;
  
end architecture rtl;