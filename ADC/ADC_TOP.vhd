library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity ADC_TOP is
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

architecture Behavioral of ADC_TOP is
	-- < definicion de señales internas > --
	signal BCD0 : STD_LOGIC_VECTOR(3 downto 0);
	signal BCD1 : STD_LOGIC_VECTOR(3 downto 0);
	signal BCD2 : STD_LOGIC_VECTOR(3 downto 0);
	signal BCD3 : STD_LOGIC_VECTOR(3 downto 0);
	
	signal DATO_ESCALADO : unsigned(21 downto 0);
	signal MULTIPLICACION : unsigned(24 downto 0);
	signal DIVISION : unsigned(12 downto 0);
	signal RES : STD_LOGIC_VECTOR(12 downto 0);
	
	signal ADC_CLK : std_logic;
	
	signal CH1: std_LOGIC_VECTOR(11 downto 0);
	signal ADC_VALID: std_LOGIC;
	
	signal CH1_PROMEDIADO: std_LOGIC_VECTOR(11 downto 0);
	
	signal BCD0_P : STD_LOGIC_VECTOR(3 downto 0);
	signal BCD1_P : STD_LOGIC_VECTOR(3 downto 0);
	signal BCD2_P : STD_LOGIC_VECTOR(3 downto 0);
	signal BCD3_P : STD_LOGIC_VECTOR(3 downto 0);
	
	signal PULSE_4HZ : std_logic := '0';
	
	begin
		-- < mapeo de entidades internas > --
		BIN2BCD0 : entity work.BIN2BCD_9999 generic map(13) port map(RES, BCD0, BCD1, BCD2, BCD3);
		
		D0 : entity work.DISPLAY generic map(BCD => true) port map (BIN => BCD0_P, D7SEG => HEX0, DP => '0');
		D1 : entity work.DISPLAY generic map(BCD => true) port map (BIN => BCD1_P, D7SEG => HEX1, DP => '0');
		D2 : entity work.DISPLAY generic map(BCD => true) port map (BIN => BCD2_P, D7SEG => HEX2, DP => '0');
		D3 : entity work.DISPLAY generic map(BCD => true) port map (BIN => BCD3_P, D7SEG => HEX3, DP => '1');
		D4 : entity work.DISPLAY port map (BIN => "0000", D7SEG => HEX4, OFF => '1');
		D5 : entity work.DISPLAY port map (BIN => "0000", D7SEG => HEX5, OFF => '1');	
	
		
		ADC_DRIVER0 : entity work.ADC_DRIVER
			port map(
						clk_in => MAX10_CLK1_50,
						clk_out => ADC_CLK,
						reset => ARDUINO_RESET_N,
						ch1_data => CH1,
						adc_valid => ADC_VALID
						);
						
		MEDIA_MOVIL0 : entity work.MEDIA_MOVIL 
							generic map(N_BITS_DATO => 12, 
											N_BITS_MUESTRAS => 6,
											VENTANA_TIEMPO_MS => 20,
											CLK_FREC => 10E6)
							port map(
										CLK => ADC_CLK,
										DATO_LISTO => ADC_VALID,
										DATO => CH1,
										DATO_PROMEDIADO => CH1_PROMEDIADO);
										
		GENERADOR_PULSOS_4HZ : 	entity work.GENERADOR_PULSOS
										generic map(CLK_FREC => 10E6, PULSE_FREC => 4)
										port map(
												CLK => ADC_CLK,
												PULSE => PULSE_4HZ
												);
		
		-- < mapeo de señales combinacionales > --
		DATO_ESCALADO <= (unsigned(CH1_PROMEDIADO)*to_unsigned(1000, 10));	-- multiplicamos por 1000 para representar del 0 al 5000 y luego en los displays encendemos el punto decimal en el primer digito, de manera que queda 5,000
		MULTIPLICACION <= DATO_ESCALADO*to_unsigned(5, 3);	-- multiplicacion por 5, el rango de tension
		DIVISION <= MULTIPLICACION(24 downto 12);	-- division entre 4096 que equivale a un desplazamiento a la derecha de 12 bits (2^12=4096) o quedarse con los 13 bits (25 totales - 12 desplazados y eliminados) mas significativos
		RES <= std_logic_vector(DIVISION);
		
		-- procesos --
		process(ADC_CLK)
			-- < declaracion de variables >
			
			begin			
				if rising_edge(ADC_CLK) then
					
				if PULSE_4HZ = '1' then
				
					BCD0_P <= BCD0;
					BCD1_P <= BCD1;
					BCD2_P <= BCD2;
					BCD3_P <= BCD3;
					
				end if;
				
				end if;
		end process;
		
end architecture;