-- Este modulo resuelve la adquisicion de datos y es modular: no conecta directamente
-- con el hardware externo.
-- Este modulo es el que se conectará con el resto de áreas del proyecto.
-- TOP_LEVEL_ENTITY_ADC hace uso de este módulo para conectar con
-- el hardware de la tarjeta y probarlo.

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity ADQUISICION_DE_DATOS is
    PORT(
            clk_50 : in std_logic;  -- conexion al reloj de 50 Mhz
            switches : in std_logic_vector (9 downto 0);  -- conexiones a los SW()       
            reset_n : in std_logic;   -- conexion a reset (mucho cuidado, debe ser un reset de logica inversa, activo a nivel bajo)
            -- conexiones a los displays (HEX)
            disp0 : out std_logic_vector (7 downto 0);
            disp1 : out std_logic_vector (7 downto 0);
            disp2 : out std_logic_vector (7 downto 0);
            disp3 : out std_logic_vector (7 downto 0);
            disp4 : out std_logic_vector (7 downto 0);
            disp5 : out std_logic_vector (7 downto 0);
            -- salidas de datos para otros modulos
            clk_adc : out std_logic;
            pll_locked_out : out std_logic; -- para mantener sistemas a reset hasta que el pll sea estable
            temp_milivoltios : out std_logic_vector(12 downto 0);
            temp_centesimas_centigrado : out signed(15 downto 0);
            
            bit_signo_temp : out std_logic;
            bcd_decenas_temp : out std_logic_vector(3 downto 0);
            bcd_unidades_temp : out std_logic_vector(3 downto 0);
            bcd_decimas_temp : out std_logic_vector(3 downto 0)
            
    );
END entity;

architecture Behavioral of ADQUISICION_DE_DATOS is

    ------------------------------------------------------------------
    -- DEFINICION DE SEÑALES INTERNAS, TIPOS Y CONSTANTES
    ------------------------------------------------------------------
    constant PLL_C0_FREC : integer := 25E6;
    
    signal ADC_CLK : std_logic;
    
    signal CH1: std_logic_vector(11 downto 0);
    signal ADC_VALID: std_logic;
    
    signal BCD0_mv : std_logic_vector(3 downto 0);
    signal BCD1_mv : std_logic_vector(3 downto 0);
    signal BCD2_mv : std_logic_vector(3 downto 0);
    signal BCD3_mv : std_logic_vector(3 downto 0);
    
    signal BCD0_P : std_logic_vector(3 downto 0);
    signal BCD1_P : std_logic_vector(3 downto 0);
    signal BCD2_P : std_logic_vector(3 downto 0);
    signal BCD3_P : std_logic_vector(3 downto 0);
    
    signal BCD0_cc : std_logic_vector(3 downto 0);
    signal BCD1_cc : std_logic_vector(3 downto 0);
    signal BCD2_cc : std_logic_vector(3 downto 0);
    signal BCD3_cc : std_logic_vector(3 downto 0);
    
    signal DP_H1 : std_logic;
    signal D7SEG_H3 : std_logic_vector (7 downto 0);
    
    signal s_temp_milivoltios : std_logic_vector(12 downto 0);
    signal s_temp_centesimas_centigrado : signed(15 downto 0);
    signal temp_centesimas_absoluta : std_logic_vector(15 downto 0);
    signal temperatura_negativa : std_logic := '0';                                 -- '0' positiva; '1' negativa
    
    signal CH1_PROMEDIADO: std_logic_vector(11 downto 0);
    signal PULSE_4HZ : std_logic := '0';
    
    signal pll_locked : std_logic;
    
    begin
        ------------------------------------------------------------------
        -- MAPEO DE ENTIDADES INTERNAS
        ------------------------------------------------------------------
        
        ADC_DRIVER0 : entity work.ADC_DRIVER
            port map(
                        clk_in => clk_50,
                        pll_c0_clk => ADC_CLK,
                        reset_n => reset_n,
                        ch1_data => CH1,
                        adc_valid => ADC_VALID,
                        pll_locked_out => pll_locked
                        
                        );
                        
        MEDIA_MOVIL0 : entity work.MEDIA_MOVIL 
                            generic map(N_BITS_DATO => 12, 
                                            N_BITS_MUESTRAS => 6,
                                            VENTANA_TIEMPO_MS => 20,
                                            CLK_FREC => PLL_C0_FREC)
                            port map(
                                        CLK => ADC_CLK,
                                        RESET => not reset_n, 
                                        DATO_LISTO => ADC_VALID,
                                        DATO => CH1,
                                        DATO_PROMEDIADO => CH1_PROMEDIADO);
                                        
        GENERADOR_PULSOS_4HZ :  entity work.GENERADOR_PULSOS
                                        generic map(CLK_FREC => PLL_C0_FREC, PULSE_FREC => 4)
                                        port map(
                                                CLK => ADC_CLK,
                                                RESET => not reset_n,
                                                PULSE => PULSE_4HZ
                                                );
                                                
        CONVERSOR_A_mV :    entity work.ADC_A_mV
                                port map(
                                            cuentas_ADC => CH1_PROMEDIADO,
                                            conversion_mv => s_temp_milivoltios
                                            );
                                            
        CONVERSOR_A_cC :    entity work.mV_A_TEMP
                                port map(
                                            mv => s_temp_milivoltios,
                                            conversion_centesimas_gradoC => s_temp_centesimas_centigrado);
                                            
        BIN2BCD_MILIVOLTIOS : entity work.BIN2BCD_9999 generic map(n_bits=>13) port map(s_temp_milivoltios, BCD0_mv, BCD1_mv, BCD2_mv, BCD3_mv);
        BIN2BCD_CENTIGRADOS : entity work.BIN2BCD_9999 generic map(n_bits=>16) port map(temp_centesimas_absoluta, BCD0_cc, BCD1_cc, BCD2_cc, BCD3_cc);

        
        D0 : entity work.DISPLAY generic map(BCD => true) port map (BIN => BCD0_P, D7SEG => disp0, DP => '0');
        D1 : entity work.DISPLAY generic map(BCD => true) port map (BIN => BCD1_P, D7SEG => disp1, DP => DP_H1);
        D2 : entity work.DISPLAY generic map(BCD => true) port map (BIN => BCD2_P, D7SEG => disp2, DP => '0');
        D3 : entity work.DISPLAY generic map(BCD => true) port map (BIN => BCD3_P, D7SEG => D7SEG_H3, DP => '1');
        
        D4 : entity work.DISPLAY generic map(BCD => true) port map (BIN => "0000", D7SEG => disp4, OFF => '1');

        
        ------------------------------------------------------------------
        -- LOGICA COMBINACIONAL ; ASIGNACIONES DIRECTAS
        ------------------------------------------------------------------
        
        temp_centesimas_absoluta <= std_logic_vector(abs(s_temp_centesimas_centigrado));
        
        temperatura_negativa <= s_temp_centesimas_centigrado(15);                                   -- el ultimo bit es el de signo
        
        disp5 <= "01000110" when switches(0) = '0' else "01000001";
        
        with std_logic_vector'(switches(0) & temperatura_negativa) select disp3 <= 
                    "10111111" when "01",                                                       -- modo temperatura y es negativa -> mostrar signo menos
                    "11111111" when "00",                                                       -- modo temperatura y es positiva -> no signo menos, apagar display
                    D7SEG_H3   when others;                                                     -- modo tension -> dejar pasar los millares de milivoltio
        
        
        DP_H1 <= '1' when switches(0) = '0' else '0';                                             -- punto decimal de disp1 ; para mostrar XX.X (grados)       
        
        -- asignacion de salidas del modulo
        temp_milivoltios <= s_temp_milivoltios;
        temp_centesimas_centigrado <= s_temp_centesimas_centigrado;
        
        clk_adc <= ADC_CLK;
        pll_locked_out <= pll_locked;
        
        bit_signo_temp <= temperatura_negativa;
        bcd_decenas_temp <= BCD3_cc;
        bcd_unidades_temp <= BCD2_cc;
        bcd_decimas_temp <= BCD1_cc;
        -- BCD0 son las centesimas, que vamos a ignorar porque
        -- no son signficativas (resolucion termica de 0.1C)
        
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
                
                    if switches(0) = '1' then
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