----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 27.01.2023 21:10:39
-- Design Name: 
-- Module Name: UART_tx - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity UART_tx is
    generic(
        BAUD_CLK_TICKS: integer := 98); -- clk/baud_rate (11 288 340 / 115 200 = 97.98)
    port(
        clk            : in  std_logic;
        reset          : in  std_logic;
        tx_start       : in  std_logic;
        tx_data_in     : in  std_logic_vector (7 downto 0);
        tx_data_out    : out std_logic;
--        leds_out       : out STD_LOGIC_VECTOR(7 downto 0);
        tx_ready       : out std_logic := '1'
        );
end UART_tx;

architecture Behavioral of UART_tx is

    type tx_states_t is (IDLE, START, DATA, STOP);
    signal tx_state  : tx_states_t := IDLE;
    signal baud_rate_clk     : std_logic:= '0';
    signal data_index        : integer range 0 to 7 := 0;
    signal data_index_reset  : std_logic := '1';
    signal stored_data       : std_logic_vector(7 downto 0) := (others=>'0');
    signal start_detected    : std_logic := '0';
    signal start_reset       : std_logic := '0';

begin

-- The baud_rate_clk_generator process generates the UART baud rate clock by
-- setting the baud_rate_clk signal when the counter counts BAUD_CLK_TICKS
-- ticks of the master clk. The BAUD_CLK_TICKS constant is specified in
-- the package and reflects the ratio between the master clk and the baud rate.

    baud_rate_clk_generator: process(clk)
    variable baud_count: integer range 0 to (BAUD_CLK_TICKS - 1) := (BAUD_CLK_TICKS - 1);
    begin
        if rising_edge(clk) then
            if (reset = '1') then
                baud_rate_clk <= '0';
                baud_count := (BAUD_CLK_TICKS - 1);
            else
                if (baud_count = 0) then
                    baud_rate_clk <= '1';
                    baud_count := (BAUD_CLK_TICKS - 1);
                else
                    baud_rate_clk <= '0';
                    baud_count := baud_count - 1;
                end if;
            end if;
        end if;
    end process baud_rate_clk_generator;

-- The tx_start_detector process works on the master clk frequency and catches
-- short (one clk cycle long) impulses in the tx_start signal and keeps it for
-- the UART_tx_FSM. tx_start_detector is needed because the UART_tx_FSM works on
-- the baud rate frequency, but the button_debounce module generates one master clk
-- cycle long impulse per one button push. start_detected keeps the information that
-- such event has occurred.
-- The second purpose of tx_start_detector is to secure the transmitting data.
-- stored_data keeps the transmitting data saved during the transmission.

    tx_start_detector: process(clk)
    begin
        if rising_edge(clk) then
            if (reset ='1') or (start_reset = '1') then
                start_detected <= '0';
            else
                if (tx_start = '1') and (start_detected = '0') then
                    start_detected <= '1';
                    stored_data <= tx_data_in;
                end if;
            end if;
        end if;
    end process tx_start_detector;

-- The data_index_counter process is a simple counter from 0 to 7 working on the baud
-- rate frequency. It is used to perform transformation between the parallel
-- data (stored_data) and the serial output (tx_data_out).
-- The data_index signal is used in UART_tx_FSM to go over the stored_data vector
-- and send the bits one by one.

    data_index_counter: process(clk)
    begin
        if rising_edge(clk) then
            if (reset = '1') or (data_index_reset = '1') then
                data_index <= 0;
            elsif (baud_rate_clk = '1') then
                data_index <= data_index + 1;
            end if;
        end if;
    end process data_index_counter;

-- The UART_FSM_tx process represents a Finite State Machine which has
-- four states (IDLE, START, DATA, STOP). See inline comments for more details.

--    leds_out(0) <= reset;
--    leds_out(1) <= '1' when tx_state = IDLE else '0';
--    leds_out(2) <= '1' when tx_state = START else '0';
--    leds_out(3) <= '1' when tx_state = DATA else '0';
--    leds_out(4) <= '1' when tx_state = STOP else '0';

    UART_tx_FSM: process(clk)
    begin
        if rising_edge(clk) then
            if (reset = '1') then
                tx_state <= IDLE;
                data_index_reset <= '1';   -- keep data_index_counter on hold
                start_reset <= '1';        -- keep tx_start_detector on hold
                tx_data_out <= '1';        -- keep tx line set along the standard
            else
                tx_ready <= '0';
                if (baud_rate_clk = '1') then   -- the FSM works on the baud rate frequency
                    case tx_state is
                        when IDLE =>
                            tx_ready <= '1';
                            data_index_reset <= '1';    -- keep data_index_counter on hold
                            start_reset <= '0';         -- enable tx_start_detector to wait for starting impulses
                            tx_data_out <= '1';         -- keep tx line set along the standard
                            if (start_detected = '1') then
                                tx_state <= START;
--                                tx_ready <= '0';
                            end if;

                        when START =>
                            data_index_reset <= '0';   -- enable data_index_counter for DATA state
                            tx_data_out <= '0';        -- send '0' as a start bit
                            tx_state <= DATA;

                        when DATA =>
                            tx_data_out <= stored_data(data_index);   -- send one bit per one baud clock cycle 8 times
                            if (data_index = 7) then
                                data_index_reset <= '1';              -- disable data_index_counter when it has reached 8
                                tx_state <= STOP;
                            end if;
                        when STOP =>
                            tx_data_out <= '1';     -- send '1' as a stop bit
                            start_reset <= '1';     -- prepare tx_start_detector to be ready detecting the next impuls in IDLE
                            tx_state <= IDLE;
--                            tx_ready <= '1';
                        when others =>
                            tx_state <= IDLE;
                    end case;
                end if;
            end if;
        end if;
    end process UART_tx_FSM;

end Behavioral;
