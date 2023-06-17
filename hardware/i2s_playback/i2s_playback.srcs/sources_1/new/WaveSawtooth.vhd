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

entity WaveSawtooth is
    Port (
        clock_in   : IN STD_LOGIC;
        reset_in   : IN STD_LOGIC;
        start      : IN STD_LOGIC;
        cycles     : IN TYPE_CYCLES;
        note_enab  : IN STD_LOGIC_VECTOR(VOICES - 1 downto 0);
        r_data_out : OUT TYPE_DATA_OUT
     );
end WaveSawtooth;

architecture Behavioral of WaveSawtooth is

    COMPONENT SawtoothROM is
    Port (
        clock_in : IN STD_LOGIC;
        addr_in  : IN INTEGER range 0 to 5391;
        data_out : OUT UNSIGNED(39 downto 0)
    );
    end COMPONENT;

    constant MIN_VALUE : SIGNED(39 downto 0) := (39 => '1', others => '0');
    
    constant ZEROS : SIGNED(39 downto 0) := (others => '0');
    
    signal wave_now : INTEGER range 0 to VOICES - 1 := 0;
    
    signal wait_cycles : INTEGER range 0 to VOICES * 2 - 1 := 0;
    
    signal addr_in : INTEGER range 0 to 5391;
    signal rom_data : UNSIGNED(39 downto 0);
    
    signal enable : STD_LOGIC := '0';

    type COUNTER is array (0 to VOICES - 1) of INTEGER;
    signal i : COUNTER := (others => 0);
	type OUTPUT is array (0 to VOICES - 1) of SIGNED(39 downto 0);
	signal q : OUTPUT := (others => (others => '0'));
	type ZERO_V is array (0 to VOICES - 1) of STD_LOGIC;
	signal zero_value : ZERO_V := (others => '1');
	type STEP is array (0 to VOICES - 1) of STD_LOGIC;
	signal st : STEP := (others => '0');
	
	type STATE is (WAIT_START, WAITING, READING, WORKING);
    signal current_state : STATE := WAIT_START;

begin

    --instantiate increment rom component
    inc_rom0 : SawtoothROM
       port map (
       clock_in => clock_in,
       addr_in => addr_in,
       data_out => rom_data
    );
    
    transitions : process(clock_in, reset_in)
    begin
        if rising_edge(clock_in) then
            if reset_in = '0' then
                current_state <= WAIT_START;
                wave_now <= 0;
                wait_cycles <= 0;
            else
                if current_state = WORKING then
                    if wave_now = VOICES - 1 then
                        wave_now <= 0;
                        current_state <= WAIT_START;
                    else
                        wave_now <= wave_now + 1;
                        current_state <= READING;
                    end if;
                elsif current_state = WAITING then
                    if wait_cycles = VOICES * 2 - 1 then
                        current_state <= READING;
                        wait_cycles <= 0;
                    else
                        wait_cycles <= wait_cycles + 1;
                    end if;
                elsif current_state = READING then
                    current_state <= WORKING;
                else
                    if start = '1' then
                        current_state <= WAITING;
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
        when WAITING =>
            enable <= '0';
        when READING =>
            enable <= '0';
        when WORKING =>
            enable <= '1';
        end case;
    end process;
    
    addr_in <= cycles(wave_now);
    
    process(clock_in)
	begin
	   if rising_edge(clock_in) then
	       if reset_in = '0' then
                i <= (others => 0);
                q <= (others=> (others => '0'));
                st <= (others => '0');
                zero_value <= (others => '1');
	       elsif enable = '1' then
               if note_enab(wave_now) = '0' AND zero_value(wave_now) = '1' then
                   i(wave_now) <= 0;
                   q(wave_now) <= (others => '0');
                   st(wave_now) <= '0';
               elsif i(wave_now) < cycles(wave_now) / 2 then
                  -- si vamos a sumar en la etapa 0 y el valor es menor a ZEROS, entonces hemos desbordado
                  if st(wave_now) = '0' AND q(wave_now) + signed(rom_data) < ZEROS then
                    i(wave_now) <= cycles(wave_now) / 2;
                    q(wave_now) <= (39 => '0', others => '1');
                  else
                    i(wave_now) <= i(wave_now) + 1;
                    q(wave_now) <=  q(wave_now) + signed(rom_data);
                  end if;
                  zero_value(wave_now) <= '0';
               else
                  i(wave_now) <= 0;
                  if st(wave_now) = '1' then
                      st(wave_now) <= '0';
                      zero_value(wave_now) <= '1';
                      q(wave_now) <= (others => '0');
                  else
                      st(wave_now) <= '1';
                      q(wave_now) <= MIN_VALUE;
                  end if;
              end if;
           end if;
	   end if;
	end process;
	
	data_out_gen : for ii in 0 to VOICES - 1 generate
	   r_data_out(ii) <= q(ii)(39 downto 16);
    end generate;

end Behavioral;