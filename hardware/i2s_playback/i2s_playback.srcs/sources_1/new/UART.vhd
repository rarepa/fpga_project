----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 27.01.2023 21:20:18
-- Design Name: 
-- Module Name: UART - Behavioral
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

entity UART is
        port(
        clk            : in  std_logic;
        reset          : in  std_logic;
        tx_start       : in  std_logic;
        data_in        : in  std_logic_vector (7 downto 0);
        data_out       : out std_logic_vector (7 downto 0);
        rx             : in  std_logic;
        tx             : out std_logic;
        rx_ready       : out std_logic := '0';
--        leds_out       : out STD_LOGIC_VECTOR(7 downto 0);
        tx_ready       : out std_logic := '1'
        );
end UART;

architecture Behavioral of UART is

    component UART_tx
        port(
            clk            : in  std_logic;
            reset          : in  std_logic;
            tx_start       : in  std_logic;
            tx_data_in     : in  std_logic_vector (7 downto 0);
            tx_data_out    : out std_logic;
--            leds_out       : out STD_LOGIC_VECTOR(7 downto 0);
            tx_ready       : out std_logic := '1'
            );
    end component;
    
    component UART_rx
        port(
            clk            : in  std_logic;
            reset          : in  std_logic;
            rx_data_in     : in  std_logic;
            rx_data_out    : out std_logic_vector (7 downto 0);
--            leds_out       : out STD_LOGIC_VECTOR(7 downto 0);
            rx_ready       : out std_logic := '0'
            );
    end component;

begin

    transmitter: UART_tx
    port map(
            clk            => clk,
            reset          => reset,
            tx_start       => tx_start,
            tx_data_in     => data_in,
            tx_data_out    => tx,
--            leds_out       => leds_out,
            tx_ready       => tx_ready
            );


    receiver: UART_rx
    port map(
            clk            => clk,
            reset          => reset,
            rx_data_in     => rx,
            rx_data_out    => data_out,
--            leds_out       => leds_out,
            rx_ready       => rx_ready
            );

end Behavioral;
