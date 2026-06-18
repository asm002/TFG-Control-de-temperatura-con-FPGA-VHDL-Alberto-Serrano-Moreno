library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

use work.CONFIG_PROYECTO.all;

--  Formato completo de mensajes:
--  DATA <CONSIGNA.0> <TEMPERATURA.0> <ERROR.0> <PWM>

entity MENSAJE_TX is
    port(
        indice : in integer range 0 to MSG_N_BYTES_TX-1;
        byte_out : out std_logic_vector(7 downto 0);
        
        -- TEMPERATURA (aprovechamos los convertidores BCD de la adquisicion)
        bus_temperatura : in t_bus_temperatura;
        -- CONTROL
        bus_control : in t_bus_control
        
    );
end entity;

architecture Behavioral of MENSAJE_TX is
    ------------------------------------------------------------------
    -- DEFINICION DE SEÑALES INTERNAS, TIPOS Y CONSTANTES
    ------------------------------------------------------------------
    signal ascii_signo_temp : std_logic_vector(7 downto 0);
    signal ascii_signo_consigna : std_logic_vector(7 downto 0);

    signal consigna_bcd_decenas : std_logic_vector(3 downto 0);
    signal consigna_bcd_unidades : std_logic_vector(3 downto 0);
    signal consigna_bcd_decimas : std_logic_vector(3 downto 0);
    signal consigna_bcd_centesimas : std_logic_vector(3 downto 0);
    
    begin
        ------------------------------------------------------------------
        -- MAPEO DE ENTIDADES INTERNAS
        ------------------------------------------------------------------
        BCD_CONSIGNA0 : entity work.BIN2BCD_9999
            generic map (
                n_bits => 16
            )
            port map (
                BIN => std_logic_vector(abs(bus_control.consigna)),
                BCD0 => consigna_bcd_centesimas,
                BCD1 => consigna_bcd_decimas,
                BCD2 => consigna_bcd_unidades,
                BCD3 => consigna_bcd_decenas
            );

        
        ------------------------------------------------------------------
        -- LOGICA COMBINACIONAL ; ASIGNACIONES DIRECTAS
        ------------------------------------------------------------------

        -- signo menos (0x2D) o signo más (0x2B) en ASCII
        ascii_signo_temp <= x"2D" when bus_temperatura.bit_signo = '1' else x"2B";
        ascii_signo_consigna <= x"2D" when bus_control.consigna(15) = '1' else x"2B";

        with indice select byte_out <=
            -- "DATA "
            x"44" when 0,  -- 'D'
            x"41" when 1,  -- 'A'
            x"54" when 2,  -- 'T'
            x"41" when 3,  -- 'A'
            x"20" when 4,  -- Espacio ' '
            
            -- <CONSIGNA.0> <+99.99 >
            ascii_signo_consigna            when 5,
            x"3" & consigna_bcd_decenas     when 6,
            x"3" & consigna_bcd_unidades    when 7,
            x"2E"                           when 8,   -- punto
            x"3" & consigna_bcd_decimas     when 9,
            x"3" & consigna_bcd_centesimas  when 10,
            x"20"                           when 11,  -- espacio
            
            -- <TEMPERATURA.0> <+99.9 >
            ascii_signo_temp                        when 12,  -- signo de la temperatura
            x"3" & bus_temperatura.bcd_decenas      when 13,
            x"3" & bus_temperatura.bcd_unidades     when 14,
            x"2E"                                   when 15,  -- punto (decimal)
            x"3" & bus_temperatura.bcd_decimas      when 16,
            x"20"                                   when 17,  -- espacio
            
            -- <ERROR.0> <+199.8 >
            x"2B" when 18,   -- +
            x"31" when 19,   -- 1
            x"39" when 20,   -- 9
            x"39" when 21,   -- 9
            x"2E" when 22,   -- punto
            x"38" when 23,   -- 8
            x"20" when 24,  -- espacio
            
            -- <PWM> <255\n>
            x"32" when 25,  -- 2
            x"35" when 26,  -- 5
            x"35" when 27,  -- 5
            x"0A" when 28,  -- salto de linea (LF)
            
            x"21" when others;  -- signo de exclamacion
        
        
        
end architecture;