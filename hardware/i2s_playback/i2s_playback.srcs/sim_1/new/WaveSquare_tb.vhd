package my_pack is new work.synthesizer_package generic map(d_voices => 6, d_bits => 24);
use work.my_pack.ALL;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity WaveSquare_tb is
--  Port ( );
end WaveSquare_tb;

architecture Behavioral of WaveSquare_tb is

    COMPONENT WaveSquare is
    Port (
        clock_in   : IN STD_LOGIC;
        reset_in   : IN STD_LOGIC;
        start      : IN STD_LOGIC;
        cycles     : IN TYPE_CYCLES;
        pulsewidth : IN TYPE_PULSEW;
        note_enab  : IN STD_LOGIC_VECTOR(VOICES - 1 downto 0);
        r_data_out : OUT TYPE_DATA_OUT
     );
    end COMPONENT;
    
    signal clk : STD_LOGIC := '1';
    signal reset, start : STD_LOGIC := '0';
	signal data : TYPE_DATA_OUT;
	signal note_enab : STD_LOGIC_VECTOR(VOICES - 1 downto 0) := (others => '1');
	signal cycles : TYPE_CYCLES := (0 => 100, 1 => 150, 2 => 200, 3 => 801, 4 => 1513, 5 => 4040);
	signal pulsewidth : TYPE_PULSEW := (others => 50);

begin

    uut : WaveSquare port map(
        clk, reset, start, cycles, pulsewidth, note_enab, data
    );
    
    clk <= not clk after 5 ns; 

	process
	begin
		reset <= '0'; -- activa a nivel bajo
		wait for 10 ns;
		reset <= '1';
		
		wait for 10 ns;
		
		start <= '1'; -- activa solo un ciclo de reloj
		wait for 10 ns;
		start <= '0';
        
        for i in 0 to 15000 loop
            if i = 7500 then
                pulsewidth(0) <= 90;
                pulsewidth(1) <= 25;
            end if;
            
            wait for 226 ns;
            start <= '1';
            wait for 10 ns;
            start <= '0';
		end loop;
		
		wait;
	end process;

end Behavioral;