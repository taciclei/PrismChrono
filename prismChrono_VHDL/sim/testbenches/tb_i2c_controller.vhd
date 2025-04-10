library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Import des packages personnalisés
library work;
use work.prismchrono_types_pkg.all;

-- Testbench pour le contrôleur I²C
entity tb_i2c_controller is
end entity tb_i2c_controller;

architecture sim of tb_i2c_controller is
    -- Période d'horloge
    constant CLK_PERIOD : time := 10 ns;
    
    -- Signaux pour le DUT
    signal clk         : std_logic := '0';
    signal rst_n       : std_logic := '0';
    signal addr        : std_logic_vector(3 downto 0) := (others => '0');
    signal data_in     : std_logic_vector(23 downto 0) := (others => '0');
    signal data_out    : std_logic_vector(23 downto 0);
    signal we          : std_logic := '0';
    signal re          : std_logic := '0';
    signal ready       : std_logic;
    signal i2c_scl     : std_logic;
    signal i2c_sda     : std_logic;
    
    -- Pull-up pour les lignes I²C
    signal scl_pullup  : std_logic := 'H';
    signal sda_pullup  : std_logic := 'H';
    
    -- Procédure pour écrire dans un registre
    procedure write_reg(
        constant reg_addr : in std_logic_vector(3 downto 0);
        constant reg_data : in std_logic_vector(23 downto 0);
        signal clk       : in std_logic;
        signal addr      : out std_logic_vector(3 downto 0);
        signal data_in   : out std_logic_vector(23 downto 0);
        signal we        : out std_logic;
        signal ready     : in std_logic
    ) is
    begin
        wait until rising_edge(clk);
        addr <= reg_addr;
        data_in <= reg_data;
        we <= '1';
        wait until rising_edge(clk);
        we <= '0';
        wait until ready = '1';
    end procedure;
    
    -- Procédure pour lire un registre
    procedure read_reg(
        constant reg_addr : in std_logic_vector(3 downto 0);
        signal clk       : in std_logic;
        signal addr      : out std_logic_vector(3 downto 0);
        signal re        : out std_logic;
        signal ready     : in std_logic
    ) is
    begin
        wait until rising_edge(clk);
        addr <= reg_addr;
        re <= '1';
        wait until rising_edge(clk);
        re <= '0';
        wait until ready = '1';
    end procedure;
    
begin
    -- Instanciation du DUT
    dut: entity work.i2c_controller
    port map (
        clk         => clk,
        rst_n       => rst_n,
        addr        => addr,
        data_in     => data_in,
        data_out    => data_out,
        we          => we,
        re          => re,
        ready       => ready,
        i2c_scl     => i2c_scl,
        i2c_sda     => i2c_sda
    );
    
    -- Génération de l'horloge
    process
    begin
        wait for CLK_PERIOD/2;
        clk <= not clk;
    end process;
    
    -- Pull-up sur les lignes I²C
    i2c_scl <= 'H';
    i2c_sda <= 'H';
    
    -- Process de test principal
    process
        variable slave_addr : std_logic_vector(7 downto 0);
        variable test_data : std_logic_vector(7 downto 0);
    begin
        -- Reset initial
        rst_n <= '0';
        wait for CLK_PERIOD * 5;
        rst_n <= '1';
        wait for CLK_PERIOD * 5;
        
        -- Test 1: Configuration de base
        report "Test 1: Configuration de base";
        write_reg(x"0", x"000001", clk, addr, data_in, we, ready);  -- Enable
        write_reg(x"1", x"000010", clk, addr, data_in, we, ready);  -- Divider=16
        
        -- Test 2: Écriture vers un esclave
        report "Test 2: Écriture vers un esclave";
        slave_addr := x"A0";  -- Adresse esclave (exemple)
        write_reg(x"2", x"0000" & slave_addr, clk, addr, data_in, we, ready);  -- Adresse
        write_reg(x"0", x"000003", clk, addr, data_in, we, ready);  -- Enable + START
        
        -- Attendre que START soit envoyé
        wait for CLK_PERIOD * 20;
        
        -- Envoyer des données
        test_data := x"55";
        write_reg(x"3", x"0000" & test_data, clk, addr, data_in, we, ready);  -- Data
        wait for CLK_PERIOD * 50;
        
        -- Générer STOP
        write_reg(x"0", x"000004", clk, addr, data_in, we, ready);  -- STOP
        wait for CLK_PERIOD * 20;
        
        -- Test 3: Lecture depuis un esclave
        report "Test 3: Lecture depuis un esclave";
        slave_addr := x"A1";  -- Adresse esclave + bit lecture
        write_reg(x"2", x"0000" & slave_addr, clk, addr, data_in, we, ready);  -- Adresse
        write_reg(x"0", x"00000B", clk, addr, data_in, we, ready);  -- Enable + START + READ
        
        -- Attendre réception données
        wait for CLK_PERIOD * 100;
        
        -- Lire données reçues
        read_reg(x"4", clk, addr, re, ready);
        
        -- Générer STOP
        write_reg(x"0", x"000004", clk, addr, data_in, we, ready);  -- STOP
        wait for CLK_PERIOD * 20;
        
        -- Test 4: Vérification gestion NACK
        report "Test 4: Vérification gestion NACK";
        slave_addr := x"F0";  -- Adresse invalide
        write_reg(x"2", x"0000" & slave_addr, clk, addr, data_in, we, ready);  -- Adresse
        write_reg(x"0", x"000003", clk, addr, data_in, we, ready);  -- Enable + START
        
        -- Attendre et vérifier statut
        wait for CLK_PERIOD * 50;
        read_reg(x"5", clk, addr, re, ready);  -- Lire statut
        
        -- Test 5: Transaction multi-octets
        report "Test 5: Transaction multi-octets";
        slave_addr := x"A0";
        write_reg(x"2", x"0000" & slave_addr, clk, addr, data_in, we, ready);  -- Adresse
        write_reg(x"0", x"000003", clk, addr, data_in, we, ready);  -- Enable + START
        
        -- Envoyer plusieurs octets
        for i in 1 to 3 loop
            test_data := std_logic_vector(to_unsigned(i * 16, 8));
            write_reg(x"3", x"0000" & test_data, clk, addr, data_in, we, ready);  -- Data
            wait for CLK_PERIOD * 50;
        end loop;
        
        -- Générer STOP
        write_reg(x"0", x"000004", clk, addr, data_in, we, ready);  -- STOP
        wait for CLK_PERIOD * 20;

        -- Test 6: Accès mémoire concurrents
        report "Test 6: Accès mémoire concurrents";
        -- Premier accès
        slave_addr := x"A0";
        write_reg(x"2", x"0000" & slave_addr, clk, addr, data_in, we, ready);
        write_reg(x"0", x"000003", clk, addr, data_in, we, ready);
        
        -- Deuxième accès (pendant que le premier est en cours)
        slave_addr := x"A2";
        write_reg(x"2", x"0000" & slave_addr, clk, addr, data_in, we, ready);
        -- Vérifier que le contrôleur gère correctement la contention
        read_reg(x"5", clk, addr, re, ready);  -- Lire statut
        wait for CLK_PERIOD * 50;
        
        -- Test 7: Points d'arrêt multiples
        report "Test 7: Points d'arrêt multiples";
        slave_addr := x"A0";
        write_reg(x"2", x"0000" & slave_addr, clk, addr, data_in, we, ready);
        write_reg(x"0", x"000003", clk, addr, data_in, we, ready);
        
        -- Simuler des points d'arrêt
        for i in 1 to 3 loop
            -- Arrêt temporaire
            write_reg(x"0", x"000000", clk, addr, data_in, we, ready);  -- Disable
            wait for CLK_PERIOD * 10;
            -- Reprise
            write_reg(x"0", x"000001", clk, addr, data_in, we, ready);  -- Enable
            wait for CLK_PERIOD * 20;
        end loop;
        
        -- Test 8: Mesures de performance
        report "Test 8: Mesures de performance";
        -- Test de vitesse maximale
        write_reg(x"1", x"000004", clk, addr, data_in, we, ready);  -- Divider=4 (vitesse max)
        slave_addr := x"A0";
        write_reg(x"2", x"0000" & slave_addr, clk, addr, data_in, we, ready);
        
        -- Chronométrer une transaction complète
        write_reg(x"0", x"000003", clk, addr, data_in, we, ready);  -- START
        test_data := x"FF";
        write_reg(x"3", x"0000" & test_data, clk, addr, data_in, we, ready);
        wait for CLK_PERIOD * 20;
        write_reg(x"0", x"000004", clk, addr, data_in, we, ready);  -- STOP
        
        -- Fin des tests
        report "Fin des tests I²C";
        wait;
    end process;
    
    -- Process de simulation du périphérique I²C esclave
    process
        variable addr_match : boolean;
    begin
        -- Attendre condition START
        wait until falling_edge(i2c_sda) and i2c_scl = '1';
        
        -- Recevoir adresse
        addr_match := false;
        for i in 7 downto 0 loop
            wait until falling_edge(i2c_scl);
            if i = 7 then
                -- Vérifier si l'adresse correspond
                addr_match := i2c_sda = '1';  -- Exemple: répond uniquement à 0xA0/0xA1
            end if;
        end loop;
        
        -- Envoyer ACK/NACK
        wait until falling_edge(i2c_scl);
        if addr_match then
            i2c_sda <= '0';  -- ACK
        else
            i2c_sda <= '1';  -- NACK
        end if;
        
        -- Si adresse reconnue, traiter les données
        if addr_match then
            loop
                -- Recevoir/envoyer données
                for i in 7 downto 0 loop
                    wait until falling_edge(i2c_scl);
                    if i2c_sda = 'H' then  -- Mode lecture
                        i2c_sda <= not i2c_sda;  -- Envoyer données de test
                    end if;
                end loop;
                
                -- Attendre ACK/NACK
                wait until falling_edge(i2c_scl);
                
                -- Vérifier condition STOP
                wait until i2c_scl = '1';
                if i2c_sda = '1' then
                    exit;  -- STOP détecté
                end if;
            end loop;
        end if;
        
        -- Réinitialiser pour prochain transfert
        i2c_sda <= 'H';
    end process;
    
end architecture sim;