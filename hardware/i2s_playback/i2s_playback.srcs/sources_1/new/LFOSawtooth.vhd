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

entity LFOSawtooth is
  Port (
    clock_in  : IN STD_LOGIC;
    reset_in  : IN STD_LOGIC;
    start     : IN STD_LOGIC;
    lfo_en    : IN STD_LOGIC;
    note_code : IN TYPE_LFO_NOTE;
    data_out  : OUT TYPE_LFO_DATA
  );
end LFOSawtooth;

architecture Behavioral of LFOSawtooth is

    type COUNTER is array (0 to NUM_LFO - 1) of INTEGER;
    signal i : COUNTER := (others => 0);
    
    signal q : TYPE_LFO_DATA := (others => (others => '0'));
    
    signal enable : STD_LOGIC := '0';
    
    signal lfo_now : INTEGER range 0 to NUM_LFO - 1 := 0;
    
    type STATE is (WAIT_START, WORKING);
    signal current_state : STATE := WAIT_START;

begin

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
	begin
	   if rising_edge(clock_in) then
	       if reset_in = '0' OR lfo_en = '0' then
                i <= (others => 0);
                q <= (others => (others => '0'));
	       elsif enable = '1' then
               if i(lfo_now) < lfo_cycle(note_code(lfo_now)) then
                  -- siempre estamos sumando, por tanto si el resultado es menor entonces hemos desbordado
                  if q(lfo_now) + to_unsigned(lfo_inc(note_code(lfo_now)), 24) < q(lfo_now) then
                    i(lfo_now) <= lfo_cycle(note_code(lfo_now));
                    q(lfo_now) <= (others => '1');
                  else
                    i(lfo_now) <= i(lfo_now) + 1;
                    q(lfo_now) <= q(lfo_now) + to_unsigned(lfo_inc(note_code(lfo_now)), 24);
                  end if;
               else
                  i(lfo_now) <= 0;
                  q(lfo_now) <= (others => '0');
              end if;
           end if;
	   end if;
	end process;
	
	data_out <= q;

end Behavioral;