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

entity WaveSine_tb is
--  Port ( );
end WaveSine_tb;

architecture Behavioral of WaveSine_tb is

    COMPONENT WaveSine is
    Port (
        clock_in   : IN STD_LOGIC;
        reset_in   : IN STD_LOGIC;
        start      : IN STD_LOGIC;
        cycles     : IN TYPE_CYCLES;
        note_enab  : IN STD_LOGIC_VECTOR(VOICES - 1 downto 0);
        r_data_out : OUT TYPE_DATA_OUT
     );
    end COMPONENT;
    
    signal clk : STD_LOGIC := '1';
    signal reset, start : STD_LOGIC := '0';
	signal data : TYPE_DATA_OUT;
	signal note_enab : STD_LOGIC_VECTOR(VOICES - 1 downto 0) := (others => '1');
	signal cycles : TYPE_CYCLES := (1 => 100, 2 => 150, others => 200);

begin

    uut : WaveSine port map(
        clk, reset, start, cycles, note_enab, data
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
            wait for 226 ns;
            start <= '1';
            wait for 10 ns;
            start <= '0';
		end loop;
		
		wait;
	end process;

end Behavioral;