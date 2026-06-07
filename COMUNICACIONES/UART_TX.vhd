library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity UART_TX is
    port(
        clk         : in  std_logic;                    -- Reloj del sistema (10 MHz)
        rst         : in  std_logic;                    -- Reset síncrono
        baud_ce     : in  std_logic;                    -- Pulso de habilitación (1 de cada 87 ciclos)
        tx_start    : in  std_logic;                    -- Orden de empezar a transmitir (1 ciclo)
        tx_data     : in  std_logic_vector(7 downto 0); -- El byte que queremos mandar
        tx_out      : out std_logic;                    -- Pin físico de salida TX
        tx_ready    : out std_logic;                    -- '1' si está libre, '0' si está ocupado
        tx_done     : out std_logic                     -- Pulso de fin de transmisión (1 ciclo)
    );
END entity;

architecture Behavioral of UART_TX is
    ------------------------------------------------------------------
    -- DEFINICION DE SEÑALES INTERNAS, TIPOS Y CONSTANTES
    ------------------------------------------------------------------
    type t_estados is (ST_IDLE, ST_START, ST_DATA, ST_STOP);
    signal estado : t_estados := ST_IDLE;

    signal r_tx_reg   : std_logic_vector(7 downto 0) := (others => '0');
    signal r_bit_idx  : integer range 0 to 7 := 0;
    signal r_tx_out   : std_logic := '1';
    
    
    begin
        ------------------------------------------------------------------
        -- MAPEO DE ENTIDADES INTERNAS
        ------------------------------------------------------------------
         
        
        ------------------------------------------------------------------
        -- LOGICA COMBINACIONAL ; ASIGNACIONES DIRECTAS
        ------------------------------------------------------------------
        tx_out   <= r_tx_out;
        tx_ready <= '1' when (estado = ST_IDLE) else '0';
        
        
        ------------------------------------------------------------------
        -- LOGICA SECUENCIAL ; PROCESOS
        ------------------------------------------------------------------
        
        process(clk)
        ------------------------------------------------------------------
        -- DEFINICION DE VARIABLES, TIPOS Y CONSTANTES
        ------------------------------------------------------------------
        
        begin
        if rising_edge(clk) then
            if rst = '1' then
                estado    <= ST_IDLE;
                r_tx_out  <= '1';
                r_bit_idx <= 0;
                tx_done   <= '0';
            else
                tx_done <= '0'; -- El pulso de "hecho" dura solo un ciclo de reloj

                case estado is
                    
                    when ST_IDLE =>
                        r_tx_out <= '1'; -- Línea en alto
                        if tx_start = '1' then
                            r_tx_reg <= tx_data; -- Capturamos el byte inmediatamente
                            estado   <= ST_START;
                        end if;

                    when ST_START =>
                        -- Esperamos al pulso del generador de baudios para cambiar la línea
                        if baud_ce = '1' then
                            r_tx_out  <= '0'; -- Bit de Start (0)
                            r_bit_idx <= 0;
                            estado    <= ST_DATA;
                        end if;

                    when ST_DATA =>
                        if baud_ce = '1' then
                            r_tx_out <= r_tx_reg(r_bit_idx); -- Mandamos el bit actual (LSB primero)
                            
                            if r_bit_idx = 7 then
                                estado <= ST_STOP;
                            else
                                r_bit_idx <= r_bit_idx + 1;
                            end if;
                        end if;

                    when ST_STOP =>
                        if baud_ce = '1' then
                            r_tx_out <= '1'; -- Bit de Stop (1)
                            tx_done  <= '1'; -- Avisamos de que el byte se ha enviado
                            estado   <= ST_IDLE;
                        end if;

                    when others =>
                        estado <= ST_IDLE;
                end case;
            end if;
        end if;
    end process;
        
end architecture;