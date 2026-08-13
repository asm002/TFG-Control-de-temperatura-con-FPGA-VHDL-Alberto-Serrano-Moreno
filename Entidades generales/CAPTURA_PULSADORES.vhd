-- Toma un vector de pulsadores activos a nivel alto (con antirrebote de fábrica), 
-- los sincroniza con el reloj y detecta el evento de flanco ascendente para cada uno.

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity CAPTURA_PULSADORES is
    generic(
        N_PULSADORES : integer := 2
    );
    port(
        clk : in std_logic;
        reset : in std_logic;

        pulsadores : in std_logic_vector(N_PULSADORES-1 downto 0);
        pulsos : out std_logic_vector(N_PULSADORES-1 downto 0)
    );
end entity;

architecture Behavioral of CAPTURA_PULSADORES is
    ------------------------------------------------------------------
    -- DEFINICION DE SEÑALES INTERNAS, TIPOS Y CONSTANTES
    ------------------------------------------------------------------
    
    -- biestables para sincronizar señal asíncrona externa con el reloj y evitar metaestabilidades
    signal sync1, sync2 : std_logic_vector(N_PULSADORES-1 downto 0) := (others => '0');

    signal estado_anterior : std_logic_vector(N_PULSADORES-1 downto 0) := (others => '0');
    
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
                        sync1 <= (others => '0');
                        sync2 <= (others => '0');
                        estado_anterior <= (others => '0');
                    else
                        pulsos <= (others => '0');
                        sync1 <= pulsadores;
                        sync2 <= sync1;
                        estado_anterior <= sync2;
                        
                        pulsos <= sync2 and not estado_anterior;
                    end if;
                end if;
        end process;
        
end architecture;