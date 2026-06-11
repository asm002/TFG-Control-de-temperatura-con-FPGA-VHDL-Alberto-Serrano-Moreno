library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library work;
use work.CONFIG_PROYECTO.all;

entity MENSAJE_TX is
    port(
        indice : in integer range 0 to 10;
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
            
            -- "-99.9/n"
            ascii_signo_temp when 5, -- signo de la temperatura
            x"3" & bus_temperatura.bcd_decenas when 6,
            x"3" & bus_temperatura.bcd_unidades when 7,
            x"2E" when 8, -- punto (decimal)
            x"3" & bus_temperatura.bcd_decimas when 9,
            x"0A" when 10;  -- salto de linea (LF)
        
        
        
end architecture;