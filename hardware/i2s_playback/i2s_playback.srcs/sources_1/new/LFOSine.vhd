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

entity LFOSine is
  Port (
    clock_in  : IN STD_LOGIC;
    reset_in  : IN STD_LOGIC;
    start     : IN STD_LOGIC;
    lfo_en    : IN STD_LOGIC;
    note_code : IN TYPE_LFO_NOTE;
    data_out  : OUT TYPE_LFO_DATA
  );
end LFOSine;

architecture Behavioral of LFOSine is

    COMPONENT LFOSineROM is
    Port (
        clock_in  : IN STD_LOGIC;
        addr_in   : IN INTEGER range 0 to sinetable_size;
        data_out  : OUT UNSIGNED(23 downto 0)
    );
    end COMPONENT;

    type COUNTER is array (0 to NUM_LFO - 1) of INTEGER range 0 to sinetable_size;
    signal i : COUNTER := (others => 0);
    
    signal q : TYPE_LFO_DATA := (others => (others => '0'));
    
	type STEP is array (0 to NUM_LFO - 1) of STD_LOGIC_VECTOR(1 downto 0);
	signal st : STEP := (others => "00");
	
	signal addr_in  : INTEGER range 0 to sinetable_size;
    signal lfo_data : UNSIGNED(23 downto 0);
    
    signal enable : STD_LOGIC := '0';
    
    signal lfo_now : INTEGER range 0 to NUM_LFO - 1 := 0;
    
    type STATE is (WAIT_START, READING, WORKING);
    signal current_state : STATE := WAIT_START;

begin

    --instantiate lfo sine rom component
    lfo_sine_rom0 : LFOSineROM
       port map (
       clock_in => clock_in,
       addr_in => addr_in,
       data_out => lfo_data
    );
    
    transitions : process(clock_in, reset_in)
    begin
        if rising_edge(clock_in) then
            if reset_in = '0' then
                current_state <= WAIT_START;
            else
                if current_state = WORKING then
                    if lfo_now = NUM_LFO - 1 then
                        lfo_now <= 0;
                        current_state <= WAIT_START;
                    else
                        lfo_now <= lfo_now + 1;
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
    
    addr_in <= i(lfo_now);
    
    process(clock_in)
    begin
        if rising_edge(clock_in) then
            if reset_in = '0' OR lfo_en = '0' then
                i <= (others => 0);
                q <= (others=> (others => '0'));
                st <= (others => "00");
            elsif enable = '1' then
                if st(lfo_now) = "00" then
                    if i(lfo_now) + lfo_index(note_code(lfo_now)) < sinetable_size then
                        i(lfo_now) <= i(lfo_now) + lfo_index(note_code(lfo_now));
                        q(lfo_now) <= lfo_data - 8388608;
                    else
                        i(lfo_now) <= sinetable_size;
                        q(lfo_now) <= lfo_data - 8388608;
                        st(lfo_now) <= "01";
                    end if;
                elsif st(lfo_now) = "01" then
                    if i(lfo_now) - lfo_index(note_code(lfo_now)) > 0 then
                        i(lfo_now) <= i(lfo_now) - lfo_index(note_code(lfo_now));
                        q(lfo_now) <= lfo_data - 8388608;
                    else
                        i(lfo_now) <= 0;
                        st(lfo_now) <= "10";
                    end if;
                elsif st(lfo_now) = "10" then
                    if i(lfo_now) + lfo_index(note_code(lfo_now)) < sinetable_size then
                        i(lfo_now) <= i(lfo_now) + lfo_index(note_code(lfo_now));
                        q(lfo_now) <= 8388608 - lfo_data;
                    else
                        i(lfo_now) <= sinetable_size;
                        q(lfo_now) <= 8388608 - lfo_data;
                        st(lfo_now) <= "11";
                    end if;
                elsif st(lfo_now) = "11" then
                    if i(lfo_now) - lfo_index(note_code(lfo_now)) > 0 then
                        i(lfo_now) <= i(lfo_now) - lfo_index(note_code(lfo_now));
                        q(lfo_now) <= 8388608 - lfo_data;
                    else
                        i(lfo_now) <= 0;
                        st(lfo_now) <= "00";
                    end if;
                end if;
           end if;
        end if;
    end process;
    
    data_out <= q;

end Behavioral;