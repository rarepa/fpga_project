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

entity WaveSquare is
    Port (
        clock_in   : IN STD_LOGIC;
        reset_in   : IN STD_LOGIC;
        start      : IN STD_LOGIC;
        cycles     : IN TYPE_CYCLES;
        pulsewidth : IN TYPE_PULSEW;
        note_enab  : IN STD_LOGIC_VECTOR(VOICES - 1 downto 0);
        r_data_out : OUT TYPE_DATA_OUT
     );
end WaveSquare;

architecture Behavioral of WaveSquare is

    constant MAX : SIGNED(23 downto 0) := (23 => '0', others => '1');
--    constant MAX_1 : SIGNED(23 downto 0) := (23 => '0', 0 => '0', others => '1');
--    constant ZERO : SIGNED(23 downto 0) := (others => '0');
    constant MIN : SIGNED(23 downto 0) := (23 => '1', others => '0');
--    constant MIN_1 : SIGNED(23 downto 0) := (23 => '1', 0 => '1', others => '0');

    type UP_DOWN is array (0 to VOICES - 1) of STD_LOGIC;
    signal up : UP_DOWN := (others => '0');

    signal wave_now : INTEGER range 0 to VOICES - 1 := 0;
    
    signal enable : STD_LOGIC := '0';

--    type COUNTER is array (0 to VOICES - 1) of UNSIGNED(10 downto 0);
--    signal i : COUNTER := (others => (others =>'0'));
--	signal q : TYPE_DATA_OUT := (others => ZERO);
--	type ZERO_V is array (0 to VOICES - 1) of STD_LOGIC;
--	signal zero_value : ZERO_V := (others => '1');

    type COUNTER is array (0 to VOICES - 1) of INTEGER;
    signal i : COUNTER := (others => 0);
    signal q : TYPE_DATA_OUT := (others => MIN);
	
	type STATE is (WAIT_START, WORKING);
    signal current_state : STATE := WAIT_START;
   
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
                    end if;
                else
                    if start = '1' then
                        current_state <= WORKING;
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
        when WORKING =>
            enable <= '1';
        end case;
    end process;

    process(clock_in)
        variable index : INTEGER range 0 to 1;
        variable pulse_cycles : INTEGER;
    begin
        if rising_edge(clock_in) then
            if reset_in = '0' then
--                i <= (others => (others => '0'));
--                q <= (others=> ZERO);
--                zero_value <= (others => '1');
                i <= (others => 0);
                q <= (others=> MIN);
                up <= (others => '0');
            elsif enable = '1' then
                if wave_now < VOICES/2 then
                    index := 0;
                else
                    index := 1;
                end if;
                
                if up(wave_now) = '1' then
                    pulse_cycles := cycles(wave_now) * fixed_mult(pulsewidth(index)) / POW_2_16;
                else
                    pulse_cycles := cycles(wave_now) - (cycles(wave_now) * fixed_mult(pulsewidth(index)) / POW_2_16);
                end if;
                
                if i(wave_now) < pulse_cycles then
--                if i(wave_now) < cycles(wave_now) / 2 then
                    if up(wave_now) = '1' then
                        q(wave_now) <= MAX;
                    else
                        q(wave_now) <= MIN;
                    end if;
                    i(wave_now) <= i(wave_now) + 1;
                else
                    i(wave_now) <= 0;
                    up(wave_now) <= not up(wave_now);
                end if;
--                if note_enab(wave_now) = '0' AND zero_value(wave_now) = '1' then
--                    q(wave_now) <= ZERO;
--                    i(wave_now) <= (others => '0');
--                elsif i(wave_now) < (cycles(wave_now) / 2) - 1 then
--                    if i(wave_now)(0) = '0' then
--                        q(wave_now) <= MAX;
--                    else
--                        q(wave_now) <= MAX_1;
--                    end if;
--                    i(wave_now) <= i(wave_now) + 1;
--                    zero_value(wave_now) <= '0';
--                elsif i(wave_now) = (cycles(wave_now) / 2) - 1 then
--                    q(wave_now) <= ZERO;
--                    i(wave_now) <= i(wave_now) + 1;
--                    zero_value(wave_now) <= '1';
--                elsif i(wave_now) < cycles(wave_now) - 1 then
--                    if i(wave_now)(0) = '0' then
--                        q(wave_now) <= MIN;
--                    else
--                        q(wave_now) <= MIN_1;
--                    end if;
--                    i(wave_now) <= i(wave_now) + 1;
--                    zero_value(wave_now) <= '0';
--                else
--                    q(wave_now) <= ZERO;
--                    i(wave_now) <= (others => '0');
--                    zero_value(wave_now) <= '1';
--                end if;
            end if;
        end if;
    end process;
    
    data_out_gen : for ii in 0 to VOICES - 1 generate
	   r_data_out(ii) <= q(ii);
    end generate;

end Behavioral;