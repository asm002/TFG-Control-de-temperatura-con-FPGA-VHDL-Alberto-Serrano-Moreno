-- Este modulo tan solo instancia COMUNICACIONES (y adquisicion) 
-- para conectarlo con los periféricos de la tarjeta y así probar dicho modulo.

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
    constant PLL_C0_FREC : integer := 25E6;
    
    signal clk_adc : std_logic; -- 25 MHz
    signal pll_locked : std_logic;
    signal reset_global : std_logic;
    
    signal bit_signo_temp : std_logic;
    signal bcd_decenas_temp : std_logic_vector(3 downto 0);
    signal bcd_unidades_temp : std_logic_vector(3 downto 0);
    signal bcd_decimas_temp : std_logic_vector(3 downto 0);
    
    begin
        ------------------------------------------------------------------
        -- MAPEO DE ENTIDADES INTERNAS
        ------------------------------------------------------------------
        COMUNICACIONES : entity work.COMUNICACIONES
            generic map(
                CLK_FREQ => PLL_C0_FREC,
                BAUD_FREQ => 115200,
                MSG_FREQ => 10  -- 100 ms -> 10 hz
                )
            port map(
                clk => clk_adc,
                switches => SW,
                reset_n => reset_global,
                out_pin => ARDUINO_IO(15),
                in_pin => open,
                
                bit_signo_temp => bit_signo_temp, 
                bcd_decenas_temp => bcd_decenas_temp,
                bcd_unidades_temp => bcd_unidades_temp,
                bcd_decimas_temp => bcd_decimas_temp
                
            );
            
        ADQUISICION : entity work.ADQUISICION_DE_DATOS
            port map(
                clk_50 => MAX10_CLK1_50,
                switches => SW,       
                reset_n => ARDUINO_RESET_N,
                
                disp0 => HEX0,
                disp1 => HEX1,
                disp2 => HEX2,
                disp3 => HEX3,
                disp4 => HEX4,
                
                disp5 => HEX5,
                clk_adc => clk_adc,
                pll_locked_out => pll_locked,
                temp_milivoltios => open,   -- "open" en vhdl sirve para indicar 
                                            -- de manera explicita que una señal
                                            -- no se conecta a nada
                temp_centesimas_centigrado => open,
                
                bit_signo_temp => bit_signo_temp,
                bcd_decenas_temp => bcd_decenas_temp,
                bcd_unidades_temp => bcd_unidades_temp,
                bcd_decimas_temp => bcd_decimas_temp
        );
            
        
        ------------------------------------------------------------------
        -- LOGICA COMBINACIONAL ; ASIGNACIONES DIRECTAS
        ------------------------------------------------------------------
        reset_global <= ARDUINO_RESET_N and pll_locked;
        
        
        
end architecture;