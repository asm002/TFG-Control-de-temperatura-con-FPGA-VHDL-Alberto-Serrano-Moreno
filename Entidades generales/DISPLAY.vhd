library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity DISPLAY is
	Generic	(
				BCD : boolean := false
				);
	Port 		(
				BIN : in STD_LOGIC_VECTOR (3 downto 0);
				D7SEG : out STD_LOGIC_VECTOR (7 downto 0);
				DP : in STD_LOGIC :='0';
				OFF : in STD_LOGIC :='0'
				);
end entity;

architecture Behavioral of DISPLAY is
signal displayseg : STD_LOGIC_VECTOR (7 downto 0);
signal dispseg : STD_LOGIC_VECTOR (7 downto 0);

begin

with BIN select displayseg(6 downto 0) <=
		"1000000" when "0000",  -- '0'
		"1111001" when "0001",  -- '1'
		"0100100" when "0010",  -- '2'
		"0110000" when "0011",  -- '3'
		"0011001" when "0100",  -- '4' 
		"0010010" when "0101",  -- '5'
		"0000010" when "0110",  -- '6'
		"1111000" when "0111",  -- '7'
		"0000000" when "1000",  -- '8'
		"0010000" when "1001",  -- '9'
		"0001000" when "1010",  -- 'A'
		"0000011" when "1011",  -- 'b'
		"1000110" when "1100",  -- 'C'
		"0100001" when "1101",  -- 'd'
		"0000110" when "1110",  -- 'E'
		"0001110" when "1111";  -- 'F'

displayseg(7)<=not DP;

dispseg <= displayseg when (not BCD) else displayseg when (BCD and unsigned(BIN)<10) else (others=>'1');
-- Si no BCD -> representacion por defecto
-- Si BCD y ademas dato<10 -> representacion por defecto
-- Si BCD y dato>=10 -> todos a '1' (display apagado) 
	
D7SEG<=dispseg when (OFF='0') else (others=>'1');

end architecture;
