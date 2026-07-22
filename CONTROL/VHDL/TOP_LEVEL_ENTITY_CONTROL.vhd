

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

use work.CONFIG_PROYECTO.all;

entity TOP_LEVEL_ENTITY_CONTROL is
    PORT(
            MAX10_CLK1_50 : in std_logic;
            ADC_CLK_10 : in std_logic;
            SW : in std_logic_vector (9 downto 0);
            KEY : in std_logic_vector (1 downto 0);
            LEDR : out std_logic_vector (9 downto 0) := (others=>'0');          
            ARDUINO_RESET_N : in std_logic;
            ARDUINO_IO : inout std_logic_vector (15 downto 0);
            HEX0 : out std_logic_vector (7 downto 0);
            HEX1 : out std_logic_vector (7 downto 0);
            HEX2 : out std_logic_vector (7 downto 0);
            HEX3 : out std_logic_vector (7 downto 0);
            HEX4 : out std_logic_vector (7 downto 0);
            HEX5 : out std_logic_vector (7 downto 0)
    );
END entity;

architecture Behavioral of TOP_LEVEL_ENTITY_CONTROL is
    ------------------------------------------------------------------
    -- DEFINICION DE SEÑALES INTERNAS, TIPOS Y CONSTANTES
    ------------------------------------------------------------------

    -- PWM --
    signal salida_digital_pwm : std_logic := '0';
    signal pulso_200hz : std_logic := '0';  -- para ajustar el PWM manualmente
    signal contador_pwm_manual : UNSIGNED(N_BITS_PWM-1 downto 0) := (others => '0');   -- 0 a 1023
    

    -- ADQUISICION --
    signal clk_adc : std_logic; -- 25 MHz
    signal pll_locked : std_logic;
    signal reset_and_pll_n : std_logic;
    signal bus_temperatura : t_bus_temperatura;


    -- GESTION DE DISPLAYS
    type MODOS_DISPLAYS is (PWM, TEMP_CELSIUS, TEMP_MV);
    signal modo_displays : MODOS_DISPLAYS := TEMP_CELSIUS;

    signal info_displays_pwm : t_bus_info_displays;
    signal info_displays_celsius : t_bus_info_displays;
    signal info_displays_mv : t_bus_info_displays;
    signal info_displays_activa : t_bus_info_displays;

    signal array_displays_out : t_displays_7seg;
    
    begin
        ------------------------------------------------------------------
        -- MAPEO DE ENTIDADES INTERNAS
        ------------------------------------------------------------------
        PWM0 : entity work.PWM
            generic map (
                CLK_FREC => PLL_C0_FREC,
                PWM_FREC => FREC_PWM,
                N_BITS => N_BITS_PWM
            )
            port map (
                clk => clk_adc,
                reset_n => reset_and_pll_n,
                t_on => std_logic_vector(contador_pwm_manual),
                pwm_out => salida_digital_pwm
            );

        GENERADOR_PULSOS_inst : entity work.GENERADOR_PULSOS
            generic map (
                CLK_FREC => PLL_C0_FREC,
                PULSE_FREC => 205
            )
            port map (
                CLK => clk_adc,
                RESET => not reset_and_pll_n,
                PULSE => pulso_200hz
            );

        ADQUISICION_DE_DATOS_inst : entity work.ADQUISICION_DE_DATOS
            port map (
                clk_50 => MAX10_CLK1_50,
                reset_n => ARDUINO_RESET_N,

                modo_displays => '0',  -- se puede eliminar...

                clk_adc => clk_adc,
                pll_locked_out => pll_locked,

                bus_temperatura => bus_temperatura,

                -- se puede eliminar, el modulo ya no necesita gestionar señales de displays internamente
                -- porque lo hacemos desde top. 
                -- Eso si, habria que modificar TOP_LEVEL_ENTITY_ADC y _COM porque dejaria de funcionar
                displays_out => open
            );

        GESTION_DISPLAYS_inst : entity work.GESTION_DISPLAYS
            generic map(
                N_BITS_VALOR_ABSOLUTO => 16
            )
            port map (
                valor_absoluto => info_displays_activa.valor_absoluto,
                es_negativo => info_displays_activa.es_negativo,
                id => info_displays_activa.id,
                array_puntos_decimales => info_displays_activa.array_puntos_decimales,
                displays_hex_out => array_displays_out
            );


        ------------------------------------------------------------------
        -- LOGICA COMBINACIONAL ; ASIGNACIONES DIRECTAS
        ------------------------------------------------------------------
        reset_and_pll_n <= ARDUINO_RESET_N and pll_locked;  -- reset de boton y ademas condicionado a que el pll
                                                            -- esté listo. Activo a nivel bajo
        
        ARDUINO_IO(PIN_PWM) <= not salida_digital_pwm;  -- señal negada porque la etapa de potencia
                                                        -- tiene señal de control activa a nivel bajo
        LEDR(8) <= '1'; -- led al maximo como referencia
        LEDR(9) <= salida_digital_pwm;  -- led regulado por el mismo pwm

        with SW(1 downto 0) select
            modo_displays <= PWM          when "01",
                             PWM          when "11",
                             TEMP_CELSIUS when "00",
                             TEMP_MV      when "10";

        with modo_displays select
            info_displays_activa <= info_displays_pwm when PWM,
                                    info_displays_celsius when TEMP_CELSIUS,
                                    info_displays_mv when others;
        
        info_displays_pwm.valor_absoluto <= std_logic_vector(resize(contador_pwm_manual, 16));
        info_displays_pwm.es_negativo <= false;
        info_displays_pwm.id <= x"0";
        info_displays_pwm.array_puntos_decimales <= "0000";

        info_displays_celsius.valor_absoluto <= std_logic_vector(abs(bus_temperatura.centesimas_centigrado));
        info_displays_celsius.es_negativo <= (bus_temperatura.bit_signo = '1');
        info_displays_celsius.id <= x"1";
        info_displays_celsius.array_puntos_decimales <= "0100";

        info_displays_mv.valor_absoluto <= std_logic_vector(resize(unsigned(bus_temperatura.milivoltios), 16));
        info_displays_mv.es_negativo <= false;
        info_displays_mv.id <= x"2";
        info_displays_mv.array_puntos_decimales <= "1000";

        HEX0 <= array_displays_out(0);
        HEX1 <= array_displays_out(1);
        HEX2 <= array_displays_out(2);
        HEX3 <= array_displays_out(3);
        HEX4 <= array_displays_out(4);
        HEX5 <= array_displays_out(5);


        ------------------------------------------------------------------
        -- LOGICA SECUENCIAL ; PROCESOS
        ------------------------------------------------------------------
        process(clk_adc)
        ------------------------------------------------------------------
        -- DEFINICION DE VARIABLES, TIPOS Y CONSTANTES
        ------------------------------------------------------------------
            
            begin           
                if rising_edge(clk_adc) then
                    if not reset_and_pll_n = '1' then
                        contador_pwm_manual <= (others => '0'); 
                    else
                        if pulso_200hz = '1' then
                            if not KEY(0) = '1' and contador_pwm_manual < 1023 then
                                contador_pwm_manual <= contador_pwm_manual + 1;
                            elsif not KEY(1) = '1' and contador_pwm_manual > 0 then
                                contador_pwm_manual <= contador_pwm_manual - 1;
                            end if;
                        end if;
                    end if;
                end if;
        end process;

    
        
end architecture;