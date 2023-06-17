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

entity adsr_env is
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
end adsr_env;

architecture Behavioral of adsr_env is

    type ADSR_STATE is (s_attack, s_decay, s_sustain, s_release);
    
    type ADSR_ARR is array (0 to VOICES - 1) of ADSR_STATE;
    signal state_adsr : ADSR_ARR := (others => s_attack);
    
    type COUNTER is array (0 to VOICES - 1) of INTEGER range 0 to 4095;
    signal count : COUNTER := (others => 0);
    
    type OUTPUT is array (0 to VOICES - 1) of INTEGER range 0 to 100;
    signal data_out : OUTPUT := (others => 0);
    
    signal note_en : STD_LOGIC_VECTOR(VOICES - 1 downto 0) := (others => '0');
    
    signal note_st : STD_LOGIC_VECTOR(VOICES - 1 downto 0) := (others => '0');
    
    type STATE is (WAIT_START, READING, WORKING);
    signal current_state : STATE := WAIT_START;
    
    signal enable : STD_LOGIC := '0';
    
    signal wave_now : INTEGER range 0 to VOICES - 1 := 0;

begin

    transitions : process(clock_in, reset_in)
    begin
        if rising_edge(clock_in) then
            if reset_in = '0' then
                current_state <= WAIT_START;
                wave_now <= 0;
            else
                if current_state = WORKING then
                    if wave_now = VOICES - 1 then
                        wave_now <= 0;
                        current_state <= WAIT_START;
                    else
                        wave_now <= wave_now + 1;
                        current_state <= READING;
                    end if;
                elsif current_state = READING then
                    current_state <= WORKING;
                else
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
    
    process(clock_in)
    begin
        if rising_edge(clock_in) then
            if reset_in = '0' then
                count <= (others => 0);
                data_out <= (others => 0);
                state_adsr <= (others => s_attack);
                note_en <= (others => '0');
                note_st <= (others => '0');
            elsif enable = '1' then
                case(state_adsr(wave_now)) is
                when s_attack =>
                    if note_play(wave_now) = '0' then
                        state_adsr(wave_now) <= s_release;
                        count(wave_now) <= 0;
                    else
                        note_en(wave_now) <= '1';
                        -- if attack and data is zero then the note has just been pressed
                        if data_out(wave_now) = 0 then
                            -- aquí hay una FSM para que esté sincronizado con WaveSelector, ya que está activo solo un ciclo
                            note_st(wave_now) <= '1';
                            data_out(wave_now) <= 1;
                        else
                            note_st(wave_now) <= '0';
                        end if;
                        
                        if count(wave_now) < attack then
                            count(wave_now) <= count(wave_now) + 1;
                        else
                            count(wave_now) <= 0;
                            if data_out(wave_now) < 100 then
                                data_out(wave_now) <= data_out(wave_now) + 1;
                            else
                                state_adsr(wave_now) <= s_decay;
                            end if;
                        end if;
                    end if;
                when s_decay =>
                    if note_play(wave_now) = '0' then
                        state_adsr(wave_now) <= s_release;
                        count(wave_now) <= 0;
                    elsif count(wave_now) < decay then
                        count(wave_now) <= count(wave_now) + 1;
                    else
                        count(wave_now) <= 0;
                        if data_out(wave_now) > sustain then
                            data_out(wave_now) <= data_out(wave_now) - 1;
                        else
                            state_adsr(wave_now) <= s_sustain;
                        end if;
                    end if;
                when s_sustain =>
                    if note_play(wave_now) = '0' then
                        state_adsr(wave_now) <= s_release;
                        count(wave_now) <= 0;
                    end if;
                when s_release =>
                    if note_play(wave_now) = '1' then
                        data_out(wave_now) <= 0;
                        state_adsr(wave_now) <= s_attack;
                        count(wave_now) <= 0;
                    elsif data_out(wave_now) > 0 then
                        if count(wave_now) < release then
                            count(wave_now) <= count(wave_now) + 1;
                        else
                            count(wave_now) <= 0;
                            data_out(wave_now) <= data_out(wave_now) - 1;
                        end if;
                    else
                        state_adsr(wave_now) <= s_attack;
                        note_en(wave_now) <= '0';
                    end if;
                end case;
            end if;
        end if;
    end process;
    
    note_enab_gen : for ii in 0 to (VOICES - 1) generate
	   note_enab(ii) <= note_en(ii);
    end generate;
    
    note_start_gen : for ii in 0 to (VOICES - 1) generate
	   note_start(ii) <= note_st(ii);
    end generate;
    
    data_out_gen : for ii in 0 to (VOICES - 1) generate
	   adsr_data(ii) <= data_out(ii);
    end generate;

end Behavioral;