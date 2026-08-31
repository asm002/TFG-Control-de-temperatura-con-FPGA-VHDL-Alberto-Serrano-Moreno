library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

use work.CONFIG_PROYECTO.all;

--  Formato completo de mensajes:
--  DATA <CONSIGNA.00> <TEMPERATURA.00> <ERROR.00> <PWM>

entity MENSAJE_TX is
    port(
        indice : in integer range 0 to MSG_N_BYTES_TX-1;
        byte_out : out std_logic_vector(7 downto 0);
        
        bus_datos_graficos : in t_bus_datos_graficos_tx
        
    );
end entity;

architecture Behavioral of MENSAJE_TX is
    ------------------------------------------------------------------
    -- DEFINICION DE SEÑALES INTERNAS, TIPOS Y CONSTANTES
    ------------------------------------------------------------------
    signal ascii_signo_temp : std_logic_vector(7 downto 0);
    signal ascii_signo_consigna : std_logic_vector(7 downto 0);
    signal ascii_signo_error : std_logic_vector(7 downto 0);

    signal bus_bcd_consigna : t_bus_bcd;
    signal bus_bcd_temperatura : t_bus_bcd;
    signal bus_bcd_error : t_bus_bcd;
    signal bus_bcd_pwm : t_bus_bcd;

    signal bus_temperatura : t_bus_temperatura;
    
    begin
        ------------------------------------------------------------------
        -- MAPEO DE ENTIDADES INTERNAS
        ------------------------------------------------------------------
        BCD_CONSIGNA : entity work.BIN2BCD_9999
            generic map (
                n_bits => N_BITS_CELSIUS
            )
            port map (
                BIN => std_logic_vector(abs(bus_datos_graficos.consigna)),
                BCD0 => bus_bcd_consigna.bcd0,
                BCD1 => bus_bcd_consigna.bcd1,
                BCD2 => bus_bcd_consigna.bcd2,
                BCD3 => bus_bcd_consigna.bcd3
            );

        BCD_TEMPERATURA : entity work.BIN2BCD_9999
            generic map (
                n_bits => N_BITS_CELSIUS
            )
            port map (
                BIN => std_logic_vector(abs(bus_datos_graficos.bus_temperatura.centesimas_celsius)),
                BCD0 => bus_bcd_temperatura.bcd0,
                BCD1 => bus_bcd_temperatura.bcd1,
                BCD2 => bus_bcd_temperatura.bcd2,
                BCD3 => bus_bcd_temperatura.bcd3
            );

        BCD_ERROR : entity work.BIN2BCD_9999
            generic map (
                n_bits => N_BITS_CELSIUS
            )
            port map (
                BIN => std_logic_vector(abs(bus_datos_graficos.error)),
                BCD0 => bus_bcd_error.bcd0,
                BCD1 => bus_bcd_error.bcd1,
                BCD2 => bus_bcd_error.bcd2,
                BCD3 => bus_bcd_error.bcd3
            );
        
        BCD_PWM : entity work.BIN2BCD_9999
            generic map (
                n_bits => N_BITS_PWM
            )
            port map (
                BIN  => bus_datos_graficos.pwm,
                BCD0 => bus_bcd_pwm.bcd0,
                BCD1 => bus_bcd_pwm.bcd1,
                BCD2 => bus_bcd_pwm.bcd2,
                BCD3 => bus_bcd_pwm.bcd3
            );

        
        ------------------------------------------------------------------
        -- LOGICA COMBINACIONAL ; ASIGNACIONES DIRECTAS
        ------------------------------------------------------------------

        bus_temperatura <= bus_datos_graficos.bus_temperatura;

        -- signo menos (0x2D) o signo más (0x2B) en ASCII
        ascii_signo_temp <= x"2D" when bus_temperatura.centesimas_celsius(N_BITS_CELSIUS-1) = '1' else x"2B";
        ascii_signo_consigna <= x"2D" when bus_datos_graficos.consigna(N_BITS_CELSIUS-1) = '1' else x"2B";
        ascii_signo_error <= x"2D" when bus_datos_graficos.error(N_BITS_CELSIUS-1) = '1' else x"2B";

        with indice select byte_out <=
            -- "DATA "
            x"44" when 0,  -- 'D'
            x"41" when 1,  -- 'A'
            x"54" when 2,  -- 'T'
            x"41" when 3,  -- 'A'
            x"20" when 4,  -- Espacio ' '
            
            -- <CONSIGNA.0> <+99.99 > -99.99 a +99.99
            ascii_signo_consigna            when 5,
            x"3" & bus_bcd_consigna.bcd3    when 6,
            x"3" & bus_bcd_consigna.bcd2    when 7,
            x"2E"                           when 8,   -- punto
            x"3" & bus_bcd_consigna.bcd1    when 9,
            x"3" & bus_bcd_consigna.bcd0    when 10,
            x"20"                           when 11,  -- espacio
            
            -- <TEMPERATURA.0> <+99.99 > -99.99 a +99.99
            ascii_signo_temp                        when 12,  -- signo de la temperatura
            x"3" & bus_bcd_temperatura.bcd3         when 13,
            x"3" & bus_bcd_temperatura.bcd2         when 14,
            x"2E"                                   when 15,  -- punto (decimal)
            x"3" & bus_bcd_temperatura.bcd1         when 16,
            x"3" & bus_bcd_temperatura.bcd0         when 17,
            x"20"                                   when 18,  -- espacio
            
            -- <ERROR.0> <+99.99 > -99.99 a +99.99 
            -- Saturamos en +-99.99 aunque teoricamente, por la consigna,
            -- podria tomar el rango -199.8 a +199.8 (en la practica nunca vamos a tener ese error tan grande
            -- y asi nos ahorramos un bcd4)
            ascii_signo_error           when 19,   -- +
            x"3" & bus_bcd_error.bcd3   when 20,   -- 9
            x"3" & bus_bcd_error.bcd2   when 21,   -- 9
            x"2E"                       when 22,   -- punto
            x"3" & bus_bcd_error.bcd1   when 23,   -- 9
            x"3" & bus_bcd_error.bcd0   when 24,   -- 9
            x"20"                       when 25,  -- espacio
            
            -- <PWM> <1023\n> 0000 a 1023
            x"3" & bus_bcd_pwm.bcd3 when 26,  -- 1
            x"3" & bus_bcd_pwm.bcd2 when 27,  -- 0
            x"3" & bus_bcd_pwm.bcd1 when 28,  -- 2
            x"3" & bus_bcd_pwm.bcd0 when 29,  -- 3
            x"0A" when 30,  -- salto de linea (LF)
            
            x"21" when others;  -- signo de exclamacion
        
        
        
end architecture;