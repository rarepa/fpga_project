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

entity NoiseGen is
    Port (
        clock_in     : IN STD_LOGIC;
        reset_in     : IN STD_LOGIC;
        start        : IN STD_LOGIC;
        enable_in    : IN STD_LOGIC;
        noise_volume : IN INTEGER range 0 to 100;
        data_in      : IN SIGNED(BIT_DEPTH - 1 downto 0);
        data_out     : OUT SIGNED(BIT_DEPTH - 1 downto 0)
    );
end NoiseGen;

architecture Behavioral of NoiseGen is

    type TABLE_NOISE_V is array (0 to 100) of INTEGER range 0 to 1000000;
    constant increment : TABLE_NOISE_V := (
        0, 10000, 20000, 30000, 40000, 50000, 60000, 70000, 80000, 90000, 100000,
        110000, 120000, 130000, 140000, 150000, 160000, 170000, 180000, 190000, 200000,
        210000, 220000, 230000, 240000, 250000, 260000, 270000, 280000, 290000, 300000,
        310000, 320000, 330000, 340000, 350000, 360000, 370000, 380000, 390000, 400000,
        410000, 420000, 430000, 440000, 450000, 460000, 470000, 480000, 490000, 500000,
        510000, 520000, 530000, 540000, 550000, 560000, 570000, 580000, 590000, 600000,
        610000, 620000, 630000, 640000, 650000, 660000, 670000, 680000, 690000, 700000,
        710000, 720000, 730000, 740000, 750000, 760000, 770000, 780000, 790000, 800000,
        810000, 820000, 830000, 840000, 850000, 860000, 870000, 880000, 890000, 900000,
        910000, 920000, 930000, 940000, 950000, 960000, 970000, 980000, 990000, 1000000
    );

    signal sum : STD_LOGIC := '0';

begin 

    process(clock_in, reset_in)
        variable temp : SIGNED(BIT_DEPTH - 1 downto 0);
        variable inc : STD_LOGIC_VECTOR(19 downto 0);
    begin
        if reset_in = '0' then
            data_out <= (others => '0');
        elsif rising_edge(clock_in) then
            if start = '1' then
                if enable_in = '1' then
                    if noise_volume = 0 then
                        data_out <= data_in;
                    else
                        if noise_volume = 100 then
                            inc := std_logic_vector(to_unsigned(increment(noise_volume), 20)) XOR std_logic_vector(data_in(19 downto 0));
                        else
                            inc := std_logic_vector(to_unsigned(increment(noise_volume), 20));
                        end if;
                        
                        if sum = '1' then
                            temp := data_in + to_integer(unsigned(inc));
                            -- sumando, luego el bit de signo es negativo o es postivo pero el de la suma también
                            if data_in(BIT_DEPTH - 1) = '1' OR
                              (data_in(BIT_DEPTH - 1) = '0' AND  temp(BIT_DEPTH - 1) = '0') then
                                data_out <= temp;
                            else
                                data_out <= data_in;
                            end if;
                            sum <= '0';
                        else
                            temp := data_in - to_integer(unsigned(inc));
                            -- restando, luego el bit de signo es positivo o es negativo pero el de la resta también
                            if data_in(BIT_DEPTH - 1) = '0' OR
                              (data_in(BIT_DEPTH - 1) = '1' AND  temp(BIT_DEPTH - 1) = '1') then
                                data_out <= temp;
                            else
                                data_out <= data_in;
                            end if;
                            sum <= '1';
                        end if;
                    end if;
                end if;
            end if;
        end if;
    end process;

end Behavioral;