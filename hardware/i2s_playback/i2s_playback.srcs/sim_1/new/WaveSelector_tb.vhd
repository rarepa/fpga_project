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

entity WaveSelector_tb is
--  Port ( );
end WaveSelector_tb;

architecture Behavioral of WaveSelector_tb is

    COMPONENT WaveSelector is
    Port (
        clock_in     : IN STD_LOGIC;
        word_select  : IN STD_LOGIC;
        reset_in     : IN STD_LOGIC;
        osc1_type    : IN INTEGER range 0 to 3;
        osc2_type    : IN INTEGER range 0 to 3;
        osc1_detune  : IN INTEGER range 0 to 100;
        osc2_detune  : IN INTEGER range 0 to 100;
        osc1_lfo     : IN INTEGER range 0 to 100;
        osc2_lfo     : IN INTEGER range 0 to 100;
        lfo_note     : IN TYPE_LFO_NOTE;
        lfo_type     : IN TYPE_LFO_TYPE;
        lfo_mode     : IN TYPE_LFO_TYPE;
        pulsewidth   : IN TYPE_PULSEW;
        portamento   : IN INTEGER range 0 to 100;
        attack_adsr  : IN INTEGER range 0 to 4095;
        decay_adsr   : IN INTEGER range 0 to 4095;
        sustain_adsr : IN INTEGER range 0 to 100;
        release_adsr : IN INTEGER range 0 to 4095;
        prev_note    : IN TYPE_PREV_NOTE;
        note_code    : IN TYPE_NOTE_CODE;
        pmod_input   : IN INTEGER range 0 to 1;
        note_play    : IN STD_LOGIC_VECTOR(VOICES - 1 downto 0);
        note_enable  : OUT STD_LOGIC_VECTOR(VOICES - 1 downto 0);
        r_data_out   : OUT TYPE_DATA_OUT;
        wave_finish  : OUT STD_LOGIC;
        leds_out     : OUT STD_LOGIC_VECTOR(7 downto 0);
        lfo3_data    : OUT UNSIGNED(23 downto 0)
    );
    end COMPONENT;
    
    constant CLK_FREQ : TIME := 90ns;

    signal clock_in : STD_LOGIC := '1';
    signal reset_in, word_select : STD_LOGIC := '0';
    
    signal osc1_type    : INTEGER range 0 to 3 := 0;
    signal osc2_type    : INTEGER range 0 to 3 := 0;
    signal osc1_detune  : INTEGER range 0 to 100 := 50;
    signal osc2_detune  : INTEGER range 0 to 100 := 50;
    signal osc1_lfo     : INTEGER range 0 to 100 := 100;
    signal osc2_lfo     : INTEGER range 0 to 100 := 0;
    signal lfo_note     : TYPE_LFO_NOTE := (others => 10);
    signal lfo_type     : TYPE_LFO_TYPE := (others => 0);
    signal lfo_mode     : TYPE_LFO_TYPE := (others => 0);
    signal pulsewidth   : TYPE_PULSEW := (others => 0);
    signal portamento   : INTEGER range 0 to 100 := 0;
    signal attack_adsr  : INTEGER range 0 to 4095 := 0;
    signal decay_adsr   : INTEGER range 0 to 4095 := 2000;
    signal sustain_adsr : INTEGER range 0 to 100 := 100;
    signal release_adsr : INTEGER range 0 to 4095 := 10;
    signal prev_note    : TYPE_PREV_NOTE := (others => 64);
    signal note_code    : TYPE_NOTE_CODE := (others => 64);
    signal pmod_input   : INTEGER range 0 to 1 := 0;
    signal note_play    : STD_LOGIC_VECTOR(VOICES - 1 downto 0) := (others => '1');
    signal note_enable  : STD_LOGIC_VECTOR(VOICES - 1 downto 0);
    signal r_data_out   : TYPE_DATA_OUT;
    signal wave_finish  : STD_LOGIC;
    signal leds_out     : STD_LOGIC_VECTOR(7 downto 0);
    signal lfo3_data    : UNSIGNED(23 downto 0);

begin

    uut : WaveSelector port map(
        clock_in => clock_in,
        word_select => word_select,
        reset_in => reset_in,
        osc1_type => osc1_type,
        osc2_type => osc2_type,
        osc1_detune => osc1_detune,
        osc2_detune => osc2_detune,
        osc1_lfo => osc1_lfo,
        osc2_lfo => osc2_lfo,
        lfo_note => lfo_note,
        lfo_type => lfo_type,
        lfo_mode => lfo_mode,
        pulsewidth => pulsewidth,
        portamento => portamento,
        attack_adsr => attack_adsr,
        decay_adsr => decay_adsr,
        sustain_adsr => sustain_adsr,
        release_adsr => release_adsr,
        prev_note => prev_note,
        note_code => note_code,
        pmod_input => pmod_input,
        note_play => note_play,
        note_enable => note_enable,
        r_data_out => r_data_out,
        wave_finish => wave_finish,
        leds_out => leds_out,
        lfo3_data => lfo3_data
    );
    
    process
	begin
--		reset_in <= '0';
--		wait for CLK_FREQ;
--		reset_in <= '1';
		
		wait for CLK_FREQ;
		
		for i in 0 to 15000 loop
		    word_select <= '1';
		    wait for CLK_FREQ;
            word_select <= '0';
            
            wait for CLK_FREQ * 256;
		end loop;
		
		wait;
	end process;

end Behavioral;