-- Este modulo tan solo instancia COMUNICACIONES (y adquisicion) 
-- para conectarlo con los periféricos de la tarjeta y así probar dicho modulo.

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library work;
use work.CONFIG_PROYECTO.all;

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
    
    signal clk_adc : std_logic; -- 25 MHz
    signal pll_locked : std_logic;
    signal reset_and_pll_n : std_logic;
    
    signal bus_temperatura : t_bus_temperatura;
    
    begin
        ------------------------------------------------------------------
        -- MAPEO DE ENTIDADES INTERNAS
        ------------------------------------------------------------------
        COMUNICACIONES : entity work.COMUNICACIONES
            generic map(
                CLK_FREQ => PLL_C0_FREC,
                BAUD_FREQ => BAUD_FREC,
                MSG_FREQ => MSG_FREC  -- 100 ms -> 10 hz
                )
            port map(
                clk => clk_adc,
                switches => SW,
                reset_n => reset_and_pll_n,
                out_pin => ARDUINO_IO(PIN_TX),
                in_pin => open,
                
                bus_temperatura => bus_temperatura
                
            );
            
        ADQUISICION : entity work.ADQUISICION_DE_DATOS
            port map(
                clk_50 => MAX10_CLK1_50,
                switches => SW,       
                reset_n => ARDUINO_RESET_N, -- mucho cuidado, aqui solo reset de boton,
                                            -- usar reset_and_pll_n crea un bucle
                                            -- infinito y no funciona nada
                
                disp0 => HEX0,
                disp1 => HEX1,
                disp2 => HEX2,
                disp3 => HEX3,
                disp4 => HEX4,
                
                disp5 => HEX5,
                clk_adc => clk_adc,
                pll_locked_out => pll_locked,
                --temp_milivoltios => open,   -- "open" en vhdl sirve para indicar 
                                            -- de manera explicita que una señal
                                            -- no se conecta a nada
                --temp_centesimas_centigrado => open,
                
                bus_temperatura => bus_temperatura
        );
            
        
        ------------------------------------------------------------------
        -- LOGICA COMBINACIONAL ; ASIGNACIONES DIRECTAS
        ------------------------------------------------------------------
        reset_and_pll_n <= ARDUINO_RESET_N and pll_locked;  -- reset de boton y ademas condicionado a que el pll
                                                            -- esté listo. Activo a nivel bajo
        
        
        
end architecture;