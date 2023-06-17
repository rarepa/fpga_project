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

entity Synchronize is
    Port (
        clock_in      : IN STD_LOGIC;
        synch_start   : IN STD_LOGIC;
        tx_ready      : IN STD_LOGIC;
        osc1_type     : IN INTEGER range 0 to 3;
        osc2_type     : IN INTEGER range 0 to 3;
        osc1_semitone : IN INTEGER range -12 to 12;
        osc2_semitone : IN INTEGER range -12 to 12;
        osc1_detune   : IN INTEGER range 0 to 100;
        osc2_detune   : IN INTEGER range 0 to 100;
        osc1_lfo      : IN INTEGER range 0 to 100;
        osc2_lfo      : IN INTEGER range 0 to 100;
        osc1_volume   : IN INTEGER range 0 to 100;
        osc2_volume   : IN INTEGER range 0 to 100;
        lfo_note      : IN TYPE_LFO_NOTE;
        lfo_type      : IN TYPE_LFO_TYPE;
        lfo_mode      : IN TYPE_LFO_TYPE;
        pulsewidth    : IN TYPE_PULSEW;
        portamento    : IN INTEGER range 0 to 100;
        master_volume : IN INTEGER range 0 to 100;
        attack_time   : IN INTEGER range 0 to 10;
        decay_time    : IN INTEGER range 0 to 10;
        release_time  : IN INTEGER range 0 to 10;
        attack_adsr   : IN INTEGER range 0 to 100;
        decay_adsr    : IN INTEGER range 0 to 100;
        sustain_adsr  : IN INTEGER range 0 to 100;
        release_adsr  : IN INTEGER range 0 to 100;
        filter_freq   : IN INTEGER range 0 to 8000;
        filter_q      : IN INTEGER range 0 to 100;
        filter_type   : IN INTEGER range 0 to 4;
        filter_lfo    : IN INTEGER range 0 to 1;
        filter_lfo_d  : IN INTEGER range 0 to 1;
        noise_volume  : IN INTEGER range 0 to 100;
        pmod_input    : IN INTEGER range 0 to 1;
        tx_start      : OUT STD_LOGIC;
--        leds_out      : OUT STD_LOGIC_VECTOR(7 downto 0);
        data_out      : OUT STD_LOGIC_VECTOR(7 downto 0)
    );
end Synchronize;

architecture Behavioral of Synchronize is

    type send_state is (
        s_init, s_wait_cycle, s_master_volume,
        s_attack, s_decay, s_sustain, s_release, s_attack_time, s_decay_time, s_release_time,
        s_filter_freq, s_filter_q, s_filter_LFO, s_filter_type,
        s_noise_volume, s_pmod_input,
        s_LFO1_type, s_LFO1_speed, s_LFO2_type, s_LFO2_speed, s_LFO1_mode, s_LFO2_mode,
        s_LFO3_type, s_LFO3_speed, s_LFO3_mode, s_LFO3_destination,
        s_osc1_type, s_osc1_volume, s_osc1_semitone, s_osc1_detune, s_osc1_LFO, s_osc1_pulse,
        s_osc2_type, s_osc2_volume, s_osc2_semitone, s_osc2_detune, s_osc2_LFO, s_osc2_pulse,
        s_portamento_d, s_master_volume_d,
        s_attack_d, s_decay_d, s_sustain_d, s_release_d, s_attack_time_d, s_decay_time_d, s_release_time_d,
        s_filter_freq_b0, s_filter_freq_b1, s_filter_q_d, s_filter_LFO_d, s_filter_type_d,
        s_noise_volume_d, s_pmod_input_d,
        s_LFO1_type_d, s_LFO1_speed_d, s_LFO2_type_d, s_LFO2_speed_d, s_LFO1_mode_d, s_LFO2_mode_d,
        s_LFO3_type_d, s_LFO3_speed_d, s_LFO3_mode_d, s_LFO3_destination_d,
        s_osc1_type_d, s_osc1_volume_d, s_osc1_semitone_d, s_osc1_detune_d, s_osc1_LFO_d, s_osc1_pulse_d,
        s_osc2_type_d, s_osc2_volume_d, s_osc2_semitone_d, s_osc2_detune_d, s_osc2_LFO_d, s_osc2_pulse_d);
    signal state, nextstate : send_state := s_init;
    
    signal filter_frequency : STD_LOGIC_VECTOR(15 downto 0);
    
    signal start : STD_LOGIC := '0';

begin

    filter_frequency <= std_logic_vector(to_unsigned(filter_freq, 16));
    
    process(clock_in)
    begin
        if rising_edge(clock_in) then
            if synch_start = '1' then
                start <= '1';
            end if;
            
            tx_start <= '0';
            if tx_ready = '1' then
                case(state) is
                when s_init =>
                    if start = '1' then
                        state <= s_wait_cycle;
                        nextstate <= s_portamento_d;
                        data_out <= x"21";
                        tx_start <= '1';
                        start <= '0';
                    end if;
                when s_wait_cycle =>
                    state <= nextstate;
                when s_portamento_d =>
                    tx_start <= '1';
                    data_out <= std_logic_vector(to_unsigned(portamento, data_out'length));
                    state <= s_wait_cycle;
                    nextstate <= s_master_volume;
                when s_master_volume =>
                    tx_start <= '1';
                    data_out <= x"05";
                    state <= s_wait_cycle;
                    nextstate <= s_master_volume_d;
                when s_master_volume_d =>
                    tx_start <= '1';
                    data_out <= std_logic_vector(to_unsigned(master_volume, data_out'length));
                    state <= s_wait_cycle;
                    nextstate <= s_attack;
                when s_attack =>
                    tx_start <= '1';
                    data_out <= x"06";
                    state <= s_wait_cycle;
                    nextstate <= s_attack_d;
                when s_attack_d =>
                    tx_start <= '1';
                    data_out <= std_logic_vector(to_unsigned(attack_adsr, data_out'length));
                    state <= s_wait_cycle;
                    nextstate <= s_decay;
                when s_decay =>
                    tx_start <= '1';
                    data_out <= x"07";
                    state <= s_wait_cycle;
                    nextstate <= s_decay_d;
                when s_decay_d =>
                    tx_start <= '1';
                    data_out <= std_logic_vector(to_unsigned(decay_adsr, data_out'length));
                    state <= s_wait_cycle;
                    nextstate <= s_sustain;
                when s_sustain =>
                    tx_start <= '1';
                    data_out <= x"08";
                    state <= s_wait_cycle;
                    nextstate <= s_sustain_d;
                when s_sustain_d =>
                    tx_start <= '1';
                    data_out <= std_logic_vector(to_unsigned(sustain_adsr, data_out'length));
                    state <= s_wait_cycle;
                    nextstate <= s_release;
                when s_release =>
                    tx_start <= '1';
                    data_out <= x"09";
                    state <= s_wait_cycle;
                    nextstate <= s_release_d;
                when s_release_d =>
                    tx_start <= '1';
                    data_out <= std_logic_vector(to_unsigned(release_adsr, data_out'length));
                    state <= s_wait_cycle;
                    nextstate <= s_attack_time;
                when s_attack_time =>
                    tx_start <= '1';
                    data_out <= x"0A";
                    state <= s_wait_cycle;
                    nextstate <= s_attack_time_d;
                when s_attack_time_d =>
                    tx_start <= '1';
                    data_out <= std_logic_vector(to_unsigned(attack_time, data_out'length));
                    state <= s_wait_cycle;
                    nextstate <= s_decay_time;
                when s_decay_time =>
                    tx_start <= '1';
                    data_out <= x"0B";
                    state <= s_wait_cycle;
                    nextstate <= s_decay_time_d;
                when s_decay_time_d =>
                    tx_start <= '1';
                    data_out <= std_logic_vector(to_unsigned(decay_time, data_out'length));
                    state <= s_wait_cycle;
                    nextstate <= s_release_time;
                when s_release_time =>
                    tx_start <= '1';
                    data_out <= x"0C";
                    state <= s_wait_cycle;
                    nextstate <= s_release_time_d;
                when s_release_time_d =>
                    tx_start <= '1';
                    data_out <= std_logic_vector(to_unsigned(release_time, data_out'length));
                    state <= s_wait_cycle;
                    nextstate <= s_filter_freq;
                when s_filter_freq =>
                    tx_start <= '1';
                    data_out <= x"0D";
                    state <= s_wait_cycle;
                    nextstate <= s_filter_freq_b0;
                when s_filter_freq_b0 =>
                    tx_start <= '1';
                    data_out <= filter_frequency(7 downto 0);
                    state <= s_wait_cycle;
                    nextstate <= s_filter_freq_b1;
                when s_filter_freq_b1 =>
                    tx_start <= '1';
                    data_out <= filter_frequency(15 downto 8);
                    state <= s_wait_cycle;
                    nextstate <= s_filter_q;
                when s_filter_q =>
                    tx_start <= '1';
                    data_out <= x"0E";
                    state <= s_wait_cycle;
                    nextstate <= s_filter_q_d;
                when s_filter_q_d =>
                    tx_start <= '1';
                    data_out <= std_logic_vector(to_unsigned(filter_q, data_out'length));
                    state <= s_wait_cycle;
                    nextstate <= s_filter_LFO;
                when s_filter_LFO =>
                    tx_start <= '1';
                    data_out <= x"0F";
                    state <= s_wait_cycle;
                    nextstate <= s_filter_LFO_d;
                when s_filter_LFO_d =>
                    tx_start <= '1';
                    data_out <= std_logic_vector(to_unsigned(filter_lfo, data_out'length));
                    state <= s_wait_cycle;
                    nextstate <= s_filter_type;
                when s_filter_type =>
                    tx_start <= '1';
                    data_out <= x"10";
                    state <= s_wait_cycle;
                    nextstate <= s_filter_type_d;
                when s_filter_type_d =>
                    tx_start <= '1';
                    data_out <= std_logic_vector(to_unsigned(filter_type, data_out'length));
                    state <= s_wait_cycle;
                    nextstate <= s_noise_volume;
                when s_noise_volume =>
                    tx_start <= '1';
                    data_out <= x"15";
                    state <= s_wait_cycle;
                    nextstate <= s_noise_volume_d;
                when s_noise_volume_d =>
                    tx_start <= '1';
                    data_out <= std_logic_vector(to_unsigned(noise_volume, data_out'length));
                    state <= s_wait_cycle;
                    nextstate <= s_pmod_input;
                when s_pmod_input =>
                    tx_start <= '1';
                    data_out <= x"16";
                    state <= s_wait_cycle;
                    nextstate <= s_pmod_input_d;
                when s_pmod_input_d =>
                    tx_start <= '1';
                    data_out <= std_logic_vector(to_unsigned(pmod_input, data_out'length));
                    state <= s_wait_cycle;
                    nextstate <= s_LFO1_type;
                when s_LFO1_type =>
                    tx_start <= '1';
                    data_out <= x"11";
                    state <= s_wait_cycle;
                    nextstate <= s_LFO1_type_d;
                when s_LFO1_type_d =>
                    tx_start <= '1';
                    data_out <= std_logic_vector(to_unsigned(lfo_type(0), data_out'length));
                    state <= s_wait_cycle;
                    nextstate <= s_LFO1_speed;
                when s_LFO1_speed =>
                    tx_start <= '1';
                    data_out <= x"12";
                    state <= s_wait_cycle;
                    nextstate <= s_LFO1_speed_d;
                when s_LFO1_speed_d =>
                    tx_start <= '1';
                    data_out <= std_logic_vector(to_unsigned(lfo_note(0), data_out'length));
                    state <= s_wait_cycle;
                    nextstate <= s_LFO2_type;
                when s_LFO2_type =>
                    tx_start <= '1';
                    data_out <= x"13";
                    state <= s_wait_cycle;
                    nextstate <= s_LFO2_type_d;
                when s_LFO2_type_d =>
                    tx_start <= '1';
                    data_out <= std_logic_vector(to_unsigned(lfo_type(1), data_out'length));
                    state <= s_wait_cycle;
                    nextstate <= s_LFO2_speed;
                when s_LFO2_speed =>
                    tx_start <= '1';
                    data_out <= x"14";
                    state <= s_wait_cycle;
                    nextstate <= s_LFO2_speed_d;
                when s_LFO2_speed_d =>
                    tx_start <= '1';
                    data_out <= std_logic_vector(to_unsigned(lfo_note(1), data_out'length));
                    state <= s_wait_cycle;
                    nextstate <= s_LFO1_mode;
                when s_LFO1_mode =>
                    tx_start <= '1';
                    data_out <= x"22";
                    state <= s_wait_cycle;
                    nextstate <= s_LFO1_mode_d;
                when s_LFO1_mode_d =>
                    tx_start <= '1';
                    data_out <= std_logic_vector(to_unsigned(lfo_mode(0), data_out'length));
                    state <= s_wait_cycle;
                    nextstate <= s_LFO2_mode;
                when s_LFO2_mode =>
                    tx_start <= '1';
                    data_out <= x"23";
                    state <= s_wait_cycle;
                    nextstate <= s_LFO2_mode_d;
                when s_LFO2_mode_d =>
                    tx_start <= '1';
                    data_out <= std_logic_vector(to_unsigned(lfo_mode(1), data_out'length));
                    state <= s_wait_cycle;
                    nextstate <= s_LFO3_type;
                when s_LFO3_type =>
                    tx_start <= '1';
                    data_out <= x"36";
                    state <= s_wait_cycle;
                    nextstate <= s_LFO3_type_d;
                when s_LFO3_type_d =>
                    tx_start <= '1';
                    data_out <= std_logic_vector(to_unsigned(lfo_type(2), data_out'length));
                    state <= s_wait_cycle;
                    nextstate <= s_LFO3_speed;
                when s_LFO3_speed =>
                    tx_start <= '1';
                    data_out <= x"37";
                    state <= s_wait_cycle;
                    nextstate <= s_LFO3_speed_d;
                when s_LFO3_speed_d =>
                    tx_start <= '1';
                    data_out <= std_logic_vector(to_unsigned(lfo_note(2), data_out'length));
                    state <= s_wait_cycle;
                    nextstate <= s_LFO3_mode;
                when s_LFO3_mode =>
                    tx_start <= '1';
                    data_out <= x"38";
                    state <= s_wait_cycle;
                    nextstate <= s_LFO3_mode_d;
                when s_LFO3_mode_d =>
                    tx_start <= '1';
                    data_out <= std_logic_vector(to_unsigned(lfo_mode(2), data_out'length));
                    state <= s_wait_cycle;
                    nextstate <= s_LFO3_destination;
                when s_LFO3_destination =>
                    tx_start <= '1';
                    data_out <= x"39";
                    state <= s_wait_cycle;
                    nextstate <= s_LFO3_destination_d;
                when s_LFO3_destination_d =>
                    tx_start <= '1';
                    data_out <= std_logic_vector(to_unsigned(filter_lfo_d, data_out'length));
                    state <= s_wait_cycle;
                    nextstate <= s_osc1_type;
                when s_osc1_type =>
                    tx_start <= '1';
                    data_out <= x"17";
                    state <= s_wait_cycle;
                    nextstate <= s_osc1_type_d;
                when s_osc1_type_d =>
                    tx_start <= '1';
                    data_out <= std_logic_vector(to_unsigned(osc1_type, data_out'length));
                    state <= s_wait_cycle;
                    nextstate <= s_osc1_volume;
                when s_osc1_volume =>
                    tx_start <= '1';
                    data_out <= x"18";
                    state <= s_wait_cycle;
                    nextstate <= s_osc1_volume_d;
                when s_osc1_volume_d =>
                    tx_start <= '1';
                    data_out <= std_logic_vector(to_unsigned(osc1_volume, data_out'length));
                    state <= s_wait_cycle;
                    nextstate <= s_osc1_semitone;
                when s_osc1_semitone =>
                    tx_start <= '1';
                    data_out <= x"19";
                    state <= s_wait_cycle;
                    nextstate <= s_osc1_semitone_d;
                when s_osc1_semitone_d =>
                    tx_start <= '1';
                    data_out <= std_logic_vector(to_signed(osc1_semitone, data_out'length));
                    state <= s_wait_cycle;
                    nextstate <= s_osc1_detune;
                when s_osc1_detune =>
                    tx_start <= '1';
                    data_out <= x"1A";
                    state <= s_wait_cycle;
                    nextstate <= s_osc1_detune_d;
                when s_osc1_detune_d =>
                    tx_start <= '1';
                    data_out <= std_logic_vector(to_unsigned(osc1_detune, data_out'length));
                    state <= s_wait_cycle;
                    nextstate <= s_osc1_LFO;
                when s_osc1_LFO =>
                    tx_start <= '1';
                    data_out <= x"1B";
                    state <= s_wait_cycle;
                    nextstate <= s_osc1_LFO_d;
                when s_osc1_LFO_d =>
                    tx_start <= '1';
                    data_out <= std_logic_vector(to_unsigned(osc1_lfo, data_out'length));
                    state <= s_wait_cycle;
                    nextstate <= s_osc1_pulse;
                when s_osc1_pulse =>
                    tx_start <= '1';
                    data_out <= x"34";
                    state <= s_wait_cycle;
                    nextstate <= s_osc1_pulse_d;
                when s_osc1_pulse_d =>
                    tx_start <= '1';
                    data_out <= std_logic_vector(to_unsigned(pulsewidth(0), data_out'length));
                    state <= s_wait_cycle;
                    nextstate <= s_osc2_type;
                when s_osc2_type =>
                    tx_start <= '1';
                    data_out <= x"1C";
                    state <= s_wait_cycle;
                    nextstate <= s_osc2_type_d;
                when s_osc2_type_d =>
                    tx_start <= '1';
                    data_out <= std_logic_vector(to_unsigned(osc2_type, data_out'length));
                    state <= s_wait_cycle;
                    nextstate <= s_osc2_volume;
                when s_osc2_volume =>
                    tx_start <= '1';
                    data_out <= x"1D";
                    state <= s_wait_cycle;
                    nextstate <= s_osc2_volume_d;
                when s_osc2_volume_d =>
                    tx_start <= '1';
                    data_out <= std_logic_vector(to_unsigned(osc2_volume, data_out'length));
                    state <= s_wait_cycle;
                    nextstate <= s_osc2_semitone;
                when s_osc2_semitone =>
                    tx_start <= '1';
                    data_out <= x"1E";
                    state <= s_wait_cycle;
                    nextstate <= s_osc2_semitone_d;
                when s_osc2_semitone_d =>
                    tx_start <= '1';
                    data_out <= std_logic_vector(to_signed(osc2_semitone, data_out'length));
                    state <= s_wait_cycle;
                    nextstate <= s_osc2_detune;
                when s_osc2_detune =>
                    tx_start <= '1';
                    data_out <= x"1F";
                    state <= s_wait_cycle;
                    nextstate <= s_osc2_detune_d;
                when s_osc2_detune_d =>
                    tx_start <= '1';
                    data_out <= std_logic_vector(to_unsigned(osc2_detune, data_out'length));
                    state <= s_wait_cycle;
                    nextstate <= s_osc2_LFO;
                when s_osc2_LFO =>
                    tx_start <= '1';
                    data_out <= x"20";
                    state <= s_wait_cycle;
                    nextstate <= s_osc2_LFO_d;
                when s_osc2_LFO_d =>
                    tx_start <= '1';
                    data_out <= std_logic_vector(to_unsigned(osc2_lfo, data_out'length));
                    state <= s_wait_cycle;
                    nextstate <= s_osc2_pulse;
                when s_osc2_pulse =>
                    tx_start <= '1';
                    data_out <= x"35";
                    state <= s_wait_cycle;
                    nextstate <= s_osc2_pulse_d;
                when s_osc2_pulse_d =>
                    tx_start <= '1';
                    data_out <= std_logic_vector(to_unsigned(pulsewidth(1), data_out'length));
                    state <= s_wait_cycle;
                    nextstate <= s_init;
                end case;
            end if;
        end if;
    end process;

end Behavioral;