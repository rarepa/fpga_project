--------------------------------------------------------------------------------
--
--   FileName:         i2s_playback.vhd
--   Dependencies:     i2s_transceiver.vhd, clk_wiz_0 (PLL)
--   Design Software:  Vivado v2017.2
--
--   HDL CODE IS PROVIDED "AS IS."  DIGI-KEY EXPRESSLY DISCLAIMS ANY
--   WARRANTY OF ANY KIND, WHETHER EXPRESS OR IMPLIED, INCLUDING BUT NOT
--   LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
--   PARTICULAR PURPOSE, OR NON-INFRINGEMENT. IN NO EVENT SHALL DIGI-KEY
--   BE LIABLE FOR ANY INCIDENTAL, SPECIAL, INDIRECT OR CONSEQUENTIAL
--   DAMAGES, LOST PROFITS OR LOST DATA, HARM TO YOUR EQUIPMENT, COST OF
--   PROCUREMENT OF SUBSTITUTE GOODS, TECHNOLOGY OR SERVICES, ANY CLAIMS
--   BY THIRD PARTIES (INCLUDING BUT NOT LIMITED TO ANY DEFENSE THEREOF),
--   ANY CLAIMS FOR INDEMNITY OR CONTRIBUTION, OR OTHER SIMILAR COSTS.
--
--   Version History
--   Version 1.0 04/19/2019 Scott Larson
--     Initial Public Release
-- 
--------------------------------------------------------------------------------

package my_pack is new work.synthesizer_package generic map(d_voices => 6, d_bits => 24);
use work.my_pack.ALL;

LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

ENTITY i2s_playback IS
    PORT(
        clock       :  IN  STD_LOGIC;                     --system clock (100 MHz on Basys board)
--        reset_n     :  IN  STD_LOGIC;                     --active low asynchronous reset
        mclk        :  OUT STD_LOGIC_VECTOR(1 DOWNTO 0);  --master clock
        sclk        :  OUT STD_LOGIC_VECTOR(1 DOWNTO 0);  --serial clock (or bit clock)
        ws          :  OUT STD_LOGIC_VECTOR(1 DOWNTO 0);  --word select (or left-right clock)
        sd_rx       :  IN  STD_LOGIC;                     --serial data in
        sd_tx       :  OUT STD_LOGIC;                    --serial data out
        
        -- UART ports
        reset_btn      : in  STD_LOGIC;
        tx_enable      : in  STD_LOGIC;
        data_in        : in  STD_LOGIC_VECTOR (7 downto 0);
        data_out       : out STD_LOGIC_VECTOR (7 downto 0);
        uart_rx        : in  STD_LOGIC;
        uart_tx        : out STD_LOGIC);
END i2s_playback;

ARCHITECTURE logic OF i2s_playback IS

    signal reset_clk : STD_LOGIC;

    SIGNAL master_clk   :  STD_LOGIC;                             --internal master clock signal
    SIGNAL serial_clk   :  STD_LOGIC := '0';                      --internal serial clock signal
    SIGNAL word_select  :  STD_LOGIC := '0';                      --internal word select signal
    SIGNAL l_data_rx    :  STD_LOGIC_VECTOR(BIT_DEPTH - 1 DOWNTO 0);  --left channel data received from I2S Transceiver component
    SIGNAL r_data_rx    :  STD_LOGIC_VECTOR(BIT_DEPTH - 1 DOWNTO 0);  --right channel data received from I2S Transceiver component
    SIGNAL l_data_tx    :  STD_LOGIC_VECTOR(BIT_DEPTH - 1 DOWNTO 0);  --left channel data to transmit using I2S Transceiver component
    SIGNAL r_data_tx    :  STD_LOGIC_VECTOR(BIT_DEPTH - 1 DOWNTO 0);  --right channel data to transmit using I2S Transceiver component
 
    --declare PLL to create 11.29 MHz master clock from 100 MHz system clock
    component clk_wiz_0
    port
     (-- Clock in ports
      -- Clock out ports
      clk_out1          : out    std_logic;
      -- Status and control signals
      reset             : in     std_logic;
      locked            : out    std_logic;
      clk_in1           : in     std_logic
     );
    end component;
    
    --declare I2S Transceiver component
    COMPONENT i2s_transceiver IS
        GENERIC(
            mclk_sclk_ratio :  INTEGER := 4;    --number of mclk periods per sclk period
            sclk_ws_ratio   :  INTEGER := 64;   --number of sclk periods per word select period
            d_width         :  INTEGER := 24);  --data width
        PORT(
            reset_n     :  IN   STD_LOGIC;                              --asynchronous active low reset
            mclk        :  IN   STD_LOGIC;                              --master clock

            sclk        :  OUT  STD_LOGIC;                              --serial clock (or bit clock)
            ws          :  OUT  STD_LOGIC;                              --word select (or left-right clock)
            sd_tx       :  OUT  STD_LOGIC;                              --serial data transmit
            sd_rx       :  IN   STD_LOGIC;                              --serial data receive
            l_data_tx   :  IN   STD_LOGIC_VECTOR(d_width-1 DOWNTO 0);   --left channel data to transmit
            r_data_tx   :  IN   STD_LOGIC_VECTOR(d_width-1 DOWNTO 0);   --right channel data to transmit
            l_data_rx   :  OUT  STD_LOGIC_VECTOR(d_width-1 DOWNTO 0);   --left channel data received
            r_data_rx   :  OUT  STD_LOGIC_VECTOR(d_width-1 DOWNTO 0));  --right channel data received
    END COMPONENT;
    
    COMPONENT UART_controller is
        PORT(
            clk              : in  std_logic;
            reset            : in  std_logic;
            tx_enable        : in  std_logic;
            data_in          : in  std_logic_vector (7 downto 0);
            data_out         : out std_logic_vector (7 downto 0);
            rx               : in  std_logic;
            tx               : out std_logic;
            rx_ready         : out std_logic := '0';
            tx_ready         : out std_logic := '1';
--            leds_out         : out STD_LOGIC_VECTOR(7 downto 0);
            tx_start         : in std_logic
            );
    end COMPONENT;
    
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
    
    signal uart_data_in, uart_data_out : STD_LOGIC_VECTOR (7 downto 0);
    signal tx_ready, rx_ready, tx_start : STD_LOGIC;
    
    signal reset_n : STD_LOGIC := '1';
    
    signal r_data_out : SIGNED(BIT_DEPTH - 1 downto 0);
	signal l_data_out : SIGNED(BIT_DEPTH - 1 downto 0);
    
BEGIN

    reset_clk <= not reset_n;
    
    --instantiate UART controller component
    uart_controller_0 : UART_controller
       port map ( 
       clk => master_clk,
       --reset => reset_btn,
       reset => '0', -- activo a nivel alto
       tx_enable => tx_enable,
       --data_in => data_in, -- switches
       data_in => uart_data_out,
       data_out => uart_data_in,
       rx => uart_rx,
       tx => uart_tx,
       rx_ready => rx_ready,
       tx_ready => tx_ready,
--       leds_out => data_out,
       tx_start => tx_start
    );
    
    --instantiate synthesizer component
    synthesizer_0 : Synthesizer
       port map (
       clock_in => master_clk,
       word_select => word_select,
       reset_in => reset_n,
       uart_data_in => uart_data_in,
       rx_ready => rx_ready,
       tx_ready => tx_ready,
       tx_start => tx_start,
       uart_data_out => uart_data_out,
       leds_out => data_out,
       l_data_rx => l_data_rx,
       r_data_rx => r_data_rx,
       l_data_out => l_data_out,
       r_data_out => r_data_out
    );
     
    --instantiate PLL to create master clock
    i2s_clock : clk_wiz_0
       port map ( 
      -- Clock out ports  
       clk_out1 => master_clk,
      -- Status and control signals                
       reset => reset_clk,
       locked => open,
       -- Clock in ports
       clk_in1 => clock
     );
       
    --instantiate I2S Transceiver component
    i2s_transceiver_0: i2s_transceiver
    GENERIC MAP(
        mclk_sclk_ratio => 4, 
        sclk_ws_ratio => 64, 
        d_width => 24)
    PORT MAP(
        reset_n => reset_n,
        mclk => master_clk,
        sclk => serial_clk,
        ws => word_select,
        sd_tx => sd_tx,
        sd_rx => sd_rx,
        l_data_tx => l_data_tx,
        r_data_tx => r_data_tx,
        l_data_rx => l_data_rx,
        r_data_rx => r_data_rx);
  
    mclk(0) <= master_clk;  --output master clock to ADC
    mclk(1) <= master_clk;  --output master clock to DAC
    sclk(0) <= serial_clk;  --output serial clock (from I2S Transceiver) to ADC
    sclk(1) <= serial_clk;  --output serial clock (from I2S Transceiver) to DAC
    ws(0) <= word_select;   --output word select (from I2S Transceiver) to ADC
    ws(1) <= word_select;   --output word select (from I2S Transceiver) to DAC

    r_data_tx <= std_logic_vector(r_data_out);
    l_data_tx <= std_logic_vector(l_data_out);
    
END logic;
