library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

use work.CONFIG_PROYECTO.all;

entity GESTION_DISPLAYS is
    generic(
        N_BITS_VALOR_ABSOLUTO : integer
        );
    port(
        valor_absoluto : in std_logic_vector(N_BITS_VALOR_ABSOLUTO-1 downto 0);  -- de 0000 a 9999
        es_negativo : in boolean;
        id : in std_logic_vector(3 downto 0);
        array_puntos_decimales : in std_logic_vector(3 downto 0);   -- 9.9.9.9. -> "1111"
        displays_hex_out : out t_displays_7seg
    );
end entity;

architecture Behavioral of GESTION_DISPLAYS is
    ------------------------------------------------------------------
    -- DEFINICION DE SEÑALES INTERNAS, TIPOS Y CONSTANTES
    ------------------------------------------------------------------
    signal bus_bcd : t_bus_bcd;
    
    begin
        ------------------------------------------------------------------
        -- MAPEO DE ENTIDADES INTERNAS
        ------------------------------------------------------------------
        BIN2BCD_9999_inst : entity work.BIN2BCD_9999
            generic map (
                n_bits => N_BITS_VALOR_ABSOLUTO
            )
            port map (
                BIN => valor_absoluto,
                BCD0 => bus_bcd.bcd0,
                BCD1 => bus_bcd.bcd1,
                BCD2 => bus_bcd.bcd2,
                BCD3 => bus_bcd.bcd3
            );
        
        -- displays 0 al 3 del valor absoluto
        DISPLAY_0 : entity work.DISPLAY
            generic map (BCD => true) port map (
                BIN => bus_bcd.bcd0, D7SEG => displays_hex_out(0), 
                DP => array_puntos_decimales(0), OFF => '0');
        
        DISPLAY_1 : entity work.DISPLAY
            generic map (BCD => true) port map (
                BIN => bus_bcd.bcd1, D7SEG => displays_hex_out(1), 
                DP => array_puntos_decimales(1), OFF => '0');
        
        DISPLAY_2 : entity work.DISPLAY
            generic map (BCD => true) port map (
                BIN => bus_bcd.bcd2, D7SEG => displays_hex_out(2), 
                DP => array_puntos_decimales(2), OFF => '0');
            
        DISPLAY_3 : entity work.DISPLAY
            generic map (BCD => true) port map (
                BIN => bus_bcd.bcd3, D7SEG => displays_hex_out(3), 
                DP => array_puntos_decimales(3), OFF => '0');
        
        -- el display 4, que muestra el signo, se asigna directamente puesto que no
        -- corresponde a un valor numérico, es un símbolo
        
        -- display 5 para mostrar el id
        DISPLAY_5 : entity work.DISPLAY
            generic map (BCD => false) port map (
                BIN => id, D7SEG => displays_hex_out(5), 
                DP => '1', OFF => '0');
        
        
        ------------------------------------------------------------------
        -- LOGICA COMBINACIONAL ; ASIGNACIONES DIRECTAS
        ------------------------------------------------------------------
        displays_hex_out(4) <= "10111111" when es_negativo = true else "11111111";
        
end architecture;