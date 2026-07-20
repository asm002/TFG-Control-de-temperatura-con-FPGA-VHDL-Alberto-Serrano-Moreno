-- Este modulo tan solo instancia PWM 
-- para conectarlo con los periféricos de la tarjeta y así probar dicho modulo.

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

use work.CONFIG_PROYECTO.all;

entity TOP_LEVEL_ENTITY_PWM is
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

architecture Behavioral of TOP_LEVEL_ENTITY_PWM is
    ------------------------------------------------------------------
    -- DEFINICION DE SEÑALES INTERNAS, TIPOS Y CONSTANTES
    ------------------------------------------------------------------
    signal pwm : std_logic := '0';

    signal pulso_200hz : std_logic := '0';
    signal contador_pwm_manual : UNSIGNED(N_BITS_PWM-1 downto 0) := (others => '0');   -- 0 a 1023

    signal pwm_bcd : t_bus_bcd;
    
    
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
                reset_n => ARDUINO_RESET_N,
                t_on => std_logic_vector(contador_pwm_manual),
                pwm_out => pwm
            );

        GENERADOR_PULSOS_inst : entity work.GENERADOR_PULSOS
            generic map (
                CLK_FREC => 50E6,
                PULSE_FREC => 205
            )
            port map (
                CLK => MAX10_CLK1_50,
                RESET => not ARDUINO_RESET_N,
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
            generic map (BCD => true) port map (pwm_bcd.bcd0, HEX0);

        D1 : entity work.DISPLAY
            generic map (BCD => true) port map (pwm_bcd.bcd1, HEX1);

        D2 : entity work.DISPLAY
            generic map (BCD => true) port map (pwm_bcd.bcd2, HEX2);

        D3 : entity work.DISPLAY
            generic map (BCD => true) port map (pwm_bcd.bcd3, HEX3);

        ------------------------------------------------------------------
        -- LOGICA COMBINACIONAL ; ASIGNACIONES DIRECTAS
        ------------------------------------------------------------------
        ARDUINO_IO(15) <= not pwm;  -- señal negada porque la etapa de potencia
                                    -- tiene señal de control activa a nivel bajo
        ARDUINO_IO(14) <= '1';
        LEDR(8) <= '1';
        LEDR(9) <= pwm;

        HEX4 <= (others => '1');
        HEX5 <= (others => '1');

        ------------------------------------------------------------------
        -- LOGICA SECUENCIAL ; PROCESOS
        ------------------------------------------------------------------
        process(MAX10_CLK1_50)
        ------------------------------------------------------------------
        -- DEFINICION DE VARIABLES, TIPOS Y CONSTANTES
        ------------------------------------------------------------------
            
            begin           
                if rising_edge(MAX10_CLK1_50) then
                    if not ARDUINO_RESET_N = '1' then

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