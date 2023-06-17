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

entity Synthesizer is
    Port (
        clock_in      : IN STD_LOGIC;
        word_select   : IN STD_LOGIC;
        reset_in      : IN STD_LOGIC;
        uart_data_in  : IN STD_LOGIC_VECTOR(7 downto 0);
        rx_ready      : IN STD_LOGIC;
        tx_ready      : IN STD_LOGIC;
        tx_start      : OUT STD_LOGIC;
        uart_data_out : OUT STD_LOGIC_VECTOR(7 downto 0);
        leds_out      : OUT STD_LOGIC_VECTOR(7 downto 0);
        l_data_rx     : IN STD_LOGIC_VECTOR(BIT_DEPTH - 1 downto 0);
        r_data_rx     : IN STD_LOGIC_VECTOR(BIT_DEPTH - 1 downto 0);
        l_data_out    : OUT SIGNED(BIT_DEPTH - 1 downto 0);
        r_data_out    : OUT SIGNED(BIT_DEPTH - 1 downto 0)
    );
end Synthesizer;

architecture Behavioral of Synthesizer is

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
    
    COMPONENT Parameters is
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
    end COMPONENT;
    
    COMPONENT Synchronize is
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
    end COMPONENT;
    
    COMPONENT Filters is
    Port (
        clock_in      : IN STD_LOGIC;
        reset_in      : IN STD_LOGIC;
        start         : IN STD_LOGIC;
        enable_in     : IN STD_LOGIC;
        frequency     : IN INTEGER range 0 to 8000;
        resonance     : IN INTEGER range 0 to 100;
        filter_type   : IN INTEGER range 0 to 4;
        filter_lfo    : IN INTEGER range 0 to 1;
        filter_lfo_d  : IN INTEGER range 0 to 1;
        lfo3_data     : IN UNSIGNED(23 downto 0);
        lfo3_mode     : IN INTEGER range 0 to 3;
        data_in       : IN SIGNED(BIT_DEPTH - 1 downto 0);
        filter_finish : OUT STD_LOGIC;
        data_out      : OUT SIGNED(BIT_DEPTH - 1 downto 0)
    );
    end COMPONENT;

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
    
    signal osc1_type, osc2_type : INTEGER range 0 to 3;
    signal osc1_semitone, osc2_semitone : INTEGER range -12 to 12;
	signal osc1_volume, osc2_volume : INTEGER range 0 to 100;
	signal master_volume : INTEGER range 0 to 100;
	
	signal osc1_detune, osc2_detune : INTEGER range 0 to 100;
    signal portamento : INTEGER range 0 to 100;
    
    signal pulsewidth : TYPE_PULSEW;
	
    signal attack_adsr  : INTEGER range 0 to 4095;
    signal decay_adsr   : INTEGER range 0 to 4095;
    signal sustain_adsr : INTEGER range 0 to 100;
    signal release_adsr : INTEGER range 0 to 4095;
    
    signal attack_time, decay_time, release_time : INTEGER range 0 to 10;
    
    signal attack_value, decay_value, release_value : INTEGER range 0 to 100;
    
    signal prev_note : TYPE_PREV_NOTE;
    signal note_code : TYPE_NOTE_CODE;
	signal note_play : STD_LOGIC_VECTOR(VOICES - 1 downto 0);
	signal note_enable : STD_LOGIC_VECTOR(VOICES - 1 downto 0);
	
	signal osc1_lfo, osc2_lfo : INTEGER range 0 to 100;
    signal lfo_type, lfo_mode : TYPE_LFO_TYPE;
    signal lfo_note : TYPE_LFO_NOTE;
    
    signal filter_freq : INTEGER range 0 to 8000;
    signal filter_q : INTEGER range 0 to 100;
    signal filter_type : INTEGER range 0 to 4;
    signal filter_lfo : INTEGER range 0 to 1;
    signal filter_lfo_d : INTEGER range 0 to 1;
    
    signal noise_volume : INTEGER range 0 to 100;
    
    signal pmod_input : INTEGER range 0 to 1;
    
    signal process_data : STD_LOGIC;
    
    constant ZEROS : STD_LOGIC_VECTOR(VOICES - 1 downto 0) := (others => '0');
    
    signal synch_start, filter_start, noise_start : STD_LOGIC;
    
    signal wave_finish, filter_finish : STD_LOGIC;
    
    signal lfo3_data : UNSIGNED(23 downto 0);
    
    signal data_out_v : TYPE_DATA_OUT;
    
    signal r_data_osc1, r_data_osc2 : SIGNED(BIT_DEPTH * 4 - 1 downto 0);
    
    signal r_data_mix : SIGNED(BIT_DEPTH * 2 + 1 downto 0);
    
    signal r_data_osc1_v, r_data_osc2_v, r_data_master : SIGNED(BIT_DEPTH * 2 - 1 downto 0);
    signal r_data_osc1_x, r_data_osc2_x : SIGNED(BIT_DEPTH downto 0);
    
    signal noise_data_in, noise_data_out : SIGNED(BIT_DEPTH - 1 downto 0);
    signal filter_data_out : SIGNED(BIT_DEPTH - 1 downto 0);
    
    type effect_state is (
        IDLE, NOISE_L, NOISE_R, FILTER_L, FILTER_R
    );
    signal current_state : effect_state := IDLE;

begin

    --instantiate wave mixer component
    wave_selector_0 : WaveSelector
       port map (
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
       r_data_out => data_out_v,
       wave_finish => wave_finish,
       leds_out => leds_out,
--       leds_out => open,
       lfo3_data => lfo3_data
    );
    
    --instantiate Parameters component
    parameters_0 : Parameters
       port map (
       clock_in => clock_in,
       rx_ready => rx_ready,
       data_in => uart_data_in,
       note_enable => note_enable,
       osc1_type => osc1_type,
       osc2_type => osc2_type,
       osc1_semitone_o => osc1_semitone,
       osc2_semitone_o => osc2_semitone,
       osc1_volume => osc1_volume,
       osc2_volume => osc2_volume,
       osc1_detune => osc1_detune,
       osc2_detune => osc2_detune,
       osc1_lfo => osc1_lfo,
       osc2_lfo => osc2_lfo,
       lfo_note => lfo_note,
       lfo_type => lfo_type,
       lfo_mode => lfo_mode,
       pulsewidth => pulsewidth,
       portamento => portamento,
       master_volume => master_volume,
       attack_time_o => attack_time,
       decay_time_o => decay_time,
       release_time_o => release_time,
       attack_value_o => attack_value,
       decay_value_o => decay_value,
       release_value_o => release_value,
       attack_adsr => attack_adsr,
       decay_adsr => decay_adsr,
       sustain_adsr => sustain_adsr,
       release_adsr => release_adsr,
       prev_note_o => prev_note,
       note_code_o => note_code,
       note_play => note_play,
       filter_freq => filter_freq,
       filter_q => filter_q,
       filter_type => filter_type,
       filter_lfo => filter_lfo,
       filter_lfo_d => filter_lfo_d,
       noise_volume => noise_volume,
       pmod_input => pmod_input,
--       leds_out => leds_out,
       synch_start => synch_start
    );
    
    --instantiate Synchronize component
    synchronize_0 : Synchronize
       port map (
       clock_in => clock_in,
       synch_start => synch_start,
       tx_ready => tx_ready,
       osc1_type => osc1_type,
       osc2_type => osc2_type,
       osc1_semitone => osc1_semitone,
       osc2_semitone => osc2_semitone,
       osc1_detune => osc1_detune,
       osc2_detune => osc2_detune,
       osc1_lfo => osc1_lfo,
       osc2_lfo => osc2_lfo,
       osc1_volume => osc1_volume,
       osc2_volume => osc2_volume,
       lfo_note => lfo_note,
       lfo_type => lfo_type,
       lfo_mode => lfo_mode,
       pulsewidth => pulsewidth,
       portamento => portamento,
       master_volume => master_volume,
       attack_time => attack_time,
       decay_time => decay_time,
       release_time => release_time,
       attack_adsr => attack_value,
       decay_adsr => decay_value,
       sustain_adsr => sustain_adsr,
       release_adsr => release_value,
       filter_freq => filter_freq,
       filter_q => filter_q,
       filter_type => filter_type,
       filter_lfo => filter_lfo,
       filter_lfo_d => filter_lfo_d,
       noise_volume => noise_volume,
       pmod_input => pmod_input,
       tx_start => tx_start,
--       leds_out => leds_out,
       data_out => uart_data_out
    );
    
    --instantiate filters component
    filters_0 : Filters
       port map (
       clock_in => clock_in,
       reset_in => reset_in,
       start => filter_start,
       enable_in => process_data,
       frequency => filter_freq,
       resonance => filter_q,
       filter_type => filter_type,
       filter_lfo => filter_lfo,
       filter_lfo_d => filter_lfo_d,
       lfo3_data => lfo3_data,
       lfo3_mode => lfo_mode(2),
       data_in => noise_data_out,
       filter_finish => filter_finish,
       data_out => filter_data_out
    );

    --instantiate noise gen component
    noise_gen0 : NoiseGen
        port map(
        clock_in => clock_in,
        reset_in => reset_in,
        start  => noise_start,
        enable_in => process_data,
        noise_volume => noise_volume,
        data_in => noise_data_in,
        data_out => noise_data_out
    );

    process(clock_in, reset_in)
    begin
        if rising_edge(clock_in) then
            if reset_in = '0' then
                current_state <= IDLE;
                filter_start <= '0';
                noise_start <= '0';
            else
                case current_state is
                when NOISE_L =>
                    noise_start <= '1';
                    noise_data_in <= signed(l_data_rx);
                    current_state <= FILTER_L;
                when FILTER_L =>
                    noise_start <= '0';
                    filter_start <= '1';
                    if filter_finish = '1' then
                        filter_start <= '0';
                        l_data_out <= filter_data_out;
                        current_state <= NOISE_R;
                    end if;
                when NOISE_R =>
                    if pmod_input = 0 then
                        noise_data_in <= r_data_master(BIT_DEPTH - 1 downto 0);
                    else
                        noise_data_in <= signed(r_data_rx);
                    end if;
                    noise_start <= '1';
                    current_state <= FILTER_R;
                when FILTER_R =>
                    noise_start <= '0';
                    filter_start <= '1';
                    if filter_finish = '1' then
                        filter_start <= '0';
                        r_data_out <= filter_data_out;
                        if pmod_input = 0 then
                            l_data_out <= filter_data_out;
                        end if;
                        current_state <= IDLE;
                    end if;
                when IDLE =>
                    if wave_finish = '1' then
                        if pmod_input = 0 then
                            current_state <= NOISE_R;
                        else
                            current_state <= NOISE_L;
                        end if;
                    end if;
                end case;
            end if;
        end if;
    end process;
    
--    leds_out(0) <= '1' when current_state = IDLE else '0';
--    leds_out(1) <= '1' when current_state = NOISE_R else '0';
--    leds_out(2) <= '1' when current_state = FILTER_R else '0';

    process_data <= '1' when pmod_input = 1 OR note_enable /= ZEROS else '0';

    -- mixing polyphony for oscillator1
    process(clock_in, reset_in)
        -- sum'length también marca el límite de polifonía (por el desbordamiento), además de los recursos y la frecuencia de reloj
        variable sum : SIGNED(BIT_DEPTH * 2 - 1 downto 0);
        variable count : INTEGER range 0 to VOICES/2;
    begin
        if reset_in = '0' then
            r_data_osc1 <= (others => '0');
        elsif rising_edge(clock_in) then
            if wave_finish = '1' then
                sum := (others => '0');
                count := 0;
                for ii in 0 to (VOICES/2) - 1 loop
                    if note_enable(ii) = '1' then
                        sum := sum + data_out_v(ii);
                        count := count + 1;
                    end if;
                end loop;
                r_data_osc1 <= sum * fixed_mult(voice_percent(count-1)) / POW_2_16;
            end if;
        end if;
    end process;

    -- mixing polyphony for oscillator2
    process(clock_in, reset_in)
        variable sum : SIGNED(BIT_DEPTH * 2 - 1 downto 0);
        variable count : INTEGER range 0 to VOICES/2;
    begin
        if reset_in = '0' then
            r_data_osc2 <= (others => '0');
        elsif rising_edge(clock_in) then
            if wave_finish = '1' then
                sum := (others => '0');
                count := 0;
                for ii in VOICES/2 to VOICES - 1 loop
                    if note_enable(ii) = '1' then
                        sum := sum + data_out_v(ii);
                        count := count + 1;
                    end if;
                end loop;
                r_data_osc2 <= sum * fixed_mult(voice_percent(count-1)) / POW_2_16;
            end if;
        end if;
    end process;
    
    -- set the oscillator volume
    r_data_osc1_v <= (r_data_osc1(BIT_DEPTH - 1 downto 0) * fixed_mult(osc1_volume)) / POW_2_16;
    r_data_osc2_v <= (r_data_osc2(BIT_DEPTH - 1 downto 0) * fixed_mult(osc2_volume)) / POW_2_16;
    
    -- mix both oscillators
    r_data_osc1_x <= r_data_osc1_v(BIT_DEPTH - 1) & r_data_osc1_v(BIT_DEPTH - 1 downto 0);
    r_data_osc2_x <= r_data_osc2_v(BIT_DEPTH - 1) & r_data_osc2_v(BIT_DEPTH - 1 downto 0);
    r_data_mix <= (r_data_osc1_x + r_data_osc2_x) * 32768 / POW_2_16;
    
    -- set the mix to the master volume
    r_data_master <= (r_data_mix(BIT_DEPTH - 1 downto 0) * fixed_mult(master_volume)) / POW_2_16;
    
    -- ahora la salida master pasa siempre por Noise -> Filters -> DAC
--    r_data_out <= r_data_master(BIT_DEPTH - 1 downto 0);

end Behavioral;