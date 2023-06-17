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

entity WaveSelector is
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
end WaveSelector;

architecture Behavioral of WaveSelector is
    
    COMPONENT adsr_env is
    Port (
        clock_in   : IN STD_LOGIC;
        reset_in   : IN STD_LOGIC;
        start      : IN STD_LOGIC;
        attack     : IN INTEGER range 0 to 4095;
        decay      : IN INTEGER range 0 to 4095;
        sustain    : IN INTEGER range 0 to 100;
        release    : IN INTEGER range 0 to 4095;
        note_play  : IN STD_LOGIC_VECTOR(VOICES - 1 downto 0);
        note_enab  : OUT STD_LOGIC_VECTOR(VOICES - 1 downto 0);
        note_start : OUT STD_LOGIC_VECTOR(VOICES - 1 downto 0);
        adsr_data  : OUT TYPE_ADSR_DATA
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
    
    COMPONENT WaveTriangle is
    Port (
        clock_in   : IN STD_LOGIC;
        reset_in   : IN STD_LOGIC;
        start      : IN STD_LOGIC;
        cycles     : IN TYPE_CYCLES;
        note_enab  : IN STD_LOGIC_VECTOR(VOICES - 1 downto 0);
        r_data_out : OUT TYPE_DATA_OUT
     );
    end COMPONENT;
    
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
    
    COMPONENT LFOSawtooth is
    Port (
        clock_in  : IN STD_LOGIC;
        reset_in  : IN STD_LOGIC;
        start     : IN STD_LOGIC;
        lfo_en    : IN STD_LOGIC;
        note_code : IN TYPE_LFO_NOTE;
        data_out  : OUT TYPE_LFO_DATA
     );
    end COMPONENT;
    
    COMPONENT LFOTriangle is
    Port (
        clock_in  : IN STD_LOGIC;
        reset_in  : IN STD_LOGIC;
        start     : IN STD_LOGIC;
        lfo_en    : IN STD_LOGIC;
        note_code : IN TYPE_LFO_NOTE;
        data_out  : OUT TYPE_LFO_DATA
     );
    end COMPONENT;
    
    COMPONENT LFOSquare is
    Port (
        clock_in  : IN STD_LOGIC;
        reset_in  : IN STD_LOGIC;
        start     : IN STD_LOGIC;
        lfo_en    : IN STD_LOGIC;
        note_code : IN TYPE_LFO_NOTE;
        data_out  : OUT TYPE_LFO_DATA
     );
    end COMPONENT;
    
    COMPONENT LFOSine is
    Port (
        clock_in  : IN STD_LOGIC;
        reset_in  : IN STD_LOGIC;
        start     : IN STD_LOGIC;
        lfo_en    : IN STD_LOGIC;
        note_code : IN TYPE_LFO_NOTE;
        data_out  : OUT TYPE_LFO_DATA
     );
    end COMPONENT;
    
    COMPONENT PortaROM is
    Port (
        clock_in  : IN STD_LOGIC;
        addr_in   : IN INTEGER range 0 to 5390;
        data_out  : OUT INTEGER range 0 to 5512
    );
    end COMPONENT;
    
    signal adsr_data : TYPE_ADSR_DATA;
    
    signal detune : TYPE_DETUNE;
    
    signal cycles_now : TYPE_CYCLES := (others => 100);
    
    signal note_enab : STD_LOGIC_VECTOR(VOICES - 1 downto 0);
    
    signal note_start : STD_LOGIC_VECTOR(VOICES - 1 downto 0);
    
    type TYPE_WAIT is array (0 to VOICES - 1) of INTEGER;
    signal pwait : TYPE_WAIT := (others => 0);
    
    signal lfo_data, lfo_data_saw, lfo_data_tri,
           lfo_data_squ, lfo_data_sin : TYPE_LFO_DATA;
    
    signal lfo_en : STD_LOGIC;
    
    signal r_data_sel, r_data_out_saw, r_data_out_tri,
           r_data_out_squ, r_data_out_sin : TYPE_DATA_OUT;
    
    type TYPE_DATA_ADSR is array(0 to VOICES - 1) of SIGNED(BIT_DEPTH * 2 - 1 downto 0);
    signal r_data_adsr : TYPE_DATA_ADSR := (others => (others => '0'));
           
    signal ws_changed, start : STD_LOGIC := '0';
    
    type STATE is (WAIT_START, READING, WORKING);
    signal current_state : STATE := WAIT_START;
    
    signal enable, start_gen : STD_LOGIC := '0';
    
    signal wave_now : INTEGER range 0 to VOICES - 1 := 0;
    
    signal addr_in : INTEGER range 0 to 5390;
    
    signal porta_data : INTEGER range 0 to 5512;
    
    signal prevnote : INTEGER range 0 to 127;
    
    signal detune_now : INTEGER range 0 to 100;
    
    signal wait_gen : STD_LOGIC := '0';
    
    signal wait_gen_count : INTEGER range 0 to VOICES * 6 - 1 := 0;

begin
    
    --instantiate adsr envelope component
    adsr_env_0 : adsr_env
       port map (
       clock_in => clock_in,
       reset_in => reset_in,
       start => start,
       attack => attack_adsr,
       decay => decay_adsr,
       sustain => sustain_adsr,
       release => release_adsr,
       note_play => note_play,
       note_enab => note_enab,
       note_start => note_start,
       adsr_data => adsr_data
    );
    
    --instantiate wave sawtooth component
    wave_saw_0 : WaveSawtooth
       port map (
       clock_in => clock_in,
       reset_in => reset_in,
       start => start_gen,
       cycles => cycles_now,
       note_enab => note_enab,
       r_data_out => r_data_out_saw
    );
    
    --instantiate wave triangle component
    wave_tri_0 : WaveTriangle
       port map (
       clock_in => clock_in,
       reset_in => reset_in,
       start => start_gen,
       cycles => cycles_now,
       note_enab => note_enab,
       r_data_out => r_data_out_tri
    );
    
    --instantiate wave square component
    wave_squ_0 : WaveSquare
       port map (
       clock_in => clock_in,
       reset_in => reset_in,
       start => start_gen,
       cycles => cycles_now,
       pulsewidth => pulsewidth,
       note_enab => note_enab,
       r_data_out => r_data_out_squ
    );
    
    --instantiate wave sine component
    wave_sin_0 : WaveSine
       port map (
       clock_in => clock_in,
       reset_in => reset_in,
       start => start_gen,
       cycles => cycles_now,
       note_enab => note_enab,
       r_data_out => r_data_out_sin
    );
    
    --instantiate lfo sawtooth component
    lfo_saw_0 : LFOSawtooth
       port map (
       clock_in => clock_in,
       reset_in => reset_in,
       start => start,
       lfo_en => lfo_en,
       note_code => lfo_note,
       data_out => lfo_data_saw
    );
    
    --instantiate lfo triangle component
    lfo_tri_0 : LFOTriangle
       port map (
       clock_in => clock_in,
       reset_in => reset_in,
       start => start,
       lfo_en => lfo_en,
       note_code => lfo_note,
       data_out => lfo_data_tri
    );
    
    --instantiate lfo square component
    lfo_squ_0 : LFOSquare
       port map (
       clock_in => clock_in,
       reset_in => reset_in,
       start => start,
       lfo_en => lfo_en,
       note_code => lfo_note,
       data_out => lfo_data_squ
    );
    
    --instantiate lfo sine component
    lfo_sin_0 : LFOSine
       port map (
       clock_in => clock_in,
       reset_in => reset_in,
       start => start,
       lfo_en => lfo_en,
       note_code => lfo_note,
       data_out => lfo_data_sin
    );
    
    --instantiate portamento rom component
    portamento_rom0 : PortaROM
       port map (
       clock_in => clock_in,
       addr_in => addr_in,
       data_out => porta_data
    );
    
    addr_in <= abs(sample_cycle(prevnote) - sample_cycle(note_code(wave_now)));
    
    prevnote <= prev_note(0) when wave_now < VOICES/2 else prev_note(1);
    
    detune_now <= osc1_detune when wave_now < VOICES/2 - 1 else osc2_detune;
    
    note_enable <= note_enab;
    
    wave_start : process(clock_in, reset_in)
    begin
        if reset_in = '0' then
            ws_changed <= '0';
            start <= '0';
        elsif rising_edge(clock_in) then
            if ws_changed = '1' AND word_select = '0' then
                ws_changed <= '0';
            end if;
            -- equals to rising_edge(word_select)
            if word_select = '1' AND ws_changed = '0' then
                ws_changed <= '1';
                start <= '1'; -- high only one cycle of the clock_in clock
            else
                start <= '0';
            end if;
        end if;
    end process;
    
    end_gen : process(clock_in, reset_in)
    begin
        if rising_edge(clock_in) then
            if reset_in = '0' then
                wave_finish <= '0';
                wait_gen <= '0';
            elsif start_gen = '1' then
                wait_gen <= '1'; -- generators have just started
            elsif wait_gen = '1' then
                if wait_gen_count < VOICES * 6 - 1 then -- wait for triangle generation (worst case)
                    wait_gen_count <= wait_gen_count + 1;
                else
                    wait_gen_count <= 0;
                    wait_gen <= '0';
                    wave_finish <= '1'; -- generators have just finished
                end if;
            else
                wave_finish <= '0';
            end if;
        end if;
    end process;
    
    transitions : process(clock_in, reset_in)
    begin
        if rising_edge(clock_in) then
            if reset_in = '0' then
                current_state <= WAIT_START;
                start_gen <= '0';
                wave_now <= 0;
            else
                if current_state = WORKING then
                    if wave_now = VOICES - 1 then
                        wave_now <= 0;
                        start_gen <= '1'; -- wave generators start
                        current_state <= WAIT_START;
                    else
                        wave_now <= wave_now + 1;
                        current_state <= READING;
                    end if;
                elsif current_state = READING then
                    current_state <= WORKING;
                else
                    start_gen <= '0';
                    if start = '1' then
                        current_state <= READING;
                    end if;
                end if;
            end if;
        end if;
    end process;
    
    outputs_p : process(current_state)
    begin        
        case current_state is
        when WAIT_START =>
            enable <= '0';
        when READING =>
            enable <= '0';
        when WORKING =>
            enable <= '1';
        end case;
    end process;
    
    lfo_gen : for ii in 0 to NUM_LFO - 1 generate
        lfo_data(ii) <= lfo_data_saw(ii) when lfo_type(ii) = 0 else lfo_data_tri(ii) when lfo_type(ii) = 1 else
                        lfo_data_squ(ii) when lfo_type(ii) = 2 else lfo_data_sin(ii) when lfo_type(ii) = 3 else
                        (others => '0');
    end generate;
    
    -- sacamos solo este dato para Filters
    lfo3_data <= lfo_data(2);
    
    -- trigger lfo when a note is enabled
    process(clock_in, reset_in)
        variable enabled : STD_LOGIC;
    begin
        if reset_in = '0' then
            lfo_en <= '0';
        elsif rising_edge(clock_in) then
            enabled := '0';
            for ii in 0 to VOICES - 1 loop
                -- si la entrada de sonido es la del PMOD, también debemos activar la LFO
                if note_enab(ii) = '1' OR pmod_input = 1 then
                    enabled := '1';
                    exit;
                end if;
            end loop;
            lfo_en <= enabled;
        end if;
    end process;
    
--    leds_out_gen: for ii in 0 to VOICES - 1 generate
--        leds_out(ii) <= note_start(ii);
--    end generate;
--    leds_out(7) <= '0';
--    leds_out(6) <= '0';

    leds_out <= std_logic_vector(to_unsigned(prevnote, 8));
--    leds_out <= std_logic_vector(to_unsigned(prev_note(0), 8));
    
    process(clock_in)
        variable wait_for : TYPE_WAIT := (others => 0);
        variable mult_lfo : UNSIGNED(39 downto 0);
        variable lfo_amp  : UNSIGNED(31 downto 0);
        variable cycles_aux : TYPE_CYCLES;
    begin
        if rising_edge(clock_in) then
            if reset_in = '0' then
                wait_for := (others => 0);
                cycles_now <= (others => 0);
            elsif enable = '1' then
                if wave_now < VOICES/2 AND osc1_lfo /= 0 then
                    mult_lfo := to_unsigned(sample_cycle(note_code(wave_now)), 16) * lfo_data(0) / POW_2_24;
                    lfo_amp := mult_lfo(15 downto 0) * fixed_mult(osc1_lfo) / POW_2_16;
                    if lfo_mode(0) = 0 then
                        cycles_aux(wave_now) := sample_cycle(note_code(wave_now)) - to_integer(lfo_amp(15 downto 0));
                        if cycles_aux(wave_now) > sample_cycle(127) then
                            cycles_now(wave_now) <= cycles_aux(wave_now);
                        else
                            cycles_now(wave_now) <= sample_cycle(127);
                        end if;
                    elsif lfo_mode(0) = 1 then
                        cycles_aux(wave_now) := sample_cycle(note_code(wave_now)) - (sample_cycle(note_code(wave_now)) - to_integer(lfo_amp(15 downto 0)));
                        if cycles_aux(wave_now) > sample_cycle(127) then
                            cycles_now(wave_now) <= cycles_aux(wave_now);
                        else
                            cycles_now(wave_now) <= sample_cycle(127);
                        end if;
                    elsif lfo_mode(0) = 2 then
                        cycles_aux(wave_now) := sample_cycle(note_code(wave_now)) + to_integer(lfo_amp(15 downto 0));
                        if cycles_aux(wave_now) < sample_cycle(0) then
                            cycles_now(wave_now) <= cycles_aux(wave_now);
                        else
                            cycles_now(wave_now) <= sample_cycle(0);
                        end if;
                    else
                        cycles_aux(wave_now) := sample_cycle(note_code(wave_now)) + (sample_cycle(note_code(wave_now)) - to_integer(lfo_amp(15 downto 0)));
                        if cycles_aux(wave_now) < sample_cycle(0) then
                            cycles_now(wave_now) <= cycles_aux(wave_now);
                        else
                            cycles_now(wave_now) <= sample_cycle(0);
                        end if;
                    end if;
                elsif wave_now > VOICES/2 - 1 AND osc2_lfo /= 0 then
                    mult_lfo := to_unsigned(sample_cycle(note_code(wave_now)), 16) * lfo_data(1) / POW_2_24;
                    lfo_amp := mult_lfo(15 downto 0) * fixed_mult(osc2_lfo) / POW_2_16;
                    if lfo_mode(1) = 0 then
                        cycles_aux(wave_now) := sample_cycle(note_code(wave_now)) - to_integer(lfo_amp(15 downto 0));
                        if cycles_aux(wave_now) > sample_cycle(127) then
                            cycles_now(wave_now) <= cycles_aux(wave_now);
                        else
                            cycles_now(wave_now) <= sample_cycle(127);
                        end if;
                    elsif lfo_mode(1) = 1 then
                        cycles_aux(wave_now) := sample_cycle(note_code(wave_now)) - (sample_cycle(note_code(wave_now)) - to_integer(lfo_amp(15 downto 0)));
                        if cycles_aux(wave_now) > sample_cycle(127) then
                            cycles_now(wave_now) <= cycles_aux(wave_now);
                        else
                            cycles_now(wave_now) <= sample_cycle(127);
                        end if;
                    elsif lfo_mode(1) = 2 then
                        cycles_aux(wave_now) := sample_cycle(note_code(wave_now)) + to_integer(lfo_amp(15 downto 0));
                        if cycles_aux(wave_now) < sample_cycle(0) then
                            cycles_now(wave_now) <= cycles_aux(wave_now);
                        else
                            cycles_now(wave_now) <= sample_cycle(0);
                        end if;
                    else
                        cycles_aux(wave_now) := sample_cycle(note_code(wave_now)) + (sample_cycle(note_code(wave_now)) - to_integer(lfo_amp(15 downto 0)));
                        if cycles_aux(wave_now) < sample_cycle(0) then
                            cycles_now(wave_now) <= cycles_aux(wave_now);
                        else
                            cycles_now(wave_now) <= sample_cycle(0);
                        end if;
                    end if;
                elsif portamento = 0 then
                    cycles_now(wave_now) <= sample_cycle(note_code(wave_now)) + detune(wave_now);
                else
                    if note_start(wave_now) = '1' then
                        cycles_now(wave_now) <= sample_cycle(prevnote);
                        pwait(wave_now) <= porta_data * fixed_mult(portamento) / POW_2_16;
                    elsif note_enab(wave_now) = '1' then
                        if cycles_now(wave_now) < sample_cycle(note_code(wave_now)) + detune(wave_now) then
                            if wait_for(wave_now) = pwait(wave_now) then
                                wait_for(wave_now) := 0;
                                cycles_now(wave_now) <= cycles_now(wave_now) + 1;
                            else
                                wait_for(wave_now) := wait_for(wave_now) + 1;
                            end if;
                        elsif cycles_now(wave_now) > sample_cycle(note_code(wave_now)) + detune(wave_now) then
                            if wait_for(wave_now) = pwait(wave_now) then
                                wait_for(wave_now) := 0;
                                cycles_now(wave_now) <= cycles_now(wave_now) - 1;
                            else
                                wait_for(wave_now) := wait_for(wave_now) + 1;
                            end if;
                        end if;
                    end if;
                end if;
            end if;
        end if;
    end process;

    process(clock_in)
    begin
        if rising_edge(clock_in) then
            if reset_in = '0' then
                detune <= (others => 0);
            elsif enable = '1' then
                detune(wave_now) <= ((50 - detune_now) * sample_cycle(note_code(wave_now))) / 1024;
            end if;
        end if;
    end process;
    
    osc1_gen : for ii in 0 to VOICES/2 - 1 generate
	   r_data_sel(ii) <= r_data_out_saw(ii) when osc1_type = 0 else r_data_out_tri(ii) when osc1_type = 1 else
                         r_data_out_squ(ii) when osc1_type = 2 else r_data_out_sin(ii) when osc1_type = 3 else
                         (others => '0');
    end generate;
    
    osc2_gen : for ii in VOICES/2 to VOICES - 1 generate
	   r_data_sel(ii) <= r_data_out_saw(ii) when osc2_type = 0 else r_data_out_tri(ii) when osc2_type = 1 else
                         r_data_out_squ(ii) when osc2_type = 2 else r_data_out_sin(ii) when osc2_type = 3 else
                         (others => '0');
    end generate;

    adsr_gen : for ii in 0 to VOICES - 1 generate
	   r_data_adsr(ii) <= (r_data_sel(ii) * fixed_mult(adsr_data(ii))) / POW_2_16;
    end generate;
    
    data_out_gen : for ii in 0 to VOICES - 1 generate
	   r_data_out(ii) <= r_data_adsr(ii)(BIT_DEPTH - 1 downto 0);
    end generate;

end Behavioral;