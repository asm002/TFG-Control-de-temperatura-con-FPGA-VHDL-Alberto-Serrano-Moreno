library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity ADC_TOP is
    PORT(
            MAX10_CLK1_50 : in STD_LOGIC;
            ADC_CLK_10 : in STD_LOGIC;
            SW : in STD_LOGIC_VECTOR (9 downto 0);
            KEY : in STD_LOGIC_VECTOR (1 downto 0);
            LEDR : out STD_LOGIC_VECTOR (9 downto 0) := (others=>'0');          
            ARDUINO_RESET_N : in STD_LOGIC;
            ARDUINO_IO : inout STD_LOGIC_VECTOR (15 downto 0);
            HEX0 : out STD_LOGIC_VECTOR (7 downto 0);
            HEX1 : out STD_LOGIC_VECTOR (7 downto 0);
            HEX2 : out STD_LOGIC_VECTOR (7 downto 0);
            HEX3 : out STD_LOGIC_VECTOR (7 downto 0);
            HEX4 : out STD_LOGIC_VECTOR (7 downto 0);
            HEX5 : out STD_LOGIC_VECTOR (7 downto 0)
    );
END entity;

architecture Behavioral of ADC_TOP is

    ------------------------------------------------------------------
    -- DEFINICION DE SEÑALES INTERNAS, TIPOS Y CONSTANTES
    ------------------------------------------------------------------
    
    signal ADC_CLK : std_logic;
    
    signal CH1: std_LOGIC_VECTOR(11 downto 0);
    signal ADC_VALID: std_LOGIC;
    
    signal BCD0_mv : STD_LOGIC_VECTOR(3 downto 0);
    signal BCD1_mv : STD_LOGIC_VECTOR(3 downto 0);
    signal BCD2_mv : STD_LOGIC_VECTOR(3 downto 0);
    signal BCD3_mv : STD_LOGIC_VECTOR(3 downto 0);
    
    signal BCD0_P : STD_LOGIC_VECTOR(3 downto 0);
    signal BCD1_P : STD_LOGIC_VECTOR(3 downto 0);
    signal BCD2_P : STD_LOGIC_VECTOR(3 downto 0);
    signal BCD3_P : STD_LOGIC_VECTOR(3 downto 0);
    
    signal BCD0_cc : STD_LOGIC_VECTOR(3 downto 0);
    signal BCD1_cc : STD_LOGIC_VECTOR(3 downto 0);
    signal BCD2_cc : STD_LOGIC_VECTOR(3 downto 0);
    signal BCD3_cc : STD_LOGIC_VECTOR(3 downto 0);
    
    signal DP_H1 : std_logic;
    signal D7SEG_H3 : STD_LOGIC_VECTOR (7 downto 0);
    
    signal TEMP_MILIVOLTIOS : STD_LOGIC_VECTOR(12 downto 0);
    signal TEMP_CENTIGRADOS : signed(15 downto 0);
    signal TEMP_CENTIGRADOS_ABSOLUTA : std_LOGIC_VECTOR(15 downto 0);
    signal temperatura_negativa : std_logic := '0';                                 -- '0' positiva; '1' negativa
    
    signal CH1_PROMEDIADO: std_LOGIC_VECTOR(11 downto 0);
    signal PULSE_4HZ : std_logic := '0';
    
    begin
        ------------------------------------------------------------------
        -- MAPEO DE ENTIDADES INTERNAS
        ------------------------------------------------------------------
        
        ADC_DRIVER0 : entity work.ADC_DRIVER
            port map(
                        clk_in => MAX10_CLK1_50,
                        clk_out => ADC_CLK,
                        reset => ARDUINO_RESET_N,
                        ch1_data => CH1,
                        adc_valid => ADC_VALID
                        );
                        
        MEDIA_MOVIL0 : entity work.MEDIA_MOVIL 
                            generic map(N_BITS_DATO => 12, 
                                            N_BITS_MUESTRAS => 6,
                                            VENTANA_TIEMPO_MS => 20,
                                            CLK_FREC => 10E6)
                            port map(
                                        CLK => ADC_CLK,
                                        DATO_LISTO => ADC_VALID,
                                        DATO => CH1,
                                        DATO_PROMEDIADO => CH1_PROMEDIADO);
                                        
        GENERADOR_PULSOS_4HZ :  entity work.GENERADOR_PULSOS
                                        generic map(CLK_FREC => 10E6, PULSE_FREC => 4)
                                        port map(
                                                CLK => ADC_CLK,
                                                PULSE => PULSE_4HZ
                                                );
                                                
        CONVERSOR_A_mV :    entity work.ADC_A_mV
                                port map(
                                            cuentas_ADC => CH1_PROMEDIADO,
                                            conversion_mv => TEMP_MILIVOLTIOS
                                            );
                                            
        CONVERSOR_A_cC :    entity work.mV_A_TEMP
                                port map(
                                            mv => TEMP_MILIVOLTIOS,
                                            conversion_centesimas_gradoC => TEMP_CENTIGRADOS);
                                            
        BIN2BCD_MILIVOLTIOS : entity work.BIN2BCD_9999 generic map(n_bits=>13) port map(TEMP_MILIVOLTIOS, BCD0_mv, BCD1_mv, BCD2_mv, BCD3_mv);
        BIN2BCD_CENTIGRADOS : entity work.BIN2BCD_9999 generic map(n_bits=>16) port map(TEMP_CENTIGRADOS_ABSOLUTA, BCD0_cc, BCD1_cc, BCD2_cc, BCD3_cc);

        
        D0 : entity work.DISPLAY generic map(BCD => true) port map (BIN => BCD0_P, D7SEG => HEX0, DP => '0');
        D1 : entity work.DISPLAY generic map(BCD => true) port map (BIN => BCD1_P, D7SEG => HEX1, DP => DP_H1);
        D2 : entity work.DISPLAY generic map(BCD => true) port map (BIN => BCD2_P, D7SEG => HEX2, DP => '0');
        D3 : entity work.DISPLAY generic map(BCD => true) port map (BIN => BCD3_P, D7SEG => D7SEG_H3, DP => '1');
        
        D4 : entity work.DISPLAY generic map(BCD => true) port map (BIN => "0000", D7SEG => HEX4, OFF => '1');

        
        ------------------------------------------------------------------
        -- LOGICA COMBINACIONAL ; ASIGNACIONES DIRECTAS
        ------------------------------------------------------------------
        
        TEMP_CENTIGRADOS_ABSOLUTA <= std_LOGIC_VECTOR(abs(TEMP_CENTIGRADOS));
        
        temperatura_negativa <= TEMP_CENTIGRADOS(15);                                   -- el ultimo bit es el de signo
        
        HEX5 <= "01000110" when SW(0) = '0' else "01000001";
        
        with std_logic_vector'(SW(0) & temperatura_negativa) select HEX3 <= 
                    "10111111" when "01",                                                       -- modo temperatura y es negativa -> mostrar signo menos
                    "11111111" when "00",                                                       -- modo temperatura y es positiva -> no signo menos, apagar display
                    D7SEG_H3   when others;                                                     -- modo tension -> dejar pasar los millares de milivoltio
        
        
        DP_H1 <= '1' when SW(0) = '0' else '0';                                             -- punto decimal de HEX1 ; para mostrar XX.X (grados)       
        
        ------------------------------------------------------------------
        -- LOGICA SECUENCIAL ; PROCESOS
        ------------------------------------------------------------------
        
        process(ADC_CLK)
            ------------------------------------------------------------------
            -- DEFINICION DE VARIABLES, TIPOS Y CONSTANTES
            ------------------------------------------------------------------
            
            begin           
                if rising_edge(ADC_CLK) then
                    
                if PULSE_4HZ = '1' then
                
                    if SW(0) = '1' then
                            -- MODO MILIVOLTIOS
                            BCD0_P <= BCD0_mv;
                            BCD1_P <= BCD1_mv;
                            BCD2_P <= BCD2_mv;
                            BCD3_P <= BCD3_mv;
                        else
                            -- MODO TEMPERATURA
                            BCD0_P <= BCD1_cc;
                            BCD1_P <= BCD2_cc;
                            BCD2_P <= BCD3_cc;
                            BCD3_P <= "0000";
                        end if;
                    
                end if;
                
                end if;
        end process;
        
end architecture;