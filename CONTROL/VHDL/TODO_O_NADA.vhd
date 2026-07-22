library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

use work.CONFIG_PROYECTO.all;

entity TODO_O_NADA is
    port(
        clk : in std_logic;
        reset : in std_logic;

        temp_actual : in signed(N_BITS_CELSIUS-1 downto 0);  -- centesimas de celsius
        consigna : in signed(N_BITS_CELSIUS-1 downto 0);  -- centesimas de celsius
        
        t_on : out unsigned(N_BITS_PWM-1 downto 0)
    );
end entity;

architecture Behavioral of TODO_O_NADA is
    ------------------------------------------------------------------
    -- DEFINICION DE SEÑALES INTERNAS, TIPOS Y CONSTANTES
    ------------------------------------------------------------------
    type t_estados is (ENFRIAR, NO_ENFRIAR);
    signal estado : t_estados := NO_ENFRIAR;

    constant histeresis : integer := 50;  -- 100 centesimas -> 1 grado de histeresis
    
    begin
        ------------------------------------------------------------------
        -- MAPEO DE ENTIDADES INTERNAS
        ------------------------------------------------------------------
        
        
        ------------------------------------------------------------------
        -- LOGICA COMBINACIONAL ; ASIGNACIONES DIRECTAS
        ------------------------------------------------------------------
        
        
        ------------------------------------------------------------------
        -- LOGICA SECUENCIAL ; PROCESOS
        ------------------------------------------------------------------
        process(clk)
        ------------------------------------------------------------------
        -- DEFINICION DE VARIABLES, TIPOS Y CONSTANTES
        ------------------------------------------------------------------
            
            begin           
                if rising_edge(clk) then
                    if reset = '1' then
                        estado <= NO_ENFRIAR;
                        t_on <= (others => '0');
                    else
                        case estado is
                            when ENFRIAR =>
                                if temp_actual < (consigna - histeresis) then
                                    estado <= NO_ENFRIAR;
                                end if;
                                t_on <= (others => '1');

                            when NO_ENFRIAR =>
                                if temp_actual > (consigna + histeresis) then
                                    estado <= ENFRIAR;
                                end if;
                                t_on <= (others => '0');

                            when others =>
                                estado <= NO_ENFRIAR;
                                t_on <= (others => '0');
                        end case;
                    end if;
                end if;
        end process;
        
end architecture;