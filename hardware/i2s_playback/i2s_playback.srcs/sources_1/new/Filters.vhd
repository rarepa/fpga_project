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

entity Filters is
    Port (
        clock_in      : IN STD_LOGIC;
        reset_in      : IN STD_LOGIC;
        start         : IN STD_LOGIC;
        enable_in     : IN STD_LOGIC;
        frequency     : IN INTEGER range 0 to 8000;
        resonance     : IN INTEGER range 0 to 100;
        filter_type   : IN INTEGER range 0 to 4;
        filter_lfo    : IN INTEGER range 0 to 1;
        filter_lfo_d  : IN INTEGER range 0 to 1;
        lfo3_data     : IN UNSIGNED(23 downto 0);
        lfo3_mode     : IN INTEGER range 0 to 3;
        data_in       : IN SIGNED(BIT_DEPTH - 1 downto 0);
        filter_finish : OUT STD_LOGIC;
        data_out      : OUT SIGNED(BIT_DEPTH - 1 downto 0)
    );
end Filters;

--architecture Behavioral of Filters is

--    COMPONENT CutFreqROM is
--    Port (
--        clock_in  : IN STD_LOGIC;
--        addr_in   : IN INTEGER range 0 to 8000;
--        data_out  : OUT INTEGER range 0 to 70719
--    );
--    end COMPONENT;
    
--    -- resonacia desde 0.8 hasta 17.09, con incrementos de 0.1 hasta 10, a partir de 10 incrementa en 1
--    -- valores más bajos de 0.8 convierten la señal en ruido (sin embargo, no en las gráficas de Python)
--    -- parece soportar valores de resonancia superiores (menor q1), según las gráficas
--    -- pero con resonacias superiores a 3.. ¡la salida supera el máximo de 2**23 - 1! (en algunos picos)
--    type TABLE_Q1 is array (0 to 100) of INTEGER range 0 to 81920;
--    constant q1 : TABLE_Q1 := (
--        81920, 
--        72817, 65536, 59578, 54613, 50412, 46811, 43690, 40959, 38550, 36408, 
--        34492, 32767, 31207, 29789, 28493, 27306, 26214, 25206, 24272, 23405, 
--        22598, 21845, 21140, 20479, 19859, 19275, 18724, 18204, 17712, 17246, 
--        16804, 16383, 15984, 15603, 15240, 14894, 14563, 14246, 13943, 13653, 
--        13374, 13107, 12850, 12603, 12365, 12136, 11915, 11702, 11497, 11299, 
--        11107, 10922, 10743, 10570, 10402, 10240, 10082, 9929, 9781, 9637, 
--        9497, 9362, 9230, 9102, 8977, 8856, 8738, 8623, 8511, 8402, 
--        8295, 8192, 8090, 7992, 7895, 7801, 7710, 7620, 7532, 7447, 
--        7363, 7281, 7201, 7123, 7046, 6971, 6898, 6826, 6756, 6687, 
--        6619, 6553, 6488, 5904, 5416, 5002, 4647, 4340, 4070, 3832
--    );
    
--    signal addr_in : INTEGER range 0 to 8000;
--    signal cut_freq : INTEGER range 0 to 70719;
    
--    signal lowpass_o : SIGNED(BIT_DEPTH * 4 - 1 downto 0) := (others => '0');
--    signal bandpass_o : SIGNED(BIT_DEPTH * 4 - 1 downto 0) := (others => '0');
--    signal highpass_o : SIGNED(BIT_DEPTH * 4 - 1 downto 0) := (others => '0');
--    signal notch_o : SIGNED(BIT_DEPTH * 4 - 1 downto 0) := (others => '0');
    
--    signal MIN : SIGNED(BIT_DEPTH * 4 - 1 downto 0) := (BIT_DEPTH * 4 - 1 downto BIT_DEPTH - 1 => '1', others => '0');
--    signal MAX : SIGNED(BIT_DEPTH * 4 - 1 downto 0) := (BIT_DEPTH - 2 downto 0 => '1', others => '0');
    
--    signal v_f1 : INTEGER range 0 to 70719;
--    signal v_q1 : INTEGER range 0 to 81920;
    
--    signal mult_case : INTEGER range 0 to 3;
--    signal operand : INTEGER range 0 to 8000;
--    signal result : UNSIGNED(BIT_DEPTH * 2 - 1 downto 0);
    
--    signal opA : INTEGER range 0 to 100;
--    signal opB : SIGNED(BIT_DEPTH * 4 - 1 downto 0);
--    signal op_result : SIGNED(BIT_DEPTH * 4 - 1 downto 0);
--    signal step : INTEGER range 0 to 2;
    
--    type filter_state is (
--        LOAD_DATA_INI, WAIT_DATA_INI, IDLE, LFO_MULT0, LFO_MULT1, OPERATE
--        LOAD_DATA_LFO, WAIT_DATA_LFO, LOWPASS, HIGHPASS, BANDPASS, NOTCH
--    );
--    signal current_state : filter_state := IDLE;

--begin

--    -- Musical_Applications_of_Microprocessors-Charmberlin, pág 490
--    -- L = D2 + F1 * D1;
--    -- H = I - L - Q1 * D1;
--    -- B = F1 * H + D1;
--    -- N = H + L;
    
--    -- donde:
--    -- D1, delay associated with bandpass output
--    -- D2, delay associated with lowpass output
--    -- F1 = 2 * sin(((pi * frequency) / 44100))
--    -- Q1 = 1 / resonance
--    -- I = input (data_in)
    
--    --instantiate portamento rom component
--    cutfreq_rom0 : CutFreqROM
--       port map (
--       clock_in => clock_in,
--       addr_in => addr_in,
--       data_out => cut_freq
--    );
    
--    process(clock_in, reset_in)
--    begin
--        if reset_in = '0' then
--            filter_finish <= '0';
--            lowpass_o <= (others => '0');
--            highpass_o <= (others => '0');
--            bandpass_o <= (others => '0');
--            notch_o <= (others => '0');
--        elsif rising_edge(clock_in) then
--            case current_state is
--            when LOAD_DATA_INI =>
--                filter_finish <= '0';
--                addr_in <= frequency;
--                current_state <= WAIT_DATA_INI;
--            when WAIT_DATA_INI =>
--                -- ciclo de espera para que el dato de cut_freq esté disponible en IDLE
--                current_state <= IDLE;
--            when IDLE =>
--                if start = '1' then
--                    if filter_type > 0 AND enable_in = '1' then
--                        if filter_lfo = 0 then
--                            v_f1 <= cut_freq;
--                            v_q1 <= q1(resonance);
--                            current_state <= OPERATE;
--                            opA <= cut_freq;
--                        else
--                            if filter_lfo_d = 0 then -- frequency is the modulation destiny
--                                if lfo3_mode < 2 then
--                                    mult_case <= 0; -- desde 0 hasta frequency
--                                    operand <= frequency;
--                                else
--                                    mult_case <= 1; -- desde 8000 hasta frequency
--                                    operand <= 8000 - frequency;
--                                end if;
--                            else
--                                if lfo3_mode < 2 then
--                                    mult_case <= 2; -- desde 0 hasta resonance
--                                    operand <= resonance;
--                                else
--                                    mult_case <= 3; -- desde 100 hasta resonance
--                                    operand <= 100 - resonance;
--                                end if;
--                            end if;
--                            current_state <= LFO_MULT0;
--                        end if;
--                        step <= 0;
--                        opB <= bandpass_o;
--                    else
--                        lowpass_o <= (others => '0');
--                        highpass_o <= (others => '0');
--                        bandpass_o <= (others => '0');
--                        notch_o <= (others => '0');
--                        current_state <= LOAD_DATA_INI;
--                        filter_finish <= '1';
--                    end if;
--                end if;
--            when LFO_MULT0 =>
--                result <= operand * lfo3_data / POW_2_24;
--                current_state <= LOAD_DATA_LFO;
--            when LOAD_DATA_LFO =>
--                if mult_case = 0 then
--                    addr_in <= to_integer(result);
--                elsif mult_case = 1 then
--                    addr_in <= 8000 - to_integer(result);
--                end if;
--                current_state <= WAIT_DATA_LFO;
--            when WAIT_DATA_LFO =>
--                -- ciclo de espera para que el dato de cut_freq esté disponible en LFO_MULT1
--                current_state <= LFO_MULT1;
--            when LFO_MULT1 =>
--                if mult_case = 0 then
--                    v_q1 <= q1(resonance);
--                elsif mult_case = 1 then
--                    v_q1 <= q1(resonance);
--                elsif mult_case = 2 then
--                    v_q1 <= q1(to_integer(result));
--                else
--                    v_q1 <= q1(100 - to_integer(result));
--                end if;
--                v_f1 <= cut_freq;
--                opA <= cut_freq;
--                current_state <= OPERATE;
--            when OPERATE =>
--                op_result <= opA * opB(BIT_DEPTH * 2 - 1 downto 0) / POW_2_16;
--                if step = 0 then
--                    current_state <= LOWPASS;
--                elsif step = 1 then
--                    current_state <= HIGHPASS;
--                elsif step = 2 then
--                    current_state <= BANDPASS;
--                end if;
--            when LOWPASS =>
--                lowpass_o <= lowpass_o(BIT_DEPTH * 2 - 1 downto 0) + op_result;
--                current_state <= OPERATE;
--                step <= 1;
--                opA <= v_q1;
--                opB <= bandpass_o;  
--            when HIGHPASS =>
--                highpass_o <= data_in - lowpass_o(BIT_DEPTH * 2 - 1 downto 0) - op_result;
--                current_state <= BANDPASS;
--                current_state <= OPERATE;
--                step <= 2;
--                opA <= v_f1;
--                opB <= data_in - lowpass_o(BIT_DEPTH * 2 - 1 downto 0) - op_result;
--            when BANDPASS =>
--                bandpass_o <= op_result + bandpass_o(BIT_DEPTH * 2 - 1 downto 0);
--                current_state <= NOTCH;
--            when NOTCH =>
--                notch_o <= highpass_o + lowpass_o;
--                current_state <= LOAD_DATA_INI;
--                filter_finish <= '1';
--            end case;
--        end if;
--    end process;
    
--    data_out <= MIN(BIT_DEPTH - 1 downto 0) when filter_type = 1 AND lowpass_o < MIN else
--                MAX(BIT_DEPTH - 1 downto 0) when filter_type = 1 AND lowpass_o > MAX else
--                lowpass_o(BIT_DEPTH - 1 downto 0) when filter_type = 1 else
--                MIN(BIT_DEPTH - 1 downto 0) when filter_type = 2 AND highpass_o < MIN else
--                MAX(BIT_DEPTH - 1 downto 0) when filter_type = 2 AND highpass_o > MAX else
--                highpass_o(BIT_DEPTH - 1 downto 0) when filter_type = 2 else
--                MIN(BIT_DEPTH - 1 downto 0) when filter_type = 3 AND bandpass_o < MIN else
--                MAX(BIT_DEPTH - 1 downto 0) when filter_type = 3 AND bandpass_o > MAX else
--                bandpass_o(BIT_DEPTH - 1 downto 0) when filter_type = 3 else
--                MIN(BIT_DEPTH - 1 downto 0) when filter_type = 4 AND notch_o < MIN else
--                MAX(BIT_DEPTH - 1 downto 0) when filter_type = 4 AND notch_o > MAX else
--                notch_o(BIT_DEPTH - 1 downto 0) when filter_type = 4 else
--                data_in; -- filter_type = 0

--end Behavioral;

architecture Behavioral of Filters is

    COMPONENT CutFreqROM is
    Port (
        clock_in  : IN STD_LOGIC;
        addr_in   : IN INTEGER range 0 to 8000;
        data_out  : OUT INTEGER range 0 to 70719
    );
    end COMPONENT;
    
    -- resonacia desde 0.8 hasta 17.09, con incrementos de 0.1 hasta 10, a partir de 10 incrementa en 1
    -- valores más bajos de 0.8 convierten la señal en ruido (sin embargo, no en las gráficas de Python)
    -- parece soportar valores de resonancia superiores (menor q1), según las gráficas
    -- pero con resonacias superiores a 3.. ¡la salida supera el máximo de 2**23 - 1! (en algunos picos)
    type TABLE_Q1 is array (0 to 100) of INTEGER range 0 to 81920;
    constant q1 : TABLE_Q1 := (
        81920, 
        72817, 65536, 59578, 54613, 50412, 46811, 43690, 40959, 38550, 36408, 
        34492, 32767, 31207, 29789, 28493, 27306, 26214, 25206, 24272, 23405, 
        22598, 21845, 21140, 20479, 19859, 19275, 18724, 18204, 17712, 17246, 
        16804, 16383, 15984, 15603, 15240, 14894, 14563, 14246, 13943, 13653, 
        13374, 13107, 12850, 12603, 12365, 12136, 11915, 11702, 11497, 11299, 
        11107, 10922, 10743, 10570, 10402, 10240, 10082, 9929, 9781, 9637, 
        9497, 9362, 9230, 9102, 8977, 8856, 8738, 8623, 8511, 8402, 
        8295, 8192, 8090, 7992, 7895, 7801, 7710, 7620, 7532, 7447, 
        7363, 7281, 7201, 7123, 7046, 6971, 6898, 6826, 6756, 6687, 
        6619, 6553, 6488, 5904, 5416, 5002, 4647, 4340, 4070, 3832
    );
    
    signal addr_in : INTEGER range 0 to 8000;
    signal cut_freq : INTEGER range 0 to 70719;
    
    signal lowpass_o : SIGNED(BIT_DEPTH * 4 - 1 downto 0) := (others => '0');
    signal bandpass_o : SIGNED(BIT_DEPTH * 4 - 1 downto 0) := (others => '0');
    signal highpass_o : SIGNED(BIT_DEPTH * 4 - 1 downto 0) := (others => '0');
    signal notch_o : SIGNED(BIT_DEPTH * 4 - 1 downto 0) := (others => '0');
    
    signal MIN : SIGNED(BIT_DEPTH * 4 - 1 downto 0) := (BIT_DEPTH * 4 - 1 downto BIT_DEPTH - 1 => '1', others => '0');
    signal MAX : SIGNED(BIT_DEPTH * 4 - 1 downto 0) := (BIT_DEPTH - 2 downto 0 => '1', others => '0');
    
    signal v_f1 : INTEGER range 0 to 70719;
    signal v_q1 : INTEGER range 0 to 81920;
    
    signal mult_case : INTEGER range 0 to 3;
    signal operand : INTEGER range 0 to 8000;
    signal result : UNSIGNED(BIT_DEPTH * 2 - 1 downto 0);
    
    type filter_state is (
        LOAD_DATA_INI, WAIT_DATA_INI, IDLE, LFO_MULT0, LFO_MULT1,
        LOAD_DATA_LFO, WAIT_DATA_LFO, LOWPASS, HIGHPASS, BANDPASS, NOTCH
    );
    signal current_state : filter_state := IDLE;

begin

    -- Musical_Applications_of_Microprocessors-Charmberlin, pág 490
    -- L = D2 + F1 * D1;
    -- H = I - L - Q1 * D1;
    -- B = F1 * H + D1;
    -- N = H + L;
    
    -- donde:
    -- D1, delay associated with bandpass output
    -- D2, delay associated with lowpass output
    -- F1 = 2 * sin(((pi * frequency) / 44100))
    -- Q1 = 1 / resonance
    -- I = input (data_in)
    
    --instantiate portamento rom component
    cutfreq_rom0 : CutFreqROM
       port map (
       clock_in => clock_in,
       addr_in => addr_in,
       data_out => cut_freq
    );
    
    process(clock_in, reset_in)
    begin
        if reset_in = '0' then
            filter_finish <= '0';
            lowpass_o <= (others => '0');
            highpass_o <= (others => '0');
            bandpass_o <= (others => '0');
            notch_o <= (others => '0');
        elsif rising_edge(clock_in) then
            case current_state is
            when LOAD_DATA_INI =>
                filter_finish <= '0';
                addr_in <= frequency;
                current_state <= WAIT_DATA_INI;
            when WAIT_DATA_INI =>
                -- ciclo de espera necesario para que el dato de cut_freq esté disponible en IDLE
                current_state <= IDLE;
            when IDLE =>
                if start = '1' then
                    if filter_type > 0 AND enable_in = '1' then
                        if filter_lfo = 0 then
                            v_f1 <= cut_freq;
                            v_q1 <= q1(resonance);
                            current_state <= LOWPASS;
                        else
                            if filter_lfo_d = 0 then -- frequency is the modulation destiny
                                if lfo3_mode < 2 then
                                    mult_case <= 0; -- desde 0 hasta frequency
                                    operand <= frequency;
                                else
                                    mult_case <= 1; -- desde 8000 hasta frequency
                                    operand <= 8000 - frequency;
                                end if;
                            else
                                if lfo3_mode < 2 then
                                    mult_case <= 2; -- desde 0 hasta resonance
                                    operand <= resonance;
                                else
                                    mult_case <= 3; -- desde 100 hasta resonance
                                    operand <= 100 - resonance;
                                end if;
                            end if;
                            current_state <= LFO_MULT0;
                        end if;
                    else
                        lowpass_o <= (others => '0');
                        highpass_o <= (others => '0');
                        bandpass_o <= (others => '0');
                        notch_o <= (others => '0');
                        current_state <= LOAD_DATA_INI;
                        filter_finish <= '1';
                    end if;
                end if;
            when LFO_MULT0 =>
                result <= operand * lfo3_data / POW_2_24;
                current_state <= LOAD_DATA_LFO;
            when LOAD_DATA_LFO =>
                if mult_case = 0 then
                    addr_in <= to_integer(result(12 downto 0));
                elsif mult_case = 1 then
                    addr_in <= 8000 - to_integer(result(12 downto 0));
                end if;
                current_state <= WAIT_DATA_LFO;
            when WAIT_DATA_LFO =>
                -- ciclo de espera necesario para que el dato de cut_freq esté disponible en LFO_MULT1
                current_state <= LFO_MULT1;
            when LFO_MULT1 =>
                if mult_case = 0 then
                    v_q1 <= q1(resonance);
                elsif mult_case = 1 then
                    v_q1 <= q1(resonance);
                elsif mult_case = 2 then
                    v_q1 <= q1(to_integer(result(7 downto 0)));
                else
                    v_q1 <= q1(100 - to_integer(result(7 downto 0)));
                end if;
                v_f1 <= cut_freq;
                current_state <= LOWPASS;
            when LOWPASS =>
                lowpass_o <= lowpass_o(BIT_DEPTH * 2 - 1 downto 0) + (v_f1 * bandpass_o(BIT_DEPTH * 2 - 1 downto 0) / POW_2_16);
                current_state <= HIGHPASS;    
            when HIGHPASS =>
                highpass_o <= data_in - lowpass_o(BIT_DEPTH * 2 - 1 downto 0) - (v_q1 * bandpass_o(BIT_DEPTH * 2 - 1 downto 0) / POW_2_16);
                current_state <= BANDPASS;
            when BANDPASS =>
                bandpass_o <= (v_f1 * highpass_o(BIT_DEPTH * 2 - 1 downto 0) / POW_2_16) + bandpass_o(BIT_DEPTH * 2 - 1 downto 0);
                current_state <= NOTCH;
            when NOTCH =>
                notch_o <= highpass_o + lowpass_o;
                current_state <= LOAD_DATA_INI;
                filter_finish <= '1';
            end case;
        end if;
    end process;
    
    data_out <= MIN(BIT_DEPTH - 1 downto 0) when filter_type = 1 AND lowpass_o < MIN else
                MAX(BIT_DEPTH - 1 downto 0) when filter_type = 1 AND lowpass_o > MAX else
                lowpass_o(BIT_DEPTH - 1 downto 0) when filter_type = 1 else
                MIN(BIT_DEPTH - 1 downto 0) when filter_type = 2 AND highpass_o < MIN else
                MAX(BIT_DEPTH - 1 downto 0) when filter_type = 2 AND highpass_o > MAX else
                highpass_o(BIT_DEPTH - 1 downto 0) when filter_type = 2 else
                MIN(BIT_DEPTH - 1 downto 0) when filter_type = 3 AND bandpass_o < MIN else
                MAX(BIT_DEPTH - 1 downto 0) when filter_type = 3 AND bandpass_o > MAX else
                bandpass_o(BIT_DEPTH - 1 downto 0) when filter_type = 3 else
                MIN(BIT_DEPTH - 1 downto 0) when filter_type = 4 AND notch_o < MIN else
                MAX(BIT_DEPTH - 1 downto 0) when filter_type = 4 AND notch_o > MAX else
                notch_o(BIT_DEPTH - 1 downto 0) when filter_type = 4 else
                data_in; -- filter_type = 0

end Behavioral;
