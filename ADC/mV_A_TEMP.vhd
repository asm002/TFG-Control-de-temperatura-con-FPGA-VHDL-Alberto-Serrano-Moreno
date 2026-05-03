library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity mV_A_TEMP is
	PORT(
		mv : in std_logic_vector(12 downto 0);
		conversion_centesimas_gradoC : out signed(15 downto 0)
	);
END entity;

architecture Behavioral of mV_A_TEMP is
	-- < definicion de señales internas, tipos y constantes > --
	constant N_BITS_mV : integer := 13;															-- bits necesarios para representar la tension de referencia en mV (por ejemplo, 5000)
	constant N_BITS_TEMP : integer := 16
	
	constant N_BITS_mv_ESCALADO : integer := N_BITS_mV + 1 + 5;							-- producto de dos datos de 14 y 5 bits -> 19 BITS
	constant N_BITS_RESTA : integer := N_BITS_mv_ESCALADO;										

	
	signal RESTA : signed(N_BITS_RESTA-1 downto 0);
	signal mv_ESCALADO : signed(N_BITS_mv_ESCALADO-1 downto 0);
	
	begin
		-- < mapeo de entidades internas > --
		
		
		-- < logica combinacional; asignaciones directas > --
		
		-- En lugar de restar 273.15 despues de dividir entre 10, se hace ANTES (restando 2731.5)
		-- Para restar 2731.5, se multiplica todo por 10
		
		mv_ESCALADO <= signed('0' & mv) * to_signed(10, 5);
		RESTA <= mv_ESCALADO - to_signed(27315, N_BITS_mv_ESCALADO);
		
		-- La señal RESTA obtiene la temperatura en centesimas de grado centigrado (25.45 C -> 02545)
		-- El ADC lee de 0 a 5000 mv 
		-- Con ese rango, la temperatura puede valer : -27315 -> 22685
		-- Para representar eso con signo: log2(27315) = 15 bits -> mas 1 bit de signo
		-- Con 16 bits podemos representar todo el rango fisicamente posible que puede leer el ADC
		conversion_centesimas_gradoC <= resize(RESTA, N_BITS_TEMP);
		
		
end architecture;