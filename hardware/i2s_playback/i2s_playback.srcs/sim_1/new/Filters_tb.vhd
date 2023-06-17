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

entity Filters_tb is
--  Port ( );
end Filters_tb;

architecture Behavioral of Filters_tb is

    COMPONENT Filters is
    Port (
        clock_in     : IN STD_LOGIC;
        reset_in     : IN STD_LOGIC;
        wave_finish  : IN STD_LOGIC;
        note_enable  : IN STD_LOGIC;
        frequency    : IN INTEGER range 0 to 8000;
        resonance    : IN INTEGER range 0 to 100;
        filter_type  : IN INTEGER range 0 to 4;
        filter_lfo   : IN INTEGER range 0 to 100;
        filter_lfo_d : IN INTEGER range 0 to 1;
        lfo3_data    : IN UNSIGNED(23 downto 0);
        lfo3_mode    : IN INTEGER range 0 to 3;
        data_in      : IN SIGNED(BIT_DEPTH - 1 downto 0);
        data_out     : OUT SIGNED(BIT_DEPTH - 1 downto 0)
    );
    end COMPONENT;
    
    -- 44100 Hz / 441 Hz = 100
    constant saw_samples : INTEGER := 100;
    
    type TABLE_DATA_SAW is array (0 to saw_samples - 1) of SIGNED(BIT_DEPTH - 1 downto 0);
    constant data_saw : TABLE_DATA_SAW := (
        x"000000",
        x"028f5c",x"051eb8",x"07ae14",x"0a3d70",x"0ccccc",x"0f5c28",x"11eb85",x"147ae1",x"170a3d",x"199999",
        x"1c28f5",x"1eb851",x"2147ae",x"23d70a",x"266666",x"28f5c2",x"2b851e",x"2e147a",x"30a3d7",x"333333",
        x"35c28f",x"3851eb",x"3ae147",x"3d70a3",x"400000",x"428f5c",x"451eb8",x"47ae14",x"4a3d70",x"4ccccc",
        x"4f5c28",x"51eb85",x"547ae1",x"570a3d",x"599999",x"5c28f5",x"5eb851",x"6147ae",x"63d70a",x"666666",
        x"68f5c2",x"6b851e",x"6e147a",x"70a3d7",x"733333",x"75c28f",x"7851eb",x"7ae147",x"7d70a3",x"800001",
        x"828f5e",x"851eba",x"87ae16",x"8a3d72",x"8cccce",x"8f5c2a",x"91eb87",x"947ae3",x"970a3f",x"99999b",
        x"9c28f7",x"9eb853",x"a147b0",x"a3d70c",x"a66668",x"a8f5c4",x"ab8520",x"ae147c",x"b0a3d9",x"b33335",
        x"b5c291",x"b851ed",x"bae149",x"bd70a5",x"c00002",x"c28f5e",x"c51eba",x"c7ae16",x"ca3d72",x"ccccce",
        x"cf5c2a",x"d1eb87",x"d47ae3",x"d70a3f",x"d9999b",x"dc28f7",x"deb853",x"e147b0",x"e3d70c",x"e66668",
        x"e8f5c4",x"eb8520",x"ee147c",x"f0a3d9",x"f33335",x"f5c291",x"f851ed",x"fae149",x"fd70a5"
    );
    
--    constant data_sawLP800 : TABLE_DATA_SAW := (
--        x"000000",x"000000",
--        x"000881",x"0020f0",x"004fae",x"009a14",x"010487",x"019280",x"02469c",x"0322ae",x"0427cf",x"05566f",
--        x"06ae68",x"082f0e",x"09d743",x"0ba585",x"0d97ff",x"0fac9b",x"11e10d",x"1432e3",x"169f90",x"192478",
--        x"1bbefc",x"1e6c80",x"212a76",x"23f663",x"26cde8",x"29aec2",x"2c96d2",x"2f841f",x"3274d9",x"356759",
--        x"385a20",x"3b4bdd",x"3e3b67",x"4127be",x"44100c",x"46f39e",x"49d1e7",x"4caa7a",x"4f7d0b",x"52496a",
--        x"550f81",x"57cf50",x"5a88ef",x"5d3c86",x"5fea4b",x"629284",x"653580",x"67d396",x"6a6d24",x"69b00e",
--        x"6608a5",x"5fe094",x"579dcb",x"4da19c",x"4247fe",x"35e6f5",x"28ce25",x"1b4683",x"0d9221",x"ffec24",
--        x"f288be",x"e59557",x"d938b5",x"cd933c",x"c2bf43",x"b8d166",x"afd8eb",x"a7e02f",x"a0ed0b",x"9b014b",
--        x"961b1a",x"923574",x"8f4894",x"8d4a5b",x"8c2eba",x"8be811",x"8c6788",x"8d9d68",x"8f7964",x"91eae4",
--        x"94e143",x"984c08",x"9c1b17",x"a03ede",x"a4a876",x"a949c3",x"ae158d",x"b2ff8e",x"b7fc84",x"bd0233",
--        x"c20771",x"c7041d",x"cbf120",x"d0c868",x"d584da",x"da224a",x"de9d6d",x"e2f3c8"
--    );
    
    signal saw_index : INTEGER range 0 to saw_samples - 1 := 0;
    
    constant CLK_FREQ : TIME := 90ns; -- a ~11 MHz son 90.90

    signal clk : STD_LOGIC := '1';
    signal reset, wave_finish : STD_LOGIC := '0';
	signal note_enab : STD_LOGIC := '1';
	
	signal data_in, data_out : SIGNED(BIT_DEPTH - 1 downto 0);
	--signal data_filter : SIGNED(BIT_DEPTH - 1 downto 0);
	
	signal frequency : INTEGER range 0 to 8000 := 800;
	signal resonance : INTEGER range 0 to 100 := 2; -- 2 equivale a una q1 de 1
	
	signal filter_type : INTEGER range 0 to 4 := 1; -- 0: off, 1: lowpass, 2: highpass, 3: bandpass, 4: notch 
    signal filter_lfo : INTEGER range 0 to 1 := 0; -- 0: off, 1: on
    signal filter_lfo_d : INTEGER range 0 to 1 := 0; -- 0: frequency, 1: resonance
    signal lfo3_data : UNSIGNED(23 downto 0) := (others => '0');
    signal lfo3_mode : INTEGER range 0 to 3 := 0; -- 0/1: de 0 a frequency/resonance, 2/3: de 100 a frequency/resonance
    
--    signal sumar : STD_LOGIC := '0';
--    signal waitfor : INTEGER range 0 to 100 := 0;

begin

    uut : Filters port map(
        clock_in => clk,
        reset_in => reset,
        wave_finish => wave_finish,
        note_enable => note_enab,
        frequency => frequency,
        resonance => resonance,
        filter_type => filter_type,
        filter_lfo => filter_lfo,
        filter_lfo_d => filter_lfo_d,
        lfo3_data => lfo3_data,
        lfo3_mode => lfo3_mode,
        data_in => data_in,
        data_out => data_out
    );
    
    clk <= not clk after CLK_FREQ/2;

	process
	begin
		reset <= '0'; -- activa a nivel bajo
		wait for CLK_FREQ;
		reset <= '1';
		
		for i in 0 to 15000 loop
            wave_finish <= '1';
            
            data_in <= data_saw(saw_index);
            --data_filter <= data_sawLP800(saw_index);
            
            if saw_index < saw_samples - 1 then
                saw_index <= saw_index + 1;
            else
                saw_index <= 0;
            end if;
            
            wait for CLK_FREQ;
            wave_finish <= '0';
            
            -- simulando "a mano" una LFO triángulo..
--            if waitfor = 100 then
--                if sumar = '1' then
--                    if frequency = 100 then
--                        sumar <= '0';
--                    else
--                        frequency <= frequency + 1;
--                    end if;
--                else
--                    if frequency = 0 then
--                        sumar <= '1';
--                    else
--                        frequency <= frequency - 1;
--                    end if;
--                end if;
--                waitfor <= 0;
--            else
--                waitfor <= waitfor + 1;
--            end if;
            
--            if i = 5000 then
--                frequency <= 10;
--            elsif i = 7500 then
--                frequency <= 5;
--            end if;
            
            -- eqivale a una LFO sierra, no importa el desbordamiento
            lfo3_data <= lfo3_data + lfo_inc(30);
            
            wait for CLK_FREQ * 255;
		end loop;
		
		wait;
	end process;

end Behavioral;