library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library work;
use work.CONFIG_PROYECTO.all;

--  Formato completo de mensajes:
--  DATA <CONSIGNA.0> <TEMPERATURA.0> <ERROR.0> <PWM>

entity MENSAJE_TX is
    port(
        indice : in integer range 0 to MSG_N_BYTES-1;
        byte_out : out std_logic_vector(7 downto 0);
        
        -- TEMPERATURA (aprovechamos los convertidores BCD de la adquisicion)
        bus_temperatura : in t_bus_temperatura
        
    );
end entity;

architecture Behavioral of MENSAJE_TX is
    ------------------------------------------------------------------
    -- DEFINICION DE SEÑALES INTERNAS, TIPOS Y CONSTANTES
    ------------------------------------------------------------------
    signal ascii_signo_temp : std_logic_vector(7 downto 0);
    
    begin
        ------------------------------------------------------------------
        -- MAPEO DE ENTIDADES INTERNAS
        ------------------------------------------------------------------
        
        -- signo menos (0x2D) o signo más (0x2B) en ASCII
        ascii_signo_temp <= x"2D" when bus_temperatura.bit_signo = '1' else x"2B";
        
        ------------------------------------------------------------------
        -- LOGICA COMBINACIONAL ; ASIGNACIONES DIRECTAS
        ------------------------------------------------------------------
        with indice select byte_out <=
            -- "DATA "
            x"44" when 0,  -- 'D'
            x"41" when 1,  -- 'A'
            x"54" when 2,  -- 'T'
            x"41" when 3,  -- 'A'
            x"20" when 4,  -- Espacio ' '
            
            -- <CONSIGNA.0> <+99.9 >
            x"2D" when 5,   -- -
            x"30" when 6,   -- 0
            x"35" when 7,   -- 5
            x"2E" when 8,   -- punto
            x"37" when 9,   -- 7
            x"20" when 10,  -- espacio
            
            -- <TEMPERATURA.0> <+99.9 >
            ascii_signo_temp                        when 11,  -- signo de la temperatura
            x"3" & bus_temperatura.bcd_decenas      when 12,
            x"3" & bus_temperatura.bcd_unidades     when 13,
            x"2E"                                   when 14,  -- punto (decimal)
            x"3" & bus_temperatura.bcd_decimas      when 15,
            x"20"                                   when 16,  -- espacio
            
            -- <ERROR.0> <+199.8 >
            x"2B" when 17,   -- +
            x"31" when 18,   -- 1
            x"39" when 19,   -- 9
            x"39" when 20,   -- 9
            x"2E" when 21,   -- punto
            x"38" when 22,   -- 8
            x"20" when 23,  -- espacio
            
            -- <PWM> <255\n>
            x"32" when 24,  -- 2
            x"35" when 25,  -- 5
            x"35" when 26,  -- 5
            x"0A" when 27,  -- salto de linea (LF)
            
            x"21" when others;  -- signo de exclamacion
        
        
        
end architecture;