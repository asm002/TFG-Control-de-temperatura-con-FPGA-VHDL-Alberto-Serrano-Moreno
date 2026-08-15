-- Este modulo tan solo instancia ADQUISICION_DE_DATOS para conectarlo con los periféricos de la tarjeta y así probar dicho modulo.

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

use work.CONFIG_PROYECTO.all;

entity TOP_LEVEL_ENTITY_ADC is
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

architecture Behavioral of TOP_LEVEL_ENTITY_ADC is

    ------------------------------------------------------------------
    -- DEFINICION DE SEÑALES INTERNAS, TIPOS Y CONSTANTES
    ------------------------------------------------------------------
    signal clk_adc : std_logic;

    signal bus_temperatura : t_bus_temperatura;
    signal pll_locked, reset_and_pll_n : std_logic;

    signal KEY_pulsos : std_logic_vector(1 downto 0);
    signal SW_sync : std_logic_vector(9 downto 0);
    signal avanzar, retroceder, ajustar : std_logic;

    signal pulso4hz : std_logic;

    -- GESTION DE DISPLAYS --
    constant N_PANTALLAS : integer := 2;
    signal contador_pantallas : integer range 0 to N_PANTALLAS-1;

    signal info_displays_mv : t_bus_info_displays;
    signal info_displays_celsius : t_bus_info_displays;
    signal info_displays_activa : t_bus_info_displays;
    signal id : std_logic_vector(3 downto 0);   -- se le asigna el valor del contador

    signal bus_t_disp : t_bus_temperatura;

    signal array_displays_out : t_displays_7seg;
    
    begin
        ------------------------------------------------------------------
        -- MAPEO DE ENTIDADES INTERNAS
        ------------------------------------------------------------------
        ADQUISICION_DE_DATOS0 : entity work.ADQUISICION_DE_DATOS
            port map (
                clk_50 => MAX10_CLK1_50,
                reset_n => ARDUINO_RESET_N,

                clk_adc => clk_adc,
                pll_locked_out => pll_locked,
                bus_temperatura => bus_temperatura
            );

        GESTION_DISPLAYS0 : entity work.GESTION_DISPLAYS
            generic map (
                N_BITS_VALOR_ABSOLUTO => N_BITS_CELSIUS
            )
            port map (
                valor_absoluto => info_displays_activa.valor_absoluto,
                es_negativo => info_displays_activa.es_negativo,
                id => info_displays_activa.id,
                array_puntos_decimales => info_displays_activa.array_puntos_decimales,
                displays_hex_out => array_displays_out
            );
        
        CAPTURA_PULSADORES0 : entity work.CAPTURA_PULSADORES
            generic map (
                N_PULSADORES => 2
            )
            port map (
                clk => clk_adc,
                reset => not reset_and_pll_n,

                pulsadores => not KEY,
                pulsos => KEY_pulsos
            );

        SINCRONIZADOR_ENTRADAS_SW : entity work.SINCRONIZADOR_ENTRADAS
            generic map (
                N_ENTRADAS => 10
            )
            port map (
                clk => clk_adc,
                reset => not reset_and_pll_n,

                entradas => SW,
                entradas_sincronizadas => SW_sync
            );

        GENERADOR_PULSOS0 : entity work.GENERADOR_PULSOS
            generic map (
                CLK_FREC => PLL_C0_FREC,
                PULSE_FREC => 4
            )
            port map (
                CLK => clk_adc,
                RESET => not reset_and_pll_n,
                PULSE => pulso4hz
            );



        ------------------------------------------------------------------
        -- LOGICA COMBINACIONAL ; ASIGNACIONES DIRECTAS
        ------------------------------------------------------------------
        reset_and_pll_n <= ARDUINO_RESET_N and pll_locked;  -- reset de boton y ademas condicionado a que el pll
                                                            -- esté listo. Activo a nivel bajo
        avanzar <= KEY_pulsos(0);
        retroceder <= KEY_pulsos(1);
        -- se usará cuando haya registros modificables directamente en la FPGA (PWM manual por ejemplo)
        ajustar <= SW_sync(0);

        -- GESTION DISPLAYS
        id <= std_logic_vector(to_unsigned(contador_pantallas, 4));

        info_displays_celsius.valor_absoluto <= std_logic_vector(abs(bus_t_disp.centesimas_celsius));
        info_displays_celsius.es_negativo <= bus_temperatura.centesimas_celsius(N_BITS_CELSIUS-1) = '1';
        info_displays_celsius.id <= id;
        info_displays_celsius.array_puntos_decimales <= "0100";

        info_displays_mv.valor_absoluto <= std_logic_vector(resize(unsigned(bus_t_disp.milivoltios), 16));
        info_displays_mv.es_negativo <= false;
        info_displays_mv.id <= id;
        info_displays_mv.array_puntos_decimales <= "1000";

        HEX0 <= array_displays_out(0);
        HEX1 <= array_displays_out(1);
        HEX2 <= array_displays_out(2);
        HEX3 <= array_displays_out(3);
        HEX4 <= array_displays_out(4);
        HEX5 <= array_displays_out(5);

        with contador_pantallas select info_displays_activa <= 
            info_displays_celsius when 0,
            info_displays_mv      when 1,
            info_displays_celsius when others;

        
        ------------------------------------------------------------------
        -- LOGICA SECUENCIAL ; PROCESOS
        ------------------------------------------------------------------
        process(clk_adc)
        ------------------------------------------------------------------
        -- DEFINICION DE VARIABLES, TIPOS Y CONSTANTES
        ------------------------------------------------------------------
            
            begin           
                if rising_edge(clk_adc) then
                    if reset_and_pll_n = '0' then
                        contador_pantallas <= 0;
                    else
                        if avanzar = '1' then
                            if contador_pantallas = N_PANTALLAS - 1 then
                                contador_pantallas <= 0;
                            else
                                contador_pantallas <= contador_pantallas + 1;
                            end if;

                        elsif retroceder = '1' then
                            if contador_pantallas = 0 then
                                contador_pantallas <= N_PANTALLAS - 1;
                            else
                                contador_pantallas <= contador_pantallas - 1;
                            end if;
                        end if;
                    end if;
                end if;
        end process;

        process(clk_adc)
        ------------------------------------------------------------------
        -- DEFINICION DE VARIABLES, TIPOS Y CONSTANTES
        ------------------------------------------------------------------
            
            begin           
                if rising_edge(clk_adc) then
                    if reset_and_pll_n = '0' then
                        bus_t_disp.milivoltios <= (others => '0');
                        bus_t_disp.centesimas_celsius <= (others => '0');
                    else
                        if pulso4hz = '1' then
                            bus_t_disp <= bus_temperatura;
                        end if;
                    end if;
                end if;
        end process;
        
        
end architecture;