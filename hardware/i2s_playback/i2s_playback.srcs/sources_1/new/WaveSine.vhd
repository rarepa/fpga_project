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

entity WaveSine is
    Port (
        clock_in   : IN STD_LOGIC;
        reset_in   : IN STD_LOGIC;
        start      : IN STD_LOGIC;
        cycles     : IN TYPE_CYCLES;
        note_enab  : IN STD_LOGIC_VECTOR(VOICES - 1 downto 0);
        r_data_out : OUT TYPE_DATA_OUT
     );
end WaveSine;

architecture Behavioral of WaveSine is

    COMPONENT SineROM is
    Port (
        clock_in  : IN STD_LOGIC;
        addr_in1  : IN INTEGER range 0 to sinetable_size;
        addr_in2  : IN INTEGER range 0 to 5393;
        data_out1 : OUT UNSIGNED(23 downto 0);
        data_out2 : OUT INTEGER range 0 to sinetable_size
    );
    end COMPONENT;
    
    signal wave_now : INTEGER range 0 to VOICES - 1 := 0;
    
    signal addr_in1 : INTEGER range 0 to sinetable_size;
    signal addr_in2 : INTEGER range 0 to 5393;
    signal rom_data : UNSIGNED(23 downto 0);
    signal index    : INTEGER range 0 to sinetable_size;
    
    signal enable : STD_LOGIC := '0';
    
    type COUNTER is array (0 to VOICES - 1) of INTEGER range 0 to sinetable_size;
    signal i : COUNTER := (others => 0);
    signal q : TYPE_DATA_OUT := (others => (others => '0'));
	type ZERO_V is array (0 to VOICES - 1) of STD_LOGIC;
	signal zero_value : ZERO_V := (others => '1');
	type STEP is array (0 to VOICES - 1) of STD_LOGIC_VECTOR(1 downto 0);
	signal st : STEP := (others => "00");
	
	type STATE is (WAIT_START, READING, WORKING);
    signal current_state : STATE := WAIT_START;

begin

    --instantiate sine rom component
    sine_rom0 : SineROM
       port map (
       clock_in => clock_in,
       addr_in1 => addr_in1,
       addr_in2 => addr_in2,
       data_out1 => rom_data,
       data_out2 => index
    );
    
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
    
    addr_in1 <= i(wave_now);
    
    addr_in2 <= cycles(wave_now);
               
    process(clock_in)
    begin
        if rising_edge(clock_in) then
            if reset_in = '0' then
                i <= (others => 0);
                q <= (others=> (others => '0'));
                st <= (others => "00");
                zero_value <= (others => '1');
            elsif enable = '1' then
                if note_enab(wave_now) = '0' AND zero_value(wave_now) = '1' then
                    i(wave_now) <= 0;
                    q(wave_now) <= (others=> '0');
                    st(wave_now) <= "00";
                elsif st(wave_now) = "00" then
                    if i(wave_now) + index < sinetable_size then
                        i(wave_now) <= i(wave_now) + index;
                        zero_value(wave_now) <= '0';
                        q(wave_now) <= signed(rom_data);
                    else
                        i(wave_now) <= sinetable_size;
                        zero_value(wave_now) <= '0';
                        q(wave_now) <= signed(rom_data);
                        st(wave_now) <= "01";
                    end if;
                elsif st(wave_now) = "01" then
                    if i(wave_now) - index > 0 then
                        i(wave_now) <= i(wave_now) - index;
                        zero_value(wave_now) <= '0';
                        q(wave_now) <= signed(rom_data);
                    else
                        i(wave_now) <= 0;
                        zero_value(wave_now) <= '1';
                        q(wave_now) <= (others=> '0');
                        st(wave_now) <= "10";
                    end if;
                elsif st(wave_now) = "10" then
                    if i(wave_now) + index < sinetable_size then
                        i(wave_now) <= i(wave_now) + index;
                        zero_value(wave_now) <= '0';
                        q(wave_now) <= -(signed(rom_data));
                    else
                        i(wave_now) <= sinetable_size;
                        zero_value(wave_now) <= '0';
                        q(wave_now) <= -(signed(rom_data));
                        st(wave_now) <= "11";
                    end if;
                elsif st(wave_now) = "11" then
                    if i(wave_now) - index > 0 then
                        i(wave_now) <= i(wave_now) - index;
                        zero_value(wave_now) <= '0';
                        q(wave_now) <= -(signed(rom_data));
                    else
                        i(wave_now) <= 0;
                        zero_value(wave_now) <= '1';
                        q(wave_now) <= (others=> '0');
                        st(wave_now) <= "00";
                    end if;
                end if;
           end if;
        end if;
    end process;

    data_out_gen : for ii in 0 to VOICES - 1 generate
	   r_data_out(ii) <= q(ii);
    end generate;

end Behavioral;