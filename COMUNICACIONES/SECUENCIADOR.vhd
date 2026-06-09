library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity SECUENCIADOR is
    generic(
        MSG_N_BYTES : integer := 11
        );
    port(
        clk : in std_logic;
        rst : in std_logic;
        mandar_mensaje : in std_logic;  -- pulso que ordena enviar un mensaje completo
                                        -- formado por varios bytes y acabado en /n (LF)
        tx_ready : in std_logic;
        tx_done : in std_logic;
        tx_start : out std_logic;
        tx_data : out std_logic_vector(7 downto 0);
        
        msg_byte_indice : out integer range 0 to MSG_N_BYTES-1;
        msg_byte: in std_logic_vector(7 downto 0)
        
    );
end entity;

architecture Behavioral of SECUENCIADOR is
    ------------------------------------------------------------------
    -- DEFINICION DE SEÑALES INTERNAS, TIPOS Y CONSTANTES
    ------------------------------------------------------------------
    
    signal indice : integer range 0 to MSG_N_BYTES-1 := 0;
    
    type estados is (ESPERA, ENVIO, ESPERAR_BYTE);
    signal estado : estados := ESPERA;
    
    begin
        ------------------------------------------------------------------
        -- MAPEO DE ENTIDADES INTERNAS
        ------------------------------------------------------------------
        
        
        ------------------------------------------------------------------
        -- LOGICA COMBINACIONAL ; ASIGNACIONES DIRECTAS
        ------------------------------------------------------------------
        msg_byte_indice <= indice;
        
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
                        estado <= ESPERA;
                        tx_start <= '0';
                        tx_data <= (others => '0');
                        indice <= 0;
                        
                    else
                        tx_start <= '0';    -- para garantizar que sea un pulso
                        
                        case estado is
                            when ESPERA =>
                                indice <= 0;
                                if mandar_mensaje = '1' then
                                    estado <= ENVIO;
                                end if;
                                
                            when ENVIO =>
                                if tx_ready = '1' then
                                    tx_start <= '1';
                                    tx_data <= msg_byte;
                                    estado <= ESPERAR_BYTE;
                                        
                                end if;
                            
                            when ESPERAR_BYTE =>
                                if tx_done = '1' then
                                    if indice = MSG_N_BYTES-1 then
                                        estado <= ESPERA;
                                        
                                    else
                                        indice <= indice + 1;
                                        estado <= ENVIO;
                                        
                                    end if;
                                    
                                end if;
                            
                            when others =>
                                estado <= ESPERA;
                            
                        
                        end case;
                    end if;
                
                end if;
        end process;
        
end architecture;