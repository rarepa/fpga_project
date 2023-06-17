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

entity EffectDistortion is
    Port (
        clock_in        : IN STD_LOGIC;
        reset_in        : IN STD_LOGIC;
        start           : IN STD_LOGIC;
        enable_in       : IN STD_LOGIC;
        distortion_type : IN INTEGER range 0 to 2;
        distortion_gain : IN INTEGER range 0 to 100;
        data_in         : IN SIGNED(BIT_DEPTH - 1 downto 0);
        data_out        : OUT SIGNED(BIT_DEPTH - 1 downto 0)
    );
end EffectDistortion;

architecture Behavioral of EffectDistortion is

    -- con una tamaño de TABLE_MAXCLIP mayor a 100, se obtendría mayor precisión para indicar el recorte
    type TABLE_MAXCLIP is array (0 to 100) of SIGNED(BIT_DEPTH - 1 downto 0);
    constant max_value : TABLE_MAXCLIP := (
        x"7fffff",
        x"7eb850",x"7d70a2",x"7c28f4",x"7ae146",x"799998",x"7851ea",x"770a3c",x"75c28e",x"747ae0",x"733332",
        x"71eb84",x"70a3d6",x"6f5c28",x"6e147a",x"6ccccb",x"6b851d",x"6a3d6f",x"68f5c1",x"67ae13",x"666665",
        x"651eb7",x"63d709",x"628f5b",x"6147ad",x"5fffff",x"5eb851",x"5d70a3",x"5c28f5",x"5ae146",x"599998",
        x"5851ea",x"570a3c",x"55c28e",x"547ae0",x"533332",x"51eb84",x"50a3d6",x"4f5c28",x"4e147a",x"4ccccc",
        x"4b851e",x"4a3d70",x"48f5c1",x"47ae13",x"466665",x"451eb7",x"43d709",x"428f5b",x"4147ad",x"3fffff",
        x"3eb851",x"3d70a3",x"3c28f5",x"3ae147",x"399999",x"3851eb",x"370a3d",x"35c28e",x"347ae0",x"333332",
        x"31eb84",x"30a3d6",x"2f5c28",x"2e147a",x"2ccccc",x"2b851e",x"2a3d70",x"28f5c2",x"27ae14",x"266666",
        x"251eb8",x"23d709",x"228f5b",x"2147ad",x"1fffff",x"1eb851",x"1d70a3",x"1c28f5",x"1ae147",x"199999",
        x"1851eb",x"170a3d",x"15c28f",x"147ae1",x"133333",x"11eb84",x"10a3d6",x"0f5c28",x"0e147a",x"0ccccc",
        x"0b851e",x"0a3d70",x"08f5c2",x"07ae14",x"066666",x"051eb8",x"03d70a",x"028f5c",x"0147ae",x"000000"
    );

begin

    process(clock_in, reset_in)
        variable overdrive : SIGNED(BIT_DEPTH - 1 downto 0);
        variable boost : SIGNED(BIT_DEPTH - 1 downto 0);
    begin
        if reset_in = '0' then
            data_out <= (others => '0');
        elsif rising_edge(clock_in) then
            if start = '1' then
                if enable_in = '1' then
                    data_out <= data_in;
                    if distortion_type > 0 then
                        -- podemos amplificar tanto como techo queda (máximo menos el recorte)
                        boost := (2**23 - 1) - max_value(distortion_gain);
                        if data_in(BIT_DEPTH - 1) = '0' then
                            if data_in > max_value(distortion_gain) then
                                if distortion_type = 1 then
                                    -- soft_clip, no recorta por completo
                                    -- revisar: con boost es igual que en hard_clip
                                    overdrive := data_in / 4;
                                    if max_value(distortion_gain) + overdrive + boost < 0 then
                                        data_out <= max_value(distortion_gain) + boost;
                                    else
                                        data_out <= max_value(distortion_gain) + overdrive + boost;
                                    end if;
                                else
                                    -- hard_clip, recorta la señal por encima de un máximo
                                    data_out <= max_value(distortion_gain) + boost;
                                end if;
                            else
                                data_out <= data_in + boost;
                            end if;
                        else
                            if data_in < -(max_value(distortion_gain)) then
                                if distortion_type = 1 then
                                    overdrive := data_in / 4;
                                    if -(max_value(distortion_gain)) + overdrive - boost > 0 then
                                        data_out <= -(max_value(distortion_gain)) - boost;
                                    else
                                        data_out <= -(max_value(distortion_gain)) + overdrive - boost;
                                    end if;
                                else
                                    data_out <= -(max_value(distortion_gain)) - boost;
                                end if;
                            else
                                data_out <= data_in - boost;
                            end if;
                        end if;
                    end if;
                end if;
            end if;
        end if;
    end process;

end Behavioral;