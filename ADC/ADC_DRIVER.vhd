library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity ADC_DRIVER is
	port(
		 clk_in  : in  std_logic;   -- 50 MHz de la placa
		 reset   : in  std_logic;

		 clk_out : out std_logic;   -- reloj interno de lógica (PLL_c0)

		 ch1_data : out std_logic_vector(11 downto 0);
		 ch2_data : out std_logic_vector(11 downto 0);

		 adc_valid : out std_logic
	);
end entity;

architecture Behavioral of ADC_DRIVER is
	-- definicion de señales internas --
	--signal reset : STD_LOGIC;
	signal command_valid : STD_LOGIC;
	signal command_channel : STD_LOGIC_VECTOR(4 DOWNTO 0) :="00001";
	signal command_startofpacket : STD_LOGIC;
	signal command_endofpacket : STD_LOGIC;
	signal command_ready : STD_LOGIC;
	signal response_valid : STD_LOGIC;
	signal response_channel : STD_LOGIC_VECTOR(4 DOWNTO 0);
	signal response_data : STD_LOGIC_VECTOR(11 DOWNTO 0);
	signal response_startofpacket : STD_LOGIC;
	signal response_endofpacket : STD_LOGIC;
	
	signal PLL_c0 : STD_LOGIC;
	signal PLL_c1 : STD_LOGIC;
	signal PLL_locked : STD_LOGIC;
	
	-- definicion de componentes (otra forma de declarar y usar entidades) --
	
	component PLL_IP IS
	-- Representa al ALTPLL IP Core, encargado de generar los relojes estables que el ADC necesita para funcionar
		port
		(
			areset		: IN STD_LOGIC  := '0';
			inclk0		: IN STD_LOGIC  := '0';
			c0		: OUT STD_LOGIC ;
			c1		: OUT STD_LOGIC ;
			locked		: OUT STD_LOGIC 
		);
	end component;
	
	component ADC_IP is
	-- Entidad para comunicarse con el bloque Modular ADC Core Intel FPGA IP, que es el "driver" lógico que controla el hardware del convertidor
		port (
			adc_pll_clock_clk      : in  std_logic                     := '0';             --  adc_pll_clock.clk
			adc_pll_locked_export  : in  std_logic                     := '0';             -- adc_pll_locked.export
			clock_clk              : in  std_logic                     := '0';             --          clock.clk
			command_valid          : in  std_logic                     := '0';             --        command.valid
			command_channel        : in  std_logic_vector(4 downto 0)  := (others => '0'); --               .channel
			command_startofpacket  : in  std_logic                     := '0';             --               .startofpacket
			command_endofpacket    : in  std_logic                     := '0';             --               .endofpacket
			command_ready          : out std_logic;                                        --               .ready
			reset_sink_reset_n     : in  std_logic                     := '0';             --     reset_sink.reset_n
			response_valid         : out std_logic;                                        --       response.valid
			response_channel       : out std_logic_vector(4 downto 0);                     --               .channel
			response_data          : out std_logic_vector(11 downto 0);                    --               .data
			response_startofpacket : out std_logic;                                        --               .startofpacket
			response_endofpacket   : out std_logic                                         --               .endofpacket
		);
	end component;
	
	begin
		-- mapeo de entidades internas --
		PLL0 : PLL_IP
			port map (
						areset	=>	not reset,
						inclk0	=> clk_in,
						c0			=> PLL_c0,
						c1			=>	PLL_c1,
						locked	=>	PLL_locked
						);
		
		ADC0 : ADC_IP
			port map (
						adc_pll_clock_clk      => PLL_c1,
						adc_pll_locked_export  => PLL_locked,
						clock_clk              => PLL_c0,
						command_valid          => command_valid,
						command_channel        => command_channel,
						command_startofpacket  => command_startofpacket,
						command_endofpacket    => command_endofpacket,
						command_ready          => command_ready,
						reset_sink_reset_n     => reset,
						response_valid         => response_valid,
						response_channel       => response_channel,
						response_data          => response_data,
						response_startofpacket => response_startofpacket,
						response_endofpacket   => response_endofpacket
						);
		
		
		-- < mapeo de señales combinacionales > --
		command_valid <= '1';	-- para estar siempre ordenando que se reciban datos
		--command_startofpacket <= '1';
		--command_endofpacket <= '1';
		
		clk_out <= PLL_c0;
		--adc_valid <= response_valid;
		
		-- procesos --
		process(PLL_c0)
			variable canal :integer range 0 to 31 :=1;
			begin			
				if rising_edge(PLL_c0) then
				adc_valid <= '0';	-- siempre a nivel bajo salvo que se indique lo contrario (cuando el ultimo canal haya leido)
					if command_ready = '1' and response_valid = '1' then
						if response_channel="00001" then
							ch1_data<=response_data(11 downto 0);
							canal:=2;
						elsif response_channel="00010" then
							ch2_data<=response_data(11 downto 0);
							canal:=1;
							adc_valid <= '1';	-- solo damos un pulso, en el siguiente flanco se pondra a cero
						end if;
						command_channel<=std_logic_vector(TO_UNSIGNED(canal,5));
					end if;
				end if;
		end process;
		
end architecture;