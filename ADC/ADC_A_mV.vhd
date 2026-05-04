library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity ADC_A_mV is
	GENERIC(
		N_BITS_ADC : integer := 12																	-- bits del ADC
		);
	PORT(
		cuentas_ADC : in std_logic_vector(11 downto 0);
		conversion_mv : out std_logic_vector(12 downto 0)
	);
END entity;

architecture Behavioral of ADC_A_mV is
	-- < definicion de señales internas > --
	constant N_BITS_mV : integer := 13;															-- bits necesarios para representar la tension de referencia en mV (por ejemplo, 5000)
	constant VREFmv : integer := 5000;															-- tension de referencia en milivoltios
	
	constant N_BITS_FACTOR : integer := 3+10;													-- 3 bits para V_ref y 10 bits para 1000
	constant N_BITS_PRODUCTO : integer := N_BITS_ADC + N_BITS_FACTOR;					-- multiplicacion de un dato de 12 bits y un dato de 13 bits
	constant N_BITS_DIVISION : integer := N_BITS_PRODUCTO - 12;							-- desplazamiento de 12 bits al dato anterior							
	
	signal PRODUCTO : unsigned(N_BITS_PRODUCTO-1 downto 0);								
	signal DIVISION : unsigned(N_BITS_DIVISION-1 downto 0);								
	
	begin
		-- < mapeo de entidades internas > --
		
		-- < mapeo de señales combinacionales > --
		PRODUCTO <= (unsigned(cuentas_ADC)*to_unsigned(VREFmv, N_BITS_FACTOR));		-- multiplicacion por 5, el rango de tension ; multiplicamos por 1000 para representar del 0 al 5000 y luego en los displays encendemos el punto decimal en el primer digito, de manera que queda 5,000
		DIVISION <= PRODUCTO(N_BITS_PRODUCTO-1 downto N_BITS_ADC);									-- division entre 4096 que equivale a un desplazamiento a la derecha de 12 bits (2^12=4096) o quedarse con los 13 bits (25 totales - 12 desplazados y eliminados) mas significativos
		conversion_mv <= std_logic_vector(DIVISION);
		
		
		
end architecture;