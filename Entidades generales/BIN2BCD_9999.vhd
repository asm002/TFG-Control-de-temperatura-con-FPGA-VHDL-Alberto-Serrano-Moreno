----------------------------------------------------------------------------------------
-- Convierte un número binario de hasta 9999 en 4 dígitos BCD
----------------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity BIN2BCD_9999 is 
    generic (
        n_bits : integer := 14 -- Se ajusta para representar hasta 9999
    );
    port (          
        BIN : in STD_LOGIC_VECTOR (n_bits-1 downto 0);
        BCD0 : out STD_LOGIC_VECTOR (3 downto 0); -- Unidades
        BCD1 : out STD_LOGIC_VECTOR (3 downto 0); -- Decenas
        BCD2 : out STD_LOGIC_VECTOR (3 downto 0); -- Centenas
        BCD3 : out STD_LOGIC_VECTOR (3 downto 0)  -- Millar
    );
end entity;

architecture Behavioral of BIN2BCD_9999 is

    signal entero: integer range 0 to 2**n_bits - 1;
    signal unidades: integer range 0 to 9;
    signal decenas: integer range 0 to 9;
    signal centenas: integer range 0 to 9;
    signal millares: integer range 0 to 9;

begin
    entero <= TO_INTEGER(unsigned(BIN));

    unidades  <= entero mod 10;
    decenas   <= (entero / 10) mod 10;
    centenas  <= (entero / 100) mod 10;
    millares  <= (entero / 1000) mod 10;

    -- Si se pasa de 9999 (99.99 C), saturamos los displays mostrando "9999"
    BCD3 <= std_logic_vector(TO_UNSIGNED(millares, 4)) when entero <= 9999 else "1001"; -- 9
    BCD2 <= std_logic_vector(TO_UNSIGNED(centenas, 4)) when entero <= 9999 else "1001"; -- 9
    BCD1 <= std_logic_vector(TO_UNSIGNED(decenas, 4))  when entero <= 9999 else "1001"; -- 9
    BCD0 <= std_logic_vector(TO_UNSIGNED(unidades, 4)) when entero <= 9999 else "1001"; -- 9

end architecture;
