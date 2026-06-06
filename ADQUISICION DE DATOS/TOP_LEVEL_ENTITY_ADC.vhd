-- Este modulo tan solo instancia ADQUISICION_DE_DATOS para conectarlo con los periféricos de la tarjeta y así probar dicho modulo.

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

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
    
    
    begin
        ------------------------------------------------------------------
        -- MAPEO DE ENTIDADES INTERNAS
        ------------------------------------------------------------------
        
        ADQUISICION_DE_DATOS0 : entity work.ADQUISICION_DE_DATOS
            port map(
                        clk_50 => MAX10_CLK1_50,
                        switches => SW,       
                        reset => ARDUINO_RESET_N,
                        disp0 => HEX0,
                        disp1 => HEX1,
                        disp2 => HEX2,
                        disp3 => HEX3,
                        disp4 => HEX4,
                        disp5 => HEX5,
                        temp_milivoltios => open,   -- "open" en vhdl sirve para indicar 
                                                    -- de manera explicita que una señal
                                                    -- no se conecta a nada
                        temp_centesimas_centigrado => open
                        
                    );
                        
        

        
        ------------------------------------------------------------------
        -- LOGICA COMBINACIONAL ; ASIGNACIONES DIRECTAS
        ------------------------------------------------------------------
        
        
        ------------------------------------------------------------------
        -- LOGICA SECUENCIAL ; PROCESOS
        ------------------------------------------------------------------
        
        
end architecture;