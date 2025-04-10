library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_plic_simple is
end entity tb_plic_simple;

architecture sim of tb_plic_simple is
    -- Constantes
    constant CLK_PERIOD : time := 10 ns;
    constant NUM_SOURCES : positive := 4;
    constant NUM_TARGETS : positive := 2;
    constant PRIO_BITS : positive := 3;
    
    -- Signaux de test
    signal clk : std_logic := '0';
    signal rst_n : std_logic := '0';
    signal irq_sources : std_logic_vector(NUM_SOURCES-1 downto 0) := (others => '0');
    signal addr : std_logic_vector(11 downto 0) := (others => '0');
    signal wdata : std_logic_vector(31 downto 0) := (others => '0');
    signal rdata : std_logic_vector(31 downto 0);
    signal we : std_logic := '0';
    signal re : std_logic := '0';
    signal irq_targets : std_logic_vector(NUM_TARGETS-1 downto 0);
    
    -- Procédure pour écrire dans un registre
    procedure write_reg(addr_in : in std_logic_vector(11 downto 0);
                       data_in : in std_logic_vector(31 downto 0)) is
    begin
        addr <= addr_in;
        wdata <= data_in;
        we <= '1';
        wait for CLK_PERIOD;
        we <= '0';
        wait for CLK_PERIOD;
    end procedure;
    
    -- Procédure pour lire un registre
    procedure read_reg(addr_in : in std_logic_vector(11 downto 0);
                      data_out : out std_logic_vector(31 downto 0)) is
    begin
        addr <= addr_in;
        re <= '1';
        wait for CLK_PERIOD;
        data_out := rdata;
        re <= '0';
        wait for CLK_PERIOD;
    end procedure;
    
begin
    -- Instanciation du PLIC
    uut: entity work.plic_simple
        generic map (
            NUM_SOURCES => NUM_SOURCES,
            NUM_TARGETS => NUM_TARGETS,
            PRIO_BITS => PRIO_BITS
        )
        port map (
            clk => clk,
            rst_n => rst_n,
            irq_sources => irq_sources,
            addr => addr,
            wdata => wdata,
            rdata => rdata,
            we => we,
            re => re,
            irq_targets => irq_targets
        );
    
    -- Génération de l'horloge
    clk <= not clk after CLK_PERIOD/2;
    
    -- Processus de test
    process
        variable read_data : std_logic_vector(31 downto 0);
    begin
        -- Reset initial
        rst_n <= '0';
        wait for CLK_PERIOD * 2;
        rst_n <= '1';
        wait for CLK_PERIOD * 2;
        
        -- Test 1: Configuration des priorités
        report "Test 1: Configuration des priorités";
        -- Source 0: priorité 1
        write_reg(x"000", x"00000001");
        -- Source 1: priorité 2
        write_reg(x"004", x"00000002");
        -- Source 2: priorité 3
        write_reg(x"008", x"00000003");
        -- Source 3: priorité 4
        write_reg(x"00C", x"00000004");
        
        -- Test 2: Activation des interruptions
        report "Test 2: Activation des interruptions";
        -- Active toutes les sources pour la cible 0
        write_reg(x"200", x"00000001"); -- Source 0
        write_reg(x"204", x"00000001"); -- Source 1
        write_reg(x"208", x"00000001"); -- Source 2
        write_reg(x"20C", x"00000001"); -- Source 3
        
        -- Test 3: Seuil d'interruption
        report "Test 3: Configuration du seuil";
        -- Seuil = 2 pour la cible 0
        write_reg(x"300", x"00000002");
        
        -- Test 4: Déclenchement d'interruptions
        report "Test 4: Déclenchement d'interruptions";
        -- Déclenche les sources 1 et 3
        irq_sources <= "1010";
        wait for CLK_PERIOD * 2;
        
        -- Test 5: Vérification de l'interruption la plus prioritaire
        report "Test 5: Vérification de claim/complete";
        read_reg(x"400", read_data);
        assert read_data = x"00000003"
            report "Erreur: Mauvaise source d'interruption retournée"
            severity error;
        
        -- Test 6: Complete l'interruption
        report "Test 6: Complete interruption";
        write_reg(x"400", x"00000003");
        wait for CLK_PERIOD * 2;
        
        -- Test 7: Vérification de la prochaine interruption
        report "Test 7: Vérification interruption suivante";
        read_reg(x"400", read_data);
        assert read_data = x"00000001"
            report "Erreur: Mauvaise source d'interruption suivante"
            severity error;
        
        -- Fin des tests
        report "Fin des tests";
        wait;
    end process;
    
end architecture sim;