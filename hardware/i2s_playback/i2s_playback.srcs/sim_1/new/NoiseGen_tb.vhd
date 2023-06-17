package my_pack is new work.synthesizer_package generic map(d_voices => 6, d_bits => 24);
use work.my_pack.ALL;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity NoiseGen_tb is
--  Port ( );
end NoiseGen_tb;

architecture Behavioral of NoiseGen_tb is

    COMPONENT NoiseGen is
    Port (
        clock_in     : IN STD_LOGIC;
        reset_in     : IN STD_LOGIC;
        start        : IN STD_LOGIC;
        enable_in    : IN STD_LOGIC;
        noise_volume : IN INTEGER range 0 to 100;
        data_in      : IN SIGNED(BIT_DEPTH - 1 downto 0);
        data_out     : OUT SIGNED(BIT_DEPTH - 1 downto 0)
    );
    end COMPONENT;
    
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
    
    COMPONENT WaveSawtooth is
    Port (
        clock_in   : IN STD_LOGIC;
        reset_in   : IN STD_LOGIC;
        start      : IN STD_LOGIC;
        cycles     : IN TYPE_CYCLES;
        note_enab  : IN STD_LOGIC_VECTOR(VOICES - 1 downto 0);
        r_data_out : OUT TYPE_DATA_OUT
     );
    end COMPONENT;
    
    constant CLK_FREQ : TIME := 90ns;

    signal clk : STD_LOGIC := '1';
    signal reset : STD_LOGIC := '0';
    
    signal start_gen, start_noise : STD_LOGIC := '0';
    
    signal cycles_now : TYPE_CYCLES := (others => 100);
    
    signal note_enab : STD_LOGIC_VECTOR(VOICES - 1 downto 0) := (others => '1');
    
    signal r_data_out_sin, r_data_out_saw : TYPE_DATA_OUT;
	
	signal data_in, data_out : SIGNED(BIT_DEPTH - 1 downto 0);
	
	signal noise_volume, progressive : INTEGER := 0;

begin

    uut : NoiseGen port map(
        clock_in => clk,
        reset_in => reset,
        enable_in => '1',
        start => start_noise,
        noise_volume => noise_volume,
        data_in => data_in,
        data_out => data_out
    );
    
    --instantiate wave sine component
    wave_sin_0 : WaveSine
       port map (
       clock_in => clk,
       reset_in => reset,
       start => start_gen,
       cycles => cycles_now,
       note_enab => note_enab,
       r_data_out => r_data_out_sin
    );
    
    --instantiate wave saw component
    wave_saw_0 : WaveSawtooth
       port map (
       clock_in => clk,
       reset_in => reset,
       start => start_gen,
       cycles => cycles_now,
       note_enab => note_enab,
       r_data_out => r_data_out_saw
    );
    
    clk <= not clk after CLK_FREQ/2;

	process
	begin
		reset <= '0';
		wait for CLK_FREQ;
		reset <= '1';
		
		for i in 0 to 15000 loop
		    start_gen <= '1';
		    wait for CLK_FREQ;
            start_gen <= '0';
		    
		    wait for CLK_FREQ * (6 * 4);
		    
		    start_noise <= '1';
--            data_in <= r_data_out_sin(0);
            data_in <= r_data_out_saw(0);
            wait for CLK_FREQ;
            start_noise <= '0';
            
            -- simulamos que añadimos ruido
            if noise_volume < 100 then
                if progressive = 10 then -- aumentamos progresivamente
                    noise_volume <= noise_volume + 1;
                    progressive <= 0;
                else
                    progressive <= progressive + 1;
                end if;
            end if;
            
            wait for CLK_FREQ * 255;
		end loop;
		
		wait;
	end process;

end Behavioral;