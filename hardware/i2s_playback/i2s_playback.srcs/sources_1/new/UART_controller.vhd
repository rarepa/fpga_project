----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 27.01.2023 21:23:10
-- Design Name: 
-- Module Name: UART_controller - Behavioral
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

entity UART_controller is
    port(
        clk              : in  std_logic;
        reset            : in  std_logic;
        tx_enable        : in  std_logic;
        data_in          : in  std_logic_vector (7 downto 0);
        data_out         : out std_logic_vector (7 downto 0);
        rx               : in  std_logic;
        tx               : out std_logic;
        rx_ready         : out std_logic := '0';
        tx_ready         : out std_logic := '1';
--        leds_out         : out STD_LOGIC_VECTOR(7 downto 0);
        tx_start         : in std_logic
        );
end UART_controller;

architecture Behavioral of UART_controller is

    component button_debounce
        port(
            clk        : in  std_logic;
            reset      : in  std_logic;
            button_in  : in  std_logic;
            button_out : out std_logic
            );
    end component;
    
    component UART
        port(
            clk            : in  std_logic;
            reset          : in  std_logic;
            tx_start       : in  std_logic;
            data_in        : in  std_logic_vector (7 downto 0);
            data_out       : out std_logic_vector (7 downto 0);
            rx             : in  std_logic;
            tx             : out std_logic;
            rx_ready       : out std_logic := '0';
--            leds_out       : out STD_LOGIC_VECTOR(7 downto 0);
            tx_ready       : out std_logic := '1'
            );
    end component;

    signal button_pressed : std_logic;

begin

    tx_button_controller: button_debounce
    port map(
            clk            => clk,
            reset          => reset,
            button_in      => tx_enable,
            button_out     => button_pressed
            );

    UART_transceiver: UART
    port map(
            clk            => clk,
            reset          => reset,
            --tx_start       => button_pressed,
            tx_start       => tx_start,
            data_in        => data_in,
            data_out       => data_out,
            rx             => rx,
            tx             => tx,
            rx_ready       => rx_ready,
--            leds_out       => leds_out,
            tx_ready       => tx_ready
            );

end Behavioral;
