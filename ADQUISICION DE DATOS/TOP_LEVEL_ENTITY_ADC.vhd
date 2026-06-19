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
    signal bus_displays : t_displays_7seg;
    
    begin
        ------------------------------------------------------------------
        -- MAPEO DE ENTIDADES INTERNAS
        ------------------------------------------------------------------

        ADQUISICION_DE_DATOS0 : entity work.ADQUISICION_DE_DATOS
            port map (
                clk_50 => MAX10_CLK1_50,
                reset_n => ARDUINO_RESET_N,
                modo_displays => SW(0),
                clk_adc => open,  -- "open" en vhdl sirve para indicar 
                                  -- de manera explicita que una señal
                                  -- no se conecta a nada
                pll_locked_out => open,
                bus_temperatura => open,
                displays_out => bus_displays
            );

        ------------------------------------------------------------------
        -- LOGICA COMBINACIONAL ; ASIGNACIONES DIRECTAS
        ------------------------------------------------------------------
        
        -- BUSES SALIDA
        HEX0 <= bus_displays(0);
        HEX1 <= bus_displays(1);
        HEX2 <= bus_displays(2);
        HEX3 <= bus_displays(3);
        HEX4 <= bus_displays(4);
        HEX5 <= bus_displays(5);
        
        ------------------------------------------------------------------
        -- LOGICA SECUENCIAL ; PROCESOS
        ------------------------------------------------------------------
        
        
end architecture;