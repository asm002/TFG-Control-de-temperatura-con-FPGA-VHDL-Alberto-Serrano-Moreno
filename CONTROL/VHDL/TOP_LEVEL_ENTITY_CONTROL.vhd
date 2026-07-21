

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
    signal pulso_200hz : std_logic := '0';
    signal contador_pwm_manual : UNSIGNED(N_BITS_PWM-1 downto 0) := (others => '0');   -- 0 a 1023
    signal pwm_bcd : t_bus_bcd;
    signal array_displays_pwm : t_displays_7seg;
    
    -- ADQUISICION --
    signal clk_adc : std_logic; -- 25 MHz
    signal pll_locked : std_logic;
    signal reset_and_pll_n : std_logic;
    signal bus_temperatura : t_bus_temperatura;
    signal array_displays_temp : t_displays_7seg;

    signal array_displays_out : t_displays_7seg;
    signal displays_temp_or_pwm : std_logic := '0';
    signal displays_cent_or_mv : std_logic := '0';
    
    begin
        ------------------------------------------------------------------
        -- MAPEO DE ENTIDADES INTERNAS
        ------------------------------------------------------------------
        PWM0 : entity work.PWM
            generic map (
                CLK_FREC => 50E6,
                PWM_FREC => FREC_PWM,
                N_BITS => N_BITS_PWM
            )
            port map (
                clk => MAX10_CLK1_50,
                reset_n => reset_and_pll_n,
                t_on => std_logic_vector(contador_pwm_manual),
                pwm_out => salida_digital_pwm
            );

        GENERADOR_PULSOS_inst : entity work.GENERADOR_PULSOS
            generic map (
                CLK_FREC => 50E6,
                PULSE_FREC => 205
            )
            port map (
                CLK => MAX10_CLK1_50,
                RESET => not reset_and_pll_n,
                PULSE => pulso_200hz
            );

        BIN2BCD_9999_inst : entity work.BIN2BCD_9999
            generic map (
                n_bits => N_BITS_PWM
            )
            port map (
                BIN => std_logic_vector(contador_pwm_manual),
                BCD0 => pwm_bcd.bcd0,
                BCD1 => pwm_bcd.bcd1,
                BCD2 => pwm_bcd.bcd2,
                BCD3 => pwm_bcd.bcd3
            );
        
        D0 : entity work.DISPLAY
            generic map (BCD => true) port map (pwm_bcd.bcd0, array_displays_pwm(0));

        D1 : entity work.DISPLAY
            generic map (BCD => true) port map (pwm_bcd.bcd1, array_displays_pwm(1));

        D2 : entity work.DISPLAY
            generic map (BCD => true) port map (pwm_bcd.bcd2, array_displays_pwm(2));

        D3 : entity work.DISPLAY
            generic map (BCD => true) port map (pwm_bcd.bcd3, array_displays_pwm(3));

        ADQUISICION_DE_DATOS_inst : entity work.ADQUISICION_DE_DATOS
            port map (
                clk_50 => MAX10_CLK1_50,
                reset_n => ARDUINO_RESET_N,

                modo_displays => displays_cent_or_mv,

                clk_adc => clk_adc,
                pll_locked_out => pll_locked,

                bus_temperatura => bus_temperatura,
                displays_out => array_displays_temp
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

        array_displays_pwm(4) <= (others => '1');
        array_displays_pwm(5) <= (others => '1');

        displays_temp_or_pwm <= SW(0);
        displays_cent_or_mv <= SW(1);

        array_displays_out <= array_displays_temp when displays_temp_or_pwm = '0' else array_displays_pwm;
        HEX0 <= array_displays_out(0);
        HEX1 <= array_displays_out(1);
        HEX2 <= array_displays_out(2);
        HEX3 <= array_displays_out(3);
        HEX4 <= array_displays_out(4);
        HEX5 <= array_displays_out(5);


        ------------------------------------------------------------------
        -- LOGICA SECUENCIAL ; PROCESOS
        ------------------------------------------------------------------
        process(MAX10_CLK1_50)
        ------------------------------------------------------------------
        -- DEFINICION DE VARIABLES, TIPOS Y CONSTANTES
        ------------------------------------------------------------------
            
            begin           
                if rising_edge(MAX10_CLK1_50) then
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