library IEEE;
use IEEE.std_logic_1164.all;

entity TB_BUFFER_RX is end entity;

architecture Sim of TB_BUFFER_RX is
    -- Señales para conectar al UUT (Unit Under Test)
    signal clk, rst : std_logic := '0';
    signal rx_byte : std_logic_vector(7 downto 0) := (others => '0');
    signal rx_ready, buffer_ready, liberar_buffer : std_logic := '0';
    signal out_byte : std_logic_vector(7 downto 0);
    signal indice_out_byte : integer range 0 to 63 := 0;

begin
    -- Instancia de tu BUFFER_RX
    UUT: entity work.BUFFER_RX port map(clk, rst, rx_byte, rx_ready, buffer_ready, liberar_buffer, indice_out_byte, out_byte);

    clk <= not clk after 10 ns; -- Generador de reloj

    -- Proceso de ESTÍMULOS
    process
    begin
        rst <= '1'; wait for 50 ns; rst <= '0'; wait for 50 ns;

        -- Simulamos la llegada del byte 'H' (0x48)
        rx_byte <= x"48"; rx_ready <= '1'; wait for 20 ns;
        rx_ready <= '0'; wait for 20 ns;

        -- Simulamos la llegada del byte 'O' (0x4F)
        rx_byte <= x"4F"; rx_ready <= '1'; wait for 20 ns;
        rx_ready <= '0'; wait for 20 ns;

        -- Simulamos la llegada del \n (0x0A)
        rx_byte <= x"0A"; rx_ready <= '1'; wait for 20 ns;
        rx_ready <= '0'; 
        
        -- Aquí el buffer debería ponerse en BUFFER_COMPLETADO y buffer_ready=1
        wait for 100 ns; 
        
        -- Ahora probamos la lectura del Parser (cambiamos el índice)
        indice_out_byte <= 0; wait for 20 ns; -- Deberías ver 0x48 en out_byte
        indice_out_byte <= 1; wait for 20 ns; -- Deberías ver 0x4F en out_byte
        
        -- Liberamos el buffer
        liberar_buffer <= '1'; wait for 20 ns; liberar_buffer <= '0';
        
        wait;
    end process;
end architecture;