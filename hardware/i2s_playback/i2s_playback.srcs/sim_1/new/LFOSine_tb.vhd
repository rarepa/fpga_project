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

entity LFOSine_tb is
--  Port ( );
end LFOSine_tb;

architecture Behavioral of LFOSine_tb is

    COMPONENT LFOSine is
      Port (
        clock_in  : IN STD_LOGIC;
        reset_in  : IN STD_LOGIC;
        start     : IN STD_LOGIC;
        note_code : IN TYPE_LFO_NOTE;
        data_out  : OUT TYPE_LFO_DATA
      );
    end COMPONENT;
    
    signal clk : STD_LOGIC := '1';
    signal reset, start : STD_LOGIC := '0';
	signal data : TYPE_LFO_DATA;
	signal note : TYPE_LFO_NOTE := (0 => 74, 1 => 61);

begin

    uut : LFOSine port map(
        clk, reset, start, note, data
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
        
        for i in 0 to 20000 loop
            wait for 226 ns;
            start <= '1';
            wait for 10 ns;
            start <= '0';
            if i = 2300 then
                note(0) <= 36;
                note(1) <= 32;
            end if;
		end loop;
		
		wait;
	end process;

end Behavioral;