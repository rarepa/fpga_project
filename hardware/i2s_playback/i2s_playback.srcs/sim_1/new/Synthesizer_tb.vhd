package my_pack is new work.synthesizer_package generic map(d_voices => 6, d_bits => 24);
use work.my_pack.ALL;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity Synthesizer_tb is
--  Port ( );
end Synthesizer_tb;

architecture Behavioral of Synthesizer_tb is

    COMPONENT Synthesizer is
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
    end COMPONENT;
    
    constant CLK_FREQ : TIME := 90ns;

    signal clock_in : STD_LOGIC := '1';
    signal reset_in, word_select : STD_LOGIC := '0';
    
    signal rx_ready, tx_ready, tx_start : STD_LOGIC := '0';
    
    signal uart_data_in, uart_data_out, leds_out : STD_LOGIC_VECTOR(7 downto 0);
    
    signal l_data_rx, r_data_rx : STD_LOGIC_VECTOR(BIT_DEPTH - 1 downto 0) := (others => '0');
    
    signal l_data_out, r_data_out : SIGNED(BIT_DEPTH - 1 downto 0);

begin

    uut : Synthesizer port map(
        clock_in => clock_in,
        word_select => word_select,
        reset_in => reset_in,
        uart_data_in => uart_data_in,
        rx_ready => rx_ready,
        tx_ready => tx_ready,
        tx_start => tx_start,
        uart_data_out => uart_data_out,
        leds_out => leds_out,
        l_data_rx => l_data_rx,
        r_data_rx => r_data_rx,
        l_data_out => l_data_out,
        r_data_out => r_data_out
    );
    
    process
	begin
--		reset_in <= '0';
--		wait for CLK_FREQ;
--		reset_in <= '1';
		
		uart_data_in <= x"24";
        rx_ready <= '1';
        wait for CLK_FREQ;
        rx_ready <= '0';
		
		for i in 0 to 15000 loop
		    word_select <= '1';
		    wait for CLK_FREQ;
            word_select <= '0';
            
            wait for CLK_FREQ * 256;
		end loop;
		
		wait;
	end process;

end Behavioral;