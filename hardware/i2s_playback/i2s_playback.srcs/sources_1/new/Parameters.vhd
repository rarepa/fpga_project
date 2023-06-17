library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

use work.my_pack.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity Parameters is
    Port (
        clock_in        : IN STD_LOGIC;
        rx_ready        : IN STD_LOGIC;
        data_in         : IN STD_LOGIC_VECTOR(7 downto 0);
        note_enable     : IN STD_LOGIC_VECTOR(VOICES - 1 downto 0);
        osc1_type       : OUT INTEGER range 0 to 3 := 0;
        osc2_type       : OUT INTEGER range 0 to 3 := 0;
        osc1_semitone_o : OUT INTEGER range -12 to 12 := 0;
        osc2_semitone_o : OUT INTEGER range -12 to 12 := 0;
        osc1_volume     : OUT INTEGER range 0 to 100 := 100;
        osc2_volume     : OUT INTEGER range 0 to 100 := 100;
        osc1_detune     : OUT INTEGER range 0 to 100 := 50;
        osc2_detune     : OUT INTEGER range 0 to 100 := 50;
        osc1_lfo        : OUT INTEGER range 0 to 100 := 0;
        osc2_lfo        : OUT INTEGER range 0 to 100 := 0;
        lfo_note        : OUT TYPE_LFO_NOTE := (0 => 32, 1 => 64, 2 => 10);
        lfo_type        : OUT TYPE_LFO_TYPE := (others => 0);
        lfo_mode        : OUT TYPE_LFO_TYPE := (others => 0);
        pulsewidth      : OUT TYPE_PULSEW := (others => 50);
        portamento      : OUT INTEGER range 0 to 100 := 0;
        master_volume   : OUT INTEGER range 0 to 100 := 100;
        attack_time_o   : OUT INTEGER range 0 to 10;
        decay_time_o    : OUT INTEGER range 0 to 10;
        release_time_o  : OUT INTEGER range 0 to 10;
        attack_value_o  : OUT INTEGER range 0 to 100;
        decay_value_o   : OUT INTEGER range 0 to 100;
        release_value_o : OUT INTEGER range 0 to 100;
        attack_adsr     : OUT INTEGER range 0 to 4095 := 0;
        decay_adsr      : OUT INTEGER range 0 to 4095 := 1000;
        sustain_adsr    : OUT INTEGER range 0 to 100 := 0;
        release_adsr    : OUT INTEGER range 0 to 4095 := 20;
        prev_note_o     : OUT TYPE_PREV_NOTE := (others => 0);
        note_code_o     : OUT TYPE_NOTE_CODE;
        note_play       : OUT STD_LOGIC_VECTOR(VOICES - 1 downto 0);
        filter_freq     : OUT INTEGER range 0 to 8000 := 8000;
        filter_q        : OUT INTEGER range 0 to 100 := 3;
        filter_type     : OUT INTEGER range 0 to 4 := 0;
        filter_lfo      : OUT INTEGER range 0 to 1 := 0;
        filter_lfo_d    : OUT INTEGER range 0 to 1 := 0;
        noise_volume    : OUT INTEGER range 0 to 100 := 0;
        pmod_input      : OUT INTEGER range 0 to 1 := 0;
--        leds_out        : OUT STD_LOGIC_VECTOR(7 downto 0);
        synch_start     : OUT STD_LOGIC := '0'
    );
end Parameters;

architecture Behavioral of Parameters is

    signal note_code : TYPE_NOTE_CODE := (others => 64);
    
    signal scale : INTEGER range 0 to 9 := 3;
    type POLYTYPE is array (0 to (VOICES / 2) - 1) of STD_LOGIC_VECTOR(7 downto 0);
    signal polynote : POLYTYPE := (others => (others=>'0'));
    signal POLYNOTE_ZEROS : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
    
    signal attack_time, decay_time, release_time : INTEGER range 0 to 10 := 5;
    constant adsr_mult : INTEGER range 0 to 4 := 4; -- a MAX of 4000 that fits in 4095
    signal attack_value : INTEGER range 0 to 100 := 0;
    signal decay_value : INTEGER range 0 to 100 := 50;
    signal release_value : INTEGER range 0 to 100 := 1;
    
    signal filter_freq_b0 : UNSIGNED(7 downto 0);
    
    signal osc1_semitone, osc2_semitone,
           last_semitone1, last_semitone2 : INTEGER range -12 to 12 := 0;
    
    type uart_state is (s_init, s_note_release, s_portamento, s_master_volume,
        s_attack, s_decay, s_sustain, s_release, s_attack_time, s_decay_time, s_release_time,
        s_filter_freq_b0, s_filter_freq_b1, s_filter_q, s_filter_LFO, s_filter_type,
        s_noise_volume, s_pmod_input,
        s_LFO1_type, s_LFO1_speed, s_LFO2_type, s_LFO2_speed, s_LFO1_mode, s_LFO2_mode,
        s_LFO3_type, s_LFO3_speed, s_LFO3_mode, s_LFO3_destination,
        s_osc1_type, s_osc1_volume, s_osc1_semitone, s_osc1_detune, s_osc1_LFO, s_osc1_pulse,
        s_osc2_type, s_osc2_volume, s_osc2_semitone, s_osc2_detune, s_osc2_LFO, s_osc2_pulse);
    signal state : uart_state := s_init;

begin

    note_code_o <= note_code;
    
    attack_time_o <= attack_time;
    decay_time_o <= decay_time;
    release_time_o <= release_time;
    
    attack_value_o <= attack_value;
    decay_value_o <= decay_value;
    release_value_o <= release_value;
    
    osc1_semitone_o <= osc1_semitone;
    osc2_semitone_o <= osc2_semitone;
    
--    leds_out <= data_in;
    
    process(clock_in)
        variable note_code_aux1, note_code_aux2 : TYPE_NOTE_CODE;
    begin
        if rising_edge(clock_in) then
            synch_start <= '0';
            if rx_ready = '1' then
                case(state) is
                when s_note_release =>
                    for ii in 0 to VOICES/2 - 1 loop
                        if polynote(ii) = data_in then
                            note_play(ii) <= '0';
                            note_play(ii + VOICES/2) <= '0';
                            polynote(ii) <= (others => '0');
                        end if;
                    end loop;
                    state <= s_init;
                when s_portamento =>
                    portamento <= to_integer(unsigned(data_in));
                    state <= s_init;
                when s_master_volume =>
                    master_volume <= to_integer(unsigned(data_in));
                    state <= s_init;
                when s_attack =>
                    attack_value <= to_integer(unsigned(data_in));
                    attack_adsr <= to_integer(unsigned(data_in)) * attack_time * adsr_mult;
                    state <= s_init;
                when s_decay =>
                    decay_value <= to_integer(unsigned(data_in));
                    decay_adsr <= to_integer(unsigned(data_in)) * decay_time * adsr_mult;
                    state <= s_init;
                when s_sustain =>
                    sustain_adsr <= to_integer(unsigned(data_in));
                    state <= s_init;
                when s_release =>
                    release_value <= to_integer(unsigned(data_in));
                    release_adsr <= to_integer(unsigned(data_in)) * release_time * adsr_mult;
                    state <= s_init;
                when s_attack_time =>
                    attack_time <= to_integer(unsigned(data_in));
                    attack_adsr <= attack_value * to_integer(unsigned(data_in)) * adsr_mult;
                    state <= s_init;
                when s_decay_time =>
                    decay_time <= to_integer(unsigned(data_in));
                    decay_adsr <= decay_value * to_integer(unsigned(data_in)) * adsr_mult;
                    state <= s_init;
                when s_release_time =>
                    release_time <= to_integer(unsigned(data_in));
                    release_adsr <= release_value * to_integer(unsigned(data_in)) * adsr_mult;
                    state <= s_init;
                when s_filter_freq_b0 =>
                    filter_freq_b0 <= unsigned(data_in);
                    state <= s_filter_freq_b1;
                when s_filter_freq_b1 =>
                    filter_freq <= to_integer(unsigned(data_in) & unsigned(filter_freq_b0));
                    state <= s_init;
                when s_filter_q =>
                    filter_q <= to_integer(unsigned(data_in));
                    state <= s_init;
                when s_filter_LFO =>
                    filter_lfo <= to_integer(unsigned(data_in));
                    state <= s_init;
                when s_filter_type =>
                    filter_type <= to_integer(unsigned(data_in));
                    state <= s_init;
                when s_LFO1_type =>
                    lfo_type(0) <= to_integer(unsigned(data_in));
                    state <= s_init;
                when s_LFO1_speed =>
                    lfo_note(0) <= to_integer(unsigned(data_in));
                    state <= s_init;
                when s_LFO1_mode =>
                    lfo_mode(0) <= to_integer(unsigned(data_in));
                    state <= s_init;
                when s_LFO2_type =>
                    lfo_type(1) <= to_integer(unsigned(data_in));
                    state <= s_init;
                when s_LFO2_speed =>
                    lfo_note(1) <= to_integer(unsigned(data_in));
                    state <= s_init;
                when s_LFO2_mode =>
                    lfo_mode(1) <= to_integer(unsigned(data_in));
                    state <= s_init;
                when s_LFO3_type =>
                    lfo_type(2) <= to_integer(unsigned(data_in));
                    state <= s_init;
                when s_LFO3_speed =>
                    lfo_note(2) <= to_integer(unsigned(data_in));
                    state <= s_init;
                when s_LFO3_mode =>
                    lfo_mode(2) <= to_integer(unsigned(data_in));
                    state <= s_init;
                when s_LFO3_destination =>
                    filter_lfo_d <= to_integer(unsigned(data_in));
                    state <= s_init;
                when s_noise_volume =>
                    noise_volume <= to_integer(unsigned(data_in));
                    state <= s_init;
                when s_pmod_input =>
                    pmod_input <= to_integer(unsigned(data_in));
                    state <= s_init;
                when s_osc1_type =>
                    osc1_type <= to_integer(unsigned(data_in));
                    state <= s_init;
                when s_osc1_volume =>
                    osc1_volume <= to_integer(unsigned(data_in));
                    state <= s_init;
                when s_osc1_semitone =>
                    osc1_semitone <= to_integer(signed(data_in));
                    for ii in 0 to VOICES/2 - 1 loop
                        if note_enable(ii) = '1' then
                            note_code_aux1(ii) := note_code(ii) + to_integer(signed(data_in)) - last_semitone1;
                            if note_code_aux1(ii) > 0 AND note_code_aux1(ii) < 128 then
                                note_code(ii) <= note_code_aux1(ii);
                                last_semitone1 <= to_integer(signed(data_in));
                            end if;
                        end if;
                    end loop;
                    state <= s_init;
                when s_osc1_detune =>
                    osc1_detune <= to_integer(unsigned(data_in));
                    state <= s_init;
                when s_osc1_LFO =>
                    osc1_lfo <= to_integer(unsigned(data_in));
                    state <= s_init;
                when s_osc1_pulse =>
                    pulsewidth(0) <= to_integer(unsigned(data_in));
                    state <= s_init;
                when s_osc2_type =>
                    osc2_type <= to_integer(unsigned(data_in));
                    state <= s_init;
                when s_osc2_volume =>
                    osc2_volume <= to_integer(unsigned(data_in));
                    state <= s_init;
                when s_osc2_semitone =>
                    osc2_semitone <= to_integer(signed(data_in));
                    for ii in VOICES/2 to VOICES - 1 loop
                        if note_enable(ii) = '1' then
                            note_code_aux2(ii) := note_code(ii) + to_integer(signed(data_in)) - last_semitone2;
                            if note_code_aux2(ii) > 0 AND note_code_aux2(ii) < 128 then
                                note_code(ii) <= note_code_aux2(ii);
                                last_semitone2 <= to_integer(signed(data_in));
                            end if;
                        end if;
                    end loop;
                    state <= s_init;
                when s_osc2_detune =>
                    osc2_detune <= to_integer(unsigned(data_in));
                    state <= s_init;
                when s_osc2_LFO =>
                    osc2_lfo <= to_integer(unsigned(data_in));
                    state <= s_init;
                when s_osc2_pulse =>
                    pulsewidth(1) <= to_integer(unsigned(data_in));
                    state <= s_init;
                when s_init =>
                    if data_in = x"01" then
                        synch_start <= '1';
                    elsif data_in = x"02" then
                        if scale > 0 then
                            scale <= scale - 1;
                        end if;
                    elsif data_in = x"03" then
                        if scale < 9 then
                            scale <= scale + 1;
                        end if;
                    elsif data_in = x"04" then
                        state <= s_note_release;
                    elsif data_in = x"05" then
                        state <= s_master_volume;
                    elsif data_in = x"06" then
                        state <= s_attack;
                    elsif data_in = x"07" then
                        state <= s_decay;
                    elsif data_in = x"08" then
                        state <= s_sustain;
                    elsif data_in = x"09" then
                        state <= s_release;
                    elsif data_in = x"0A" then
                        state <= s_attack_time;
                    elsif data_in = x"0B" then
                        state <= s_decay_time;
                    elsif data_in = x"0C" then
                        state <= s_release_time;
                    elsif data_in = x"0D" then
                        state <= s_filter_freq_b0;
                    elsif data_in = x"0E" then
                        state <= s_filter_q;
                    elsif data_in = x"0F" then
                        state <= s_filter_LFO;
                    elsif data_in = x"10" then
                        state <= s_filter_type;
                    elsif data_in = x"11" then
                        state <= s_LFO1_type;
                    elsif data_in = x"12" then
                        state <= s_LFO1_speed;
                    elsif data_in = x"13" then
                        state <= s_LFO2_type;
                    elsif data_in = x"14" then
                        state <= s_LFO2_speed;
                    elsif data_in = x"15" then
                        state <= s_noise_volume;
                    elsif data_in = x"16" then
                        state <= s_pmod_input;
                    elsif data_in = x"17" then
                        state <= s_osc1_type;
                    elsif data_in = x"18" then
                        state <= s_osc1_volume;
                    elsif data_in = x"19" then
                        state <= s_osc1_semitone;
                    elsif data_in = x"1A" then
                        state <= s_osc1_detune;
                    elsif data_in = x"1B" then
                        state <= s_osc1_LFO;
                    elsif data_in = x"1C" then
                        state <= s_osc2_type;
                    elsif data_in = x"1D" then
                        state <= s_osc2_volume;
                    elsif data_in = x"1E" then
                        state <= s_osc2_semitone;
                    elsif data_in = x"1F" then
                        state <= s_osc2_detune;
                    elsif data_in = x"20" then
                        state <= s_osc2_LFO;
                    elsif data_in = x"21" then
                        state <= s_portamento;
                    elsif data_in = x"22" then
                        state <= s_LFO1_mode;
                    elsif data_in = x"23" then
                        state <= s_LFO2_mode;
                    elsif data_in = x"34" then
                        state <= s_osc1_pulse;
                    elsif data_in = x"35" then
                        state <= s_osc2_pulse;
                    elsif data_in = x"36" then
                        state <= s_LFO3_type;
                    elsif data_in = x"37" then
                        state <= s_LFO3_speed;
                    elsif data_in = x"38" then
                        state <= s_LFO3_mode;
                    elsif data_in = x"39" then
                        state <= s_LFO3_destination;
                    elsif (data_in > x"23" AND data_in < x"2C") OR
                        (data_in > x"2B" AND data_in < x"30" AND scale < 9) OR
                        (data_in > x"2F" AND data_in < x"33" AND scale < 8) OR
                        (data_in > x"7F" AND data_in <= x"FF") then
                        for ii in 0 to VOICES/2 - 1 loop
                            if polynote(ii) = POLYNOTE_ZEROS then
                                note_code_aux1(ii) := 0;
                                note_code_aux2(ii) := 0;
                                if polynote(ii) > x"7F" then -- MIDI hardware
                                    note_code_aux1(ii) := to_integer(unsigned(data_in)) - 128 + osc1_semitone;
                                    note_code_aux2(ii) := to_integer(unsigned(data_in)) - 128 + osc2_semitone;
                                else -- pc keyboard
                                    note_code_aux1(ii) := to_integer(unsigned(data_in)) + 12 * (scale-1) + osc1_semitone;
                                    note_code_aux2(ii) := to_integer(unsigned(data_in)) + 12 * (scale-1) + osc2_semitone;
                                end if;
                                
                                if note_code_aux1(ii) > 0 AND note_code_aux1(ii) < 128 then
                                    note_code(ii) <= note_code_aux1(ii);
                                    prev_note_o(0) <= note_code(ii);
                                    note_play(ii) <= '1';
                                    polynote(ii) <= data_in;
                                end if;
                                
                                if note_code_aux2(ii) > 0 AND note_code_aux2(ii) < 128 then
                                    note_code(ii + VOICES/2) <= note_code_aux2(ii);
                                    prev_note_o(1) <= note_code(ii + VOICES/2);
                                    note_play(ii + VOICES/2) <= '1';
                                    polynote(ii) <= data_in;
                                end if;
                                exit;
                            end if;
                        end loop;
                    end if;
                end case;
            end if;
        end if;
    end process;

end Behavioral;