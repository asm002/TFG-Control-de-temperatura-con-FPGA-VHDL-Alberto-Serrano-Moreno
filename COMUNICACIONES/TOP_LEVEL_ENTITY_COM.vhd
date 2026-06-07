-- Este modulo tan solo instancia COMUNICACIONES para conectarlo con los periféricos de la tarjeta y así probar dicho modulo.

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity TOP_LEVEL_ENTITY_COM is
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

architecture Behavioral of TOP_LEVEL_ENTITY_COM is
    ------------------------------------------------------------------
    -- DEFINICION DE SEÑALES INTERNAS, TIPOS Y CONSTANTES
    ------------------------------------------------------------------
    
    
    begin
        ------------------------------------------------------------------
        -- MAPEO DE ENTIDADES INTERNAS
        ------------------------------------------------------------------
        COMUNICACIONES0: entity work.COMUNICACIONES
            generic map(
                CLK_FREQ => 50E6,
                BAUD_FREQ => 115200
                )
            port map(
                clk => MAX10_CLK1_50,
                switches => SW,
                reset_n => ARDUINO_RESET_N,
                out_pin => ARDUINO_IO(15),
                in_pin => open
            );
        
        ------------------------------------------------------------------
        -- LOGICA COMBINACIONAL ; ASIGNACIONES DIRECTAS
        ------------------------------------------------------------------
        
        
        
        
end architecture;