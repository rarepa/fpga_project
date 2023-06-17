library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity PortaROM is
    Port (
        clock_in  : IN STD_LOGIC;
        addr_in   : IN INTEGER range 0 to 5390;
        data_out  : OUT INTEGER range 0 to 5512
    );
end PortaROM;

architecture Behavioral of PortaROM is

    type TYPE_PORTAWAIT is array (0 to 5390) of INTEGER range 0 to 5512;
	signal portawait : TYPE_PORTAWAIT := (
	    0,5512,2756,1837,1378,1102,918,787,689,612,551,501,459,424,393,367,344,324,306,290,275,262,250,239,229,220,212,204,196,190,183,177,172,167,162,157,153,148,145,141,137,134,131,128,125,122,119,117,114,112,110,
        108,106,104,102,100,98,96,95,93,91,90,88,87,86,84,83,82,81,79,78,77,76,75,74,73,72,71,70,69,68,68,67,66,65,64,64,63,62,61,61,60,59,59,58,58,57,56,56,55,55,
        54,54,53,53,52,52,51,51,50,50,49,49,48,48,47,47,47,46,46,45,45,45,44,44,44,43,43,43,42,42,42,41,41,41,40,40,40,39,39,39,39,38,38,38,38,37,37,37,36,36,
        36,36,36,35,35,35,35,34,34,34,34,34,33,33,33,33,33,32,32,32,32,32,31,31,31,31,31,30,30,30,30,30,30,29,29,29,29,29,29,29,28,28,28,28,28,28,27,27,27,27,
        27,27,27,27,26,26,26,26,26,26,26,26,25,25,25,25,25,25,25,25,24,24,24,24,24,24,24,24,24,23,23,23,23,23,23,23,23,23,23,22,22,22,22,22,22,22,22,22,22,22,
        21,21,21,21,21,21,21,21,21,21,21,21,20,20,20,20,20,20,20,20,20,20,20,20,20,19,19,19,19,19,19,19,19,19,19,19,19,19,19,19,18,18,18,18,18,18,18,18,18,18,
        18,18,18,18,18,18,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,15,15,15,15,15,15,
        15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,13,13,13,13,13,13,13,
        13,13,13,0,13,13,13,13,13,13,13,13,13,13,13,13,13,13,13,13,13,13,13,13,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,
        12,12,12,12,12,12,12,12,12,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,0,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,
        11,10,10,10,10,10,10,0,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,0,10,10,10,10,10,10,10,10,10,10,10,
        10,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,
        9,9,9,9,9,9,9,9,0,9,9,9,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,0,8,8,8,8,8,8,0,8,8,8,
        8,8,8,0,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,0,8,0,8,8,8,0,8,8,0,8,8,7,7,7,7,0,7,7,7,7,7,7,
        7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,0,7,0,7,7,7,0,7,7,7,7,0,7,7,7,7,7,7,0,7,7,7,7,7,7,7,7,7,7,7,7,7,7,
        7,7,7,7,7,0,7,7,7,7,0,7,0,7,7,7,7,7,0,7,0,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,6,6,6,6,6,6,6,6,6,6,6,6,6,
        6,6,6,0,6,6,6,0,0,6,6,6,6,6,6,6,0,6,6,6,6,6,6,6,6,6,6,6,0,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,
        6,6,6,0,0,6,0,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,0,6,6,0,6,6,6,0,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,0,6,
        6,6,6,6,0,6,0,6,6,6,6,0,6,6,6,6,0,6,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,
        5,5,0,5,5,0,5,5,0,5,0,0,5,5,5,5,5,5,0,5,5,5,5,5,5,5,5,5,5,0,5,5,5,5,5,5,5,5,5,0,5,5,5,5,5,5,5,5,5,5,
        5,5,5,5,5,5,5,5,0,5,5,5,5,5,0,0,5,0,0,5,5,0,5,5,0,5,5,5,0,5,5,5,5,5,5,0,5,0,5,0,5,5,0,5,5,0,5,5,5,5,
        5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,0,5,5,5,0,5,5,0,5,0,0,5,5,5,5,0,0,5,0,0,5,0,5,0,5,5,5,5,0,5,0,5,
        5,5,0,4,4,4,4,4,0,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,0,4,4,4,0,4,4,0,0,4,0,0,4,4,0,4,0,0,
        4,0,4,4,0,4,4,0,4,4,4,4,4,4,0,4,0,4,0,4,4,4,4,0,4,4,0,4,4,4,0,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,0,4,
        4,4,4,0,4,4,4,0,4,0,0,0,4,0,4,4,0,0,4,0,0,4,0,0,4,0,4,4,4,4,0,0,4,4,4,4,4,0,4,4,4,4,4,4,0,4,4,4,4,4,
        4,0,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,0,4,0,4,4,4,0,4,4,0,0,0,4,0,0,4,0,4,4,4,0,4,4,0,0,4,0,0,4,0,4,
        4,4,4,4,0,4,4,0,4,0,4,0,4,4,4,4,4,0,4,4,0,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,0,4,4,4,
        4,0,4,4,0,0,0,4,0,0,4,4,4,0,4,0,4,0,4,0,0,4,0,0,4,4,4,4,0,3,3,0,0,3,0,3,3,0,3,0,3,3,3,3,3,0,3,3,3,3,
        3,3,3,0,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,0,0,3,0,3,0,0,3,3,0,0,3,0,0,0,0,3,3,0,3,3,0,3,3,
        0,0,3,3,0,0,3,0,0,3,0,3,3,0,0,3,0,0,3,3,3,0,3,3,3,3,3,3,0,3,0,3,3,3,3,3,3,3,0,3,3,3,0,3,3,3,3,3,3,3,
        3,3,3,3,3,3,3,3,3,3,3,0,0,3,3,0,3,0,3,3,0,0,0,3,0,0,0,3,3,3,0,0,3,0,3,0,3,0,3,3,0,0,0,3,0,0,3,3,0,3,
        0,0,3,0,0,3,3,0,3,0,3,3,3,3,3,3,0,3,0,3,0,3,0,3,3,0,3,3,3,3,3,3,0,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
        3,0,0,3,3,0,3,0,3,0,3,0,0,3,0,0,0,0,3,3,0,3,3,3,0,3,0,3,0,0,3,3,0,0,3,0,0,3,3,3,3,3,0,0,3,3,0,3,0,3,
        3,0,0,3,3,3,0,0,3,0,3,0,3,3,3,0,3,0,3,3,0,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,0,0,3,3,
        3,3,0,0,0,3,3,0,0,0,3,0,0,0,0,3,0,3,0,3,3,0,0,3,3,0,0,3,3,3,0,3,0,3,0,3,3,0,3,3,3,0,3,3,0,0,3,3,0,3,
        0,0,3,0,3,3,3,3,0,0,3,3,3,0,3,3,3,3,3,0,3,3,3,3,3,0,3,3,3,0,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,0,0,3,
        3,3,3,0,0,0,3,3,0,0,0,0,3,0,0,0,3,3,0,3,0,3,3,0,0,3,0,3,0,0,3,3,0,0,0,3,3,0,2,2,2,2,2,2,0,0,2,2,0,0,
        2,2,0,2,0,0,2,0,2,2,2,0,2,0,2,0,2,2,0,2,2,2,2,2,0,2,0,2,2,0,2,2,0,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,
        2,2,2,2,0,0,2,2,2,2,0,0,0,2,2,0,0,0,0,2,0,0,0,0,0,2,0,2,0,2,2,0,0,0,2,2,0,0,0,2,2,0,0,0,2,0,0,2,2,2,
        2,2,0,2,0,0,2,0,0,0,2,2,0,2,0,0,2,0,2,2,0,2,2,0,0,2,0,2,2,0,2,2,2,2,2,0,2,0,2,2,2,2,0,2,2,2,2,2,2,2,
        2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,0,0,2,2,2,0,2,0,0,0,2,2,0,0,0,0,2,0,0,0,0,0,2,0,2,0,0,2,2,0,0,2,0,
        2,0,0,0,2,2,0,0,0,2,2,0,0,2,2,0,2,0,2,2,0,0,0,2,0,0,2,2,0,0,2,0,0,2,0,0,2,0,2,2,0,0,2,0,2,2,0,2,2,0,
        2,2,2,0,2,0,2,2,2,0,2,2,0,2,2,2,2,2,2,0,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,0,0,0,2,0,2,0,2,0,0,2,0,2,
        0,0,0,0,2,0,0,0,0,0,2,0,0,2,0,0,2,0,0,0,0,2,2,0,0,0,2,2,0,0,0,0,2,0,0,2,0,2,0,2,2,2,0,0,0,2,2,0,0,0,
        2,2,0,2,0,0,0,2,0,0,2,0,2,2,0,0,2,0,0,2,2,0,2,2,2,2,2,2,0,2,0,2,0,2,0,2,0,2,2,2,2,2,2,2,2,2,0,2,2,2,
        2,2,2,2,2,2,2,2,2,2,2,2,2,2,0,0,0,2,2,0,2,2,0,0,0,2,0,2,0,0,0,0,2,0,0,0,0,0,0,2,2,0,2,0,0,2,0,0,0,0,
        2,2,0,0,0,0,2,2,0,0,0,0,2,0,0,0,0,2,0,2,0,2,2,0,0,0,2,2,0,0,0,2,2,0,0,2,0,0,2,0,0,2,2,0,2,2,0,0,2,0,
        0,2,2,0,2,2,0,2,2,2,0,0,2,0,2,2,2,0,2,0,2,0,2,2,0,2,2,2,2,2,2,0,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,0,
        0,0,2,2,0,2,2,0,0,0,0,2,2,0,0,0,0,0,2,0,0,0,0,0,0,2,2,0,2,0,0,0,2,0,0,0,2,0,2,0,0,0,0,2,2,0,0,0,0,0,
        2,0,0,0,0,2,2,2,0,0,2,0,0,0,0,2,2,0,0,2,2,0,0,0,2,0,0,0,2,0,2,2,0,2,0,2,0,0,2,0,0,2,2,0,2,2,2,2,0,2,
        2,0,2,0,0,2,2,2,0,2,0,2,0,2,2,2,2,2,2,2,0,2,2,2,0,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,0,0,0,2,0,2,0,0,
        2,0,0,0,2,0,2,0,0,0,0,0,2,0,0,0,0,0,0,2,2,0,0,2,0,0,2,0,0,0,0,0,2,2,0,0,0,0,0,2,0,0,0,0,0,2,0,0,0,0,
        0,2,2,0,2,0,2,0,0,0,0,2,2,0,0,0,2,0,2,0,2,0,0,0,0,2,2,2,0,2,0,2,2,0,0,0,2,0,0,2,2,0,2,0,2,2,2,0,2,0,
        0,2,0,2,0,0,2,0,2,0,2,0,2,0,2,0,2,2,0,2,2,2,2,2,2,0,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,0,0,0,2,2,0,2,
        0,2,0,0,0,0,2,0,2,0,0,0,0,0,0,2,0,0,0,0,0,0,2,2,0,0,2,0,0,0,2,0,0,0,2,0,0,2,0,0,0,0,0,2,2,0,0,0,0,0,
        2,0,0,0,0,0,1,0,0,1,1,0,1,0,0,0,0,1,0,0,0,0,1,0,1,0,0,1,0,0,0,1,1,0,1,0,1,0,1,0,1,0,0,1,0,0,1,1,1,0,
        1,1,0,1,0,0,1,0,0,1,0,0,1,0,1,0,0,1,0,1,0,1,0,1,0,1,1,1,1,0,1,1,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
        1,1,1,1,0,0,0,0,1,0,1,1,0,0,0,0,0,1,0,1,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,1,0,0,1,0,0,1,0,1,0,0,0,1,0,0,
        1,0,0,0,0,0,1,1,0,0,0,0,0,1,1,0,0,0,0,0,1,0,0,1,0,1,1,0,0,0,0,1,1,0,0,0,0,1,0,1,0,0,1,0,0,0,1,1,0,0,
        1,1,0,0,1,0,1,0,0,0,1,0,0,1,1,0,0,1,1,1,1,0,1,1,0,0,1,0,0,1,0,1,1,0,1,0,0,1,0,1,1,1,0,1,1,1,1,1,1,1,
        1,1,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,0,0,0,1,1,0,0,0,1,0,0,0,0,1,1,0,0,0,0,0,0,0,1,0,0,
        0,0,0,0,0,0,1,1,0,1,0,0,0,0,1,1,0,0,0,0,1,0,0,1,0,0,0,0,1,1,1,0,0,0,0,0,1,1,0,0,0,0,0,0,1,0,1,0,0,1,
        1,0,0,0,0,0,1,0,0,0,0,0,1,1,0,0,0,1,0,0,0,0,1,1,0,1,0,1,0,1,0,1,0,0,0,0,1,0,0,1,1,0,0,1,1,0,0,1,0,1,
        1,0,0,1,0,0,1,0,1,1,0,0,1,0,1,0,0,1,0,1,0,1,0,1,0,1,0,1,1,0,1,1,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
        1,1,1,1,0,0,0,1,0,0,1,0,0,1,0,0,0,0,1,0,0,1,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,1,1,0,0,0,1,0,0,0,1,1,0,0,
        0,0,1,0,0,1,0,0,0,0,0,0,1,1,0,0,0,0,0,0,1,0,0,0,0,0,0,1,1,0,0,1,0,1,1,0,0,0,0,0,1,1,0,0,0,0,1,0,0,1,
        0,0,1,0,0,0,0,1,1,0,0,0,1,0,0,0,1,1,0,0,0,1,0,0,0,1,1,1,0,0,1,0,1,1,0,0,0,1,0,0,1,0,0,1,0,0,1,1,0,1,
        0,0,1,0,1,0,0,1,0,1,0,1,0,1,0,1,0,1,1,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,0,0,0,0,1,
        0,1,0,1,0,0,0,0,0,0,1,0,0,1,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,1,0,0,0,1,0,0,0,1,1,0,0,0,0,0,0,0,0,1,
        0,0,0,0,0,0,1,0,1,0,0,0,0,0,1,0,1,0,0,0,0,0,0,1,0,0,1,0,0,1,1,0,0,0,0,1,0,1,0,0,0,0,0,1,0,1,0,0,0,1,
        0,0,0,0,1,1,0,0,0,0,1,0,0,1,0,1,0,0,0,0,1,0,0,0,1,0,0,0,0,1,1,0,1,1,1,0,1,0,0,0,1,0,0,1,0,0,1,0,0,1,
        0,0,1,0,0,1,0,1,0,0,1,1,1,1,1,0,1,0,1,0,1,1,0,1,1,1,1,1,1,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,0,0,
        0,1,0,1,0,0,1,0,0,0,0,0,0,1,0,1,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,1,1,0,0,0,1,0,0,0,0,1,1,0,0,0,0,
        0,0,0,0,1,0,0,0,0,0,0,1,1,1,0,0,0,0,0,0,0,1,1,0,0,0,0,0,0,0,1,0,1,0,0,1,0,1,0,0,0,0,0,0,1,0,0,0,0,0,
        0,1,1,0,0,0,0,1,0,0,0,0,0,1,1,0,0,0,0,1,0,1,0,0,1,0,0,0,0,1,0,0,0,1,1,0,0,0,1,1,0,0,1,1,0,1,0,1,0,0,
        1,0,0,0,1,0,1,1,0,0,1,0,0,1,0,0,1,0,0,1,0,1,1,0,1,1,1,0,1,0,1,0,1,0,1,1,0,1,1,1,1,1,1,0,1,1,1,1,1,1,
        1,1,1,1,1,1,1,1,1,1,1,0,0,0,1,0,0,0,1,0,1,0,0,0,0,0,0,1,0,0,1,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,
        1,1,0,0,0,0,1,0,0,0,1,1,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,1,1,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,1,0,
        0,0,1,0,1,0,1,0,0,0,0,0,0,1,0,0,0,0,0,0,1,0,0,1,0,0,0,1,0,0,0,0,0,1,1,0,0,0,0,1,0,0,0,1,0,1,0,0,0,0,
        1,0,0,0,0,1,0,1,0,0,1,0,1,0,1,0,0,0,1,1,0,0,0,1,0,0,1,0,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,1,0,1,
        1,0,1,1,1,0,1,0,1,0,1,1,0,1,1,0,1,1,1,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,0,0,0,0,1,0,1,0,0,0,1,0,
        0,0,0,0,0,1,0,0,1,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,1,0,0,0,0,0,1,1,0,0,0,0,0,0,0,0,
        0,0,1,0,0,0,0,0,0,0,1,0,1,0,0,0,0,0,0,0,1,1,0,0,0,0,0,0,0,0,1,0,0,0,1,0,0,1,0,1,0,0,0,0,0,0,0,1,0,0,
        0,0,0,0,1,0,1,0,0,0,0,1,0,0,0,0,0,0,1,0,0,0,0,0,1,0,0,1,0,0,1,0,0,0,0,0,1,0,0,0,1,1,0,0,0,0,1,1,0,0,
        0,1,0,0,1,1,0,0,0,0,1,0,0,0,1,0,1,1,0,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,1,0,1,0,1,0,0,1,0,1,0,1,0,1,0,1,
        0,1,1,0,1,1,0,1,1,1,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,0,0,0,1,0,0,0,0,0,0,1,0,0,0,0,0,0,1,0,0,1,
        0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,1,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,
        0,0,0,0,1,0,1,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,1,1,0,0,0,1,0,1,0,1,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,
        0,1,0,0,1,0,0,0,1,0,0,0,0,0,0,1,1,0,0,0,0,0,1,0,0,0,1,0,1,0,0,0,0,0,1,0,0,0,0,1,1,0,0,0,0,1,0,1,0,0,
        1,0,0,0,1,1,0,0,0,1,0,0,0,0,1,0,0,1,1,0,0,1,0,0,0,1,0,0,1,0,0,1,0,0,1,0,1,1,0,0,1,0,1,0,0,1,0,1,0,1,
        0,1,0,1,1,1,1,0,1,1,0,1,1,1,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,0,0,0,0,1,0,0,0,0,0,1,0,0,0,0,0,0,
        0,0,1,0,0,1,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,1,0,0,0,0,0,1,1,0,0,0,0,0,0,0,
        0,0,0,0,1,0,0,0,0,0,0,0,0,0,1,1,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,1,0,0,0,1,0,0,0,0,1,0,0,0,0,
        0,0,0,0,1,0,0,0,0,0,0,0,0,1,0,0,1,0,0,0,0,1,0,0,0,0,0,0,1,0,0,0,0,0,0,1,0,0,0,0,1,0,1,0,0,0,0,0,1,0,
        0,0,0,0,1,0,0,0,0,0,1,0,1,0,0,1,0,0,1,0,1,0,0,0,0,1,0,0,0,1,0,0,0,1,1,0,0,0,1,0,0,1,0,0,0,1,0,0,1,0,
        0,1,0,1,1,0,1,1,0,0,1,0,1,0,0,1,0,1,0,1,0,1,1,1,0,1,1,0,1,1,0,1,1,1,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
        1,1,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,
        0,0,1,0,0,0,0,1,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,1,0,0,1,0,0,0,0,0,0,0,0,0,
        0,1,0,0,0,0,0,0,0,0,0,0,1,0,0,0,1,0,0,0,0,0,1,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,1,0,1,0,0,0,0,0,0,1,
        0,0,0,0,0,0,0,1,0,0,0,0,0,0,1,0,0,0,1,0,0,1,0,0,0,0,0,0,1,0,0,0,0,0,1,0,0,0,0,0,1,0,1,0,0,0,1,0,0,0,
        0,1,0,0,0,0,1,0,0,0,0,1,0,0,1,1,0,0,0,0,1,0,0,0,1,0,0,1,0,0,0,1,0,0,1,1,0,1,0,0,1,0,0,1,0,0,1,0,1,0,
        0,1,0,1,0,1,0,1,0,1,0,1,1,0,1,1,0,1,1,1,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,0,0,0,1,0,0,0,0,0,0,0,
        0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,
        0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,
        0,0,0,1,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,
        0,1,0,0,0,0,0,0,0,1,0,0,0,0,0,0,1,0,0,0,0,0,0,1,0,0,0,0,0,0,1,0,0,0,0,0,1,0,0,0,0,0,1,0,0,0,0,0,1,0,
        0,0,0,1,0,0,0,0,1,0,0,0,0,1,0,0,0,1,0,0,0,0,1,0,0,0,1,0,0,1,0,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,
        1,0,0,1,0,1,0,1,0,1,0,1,0,1,1,0,1,1,0,1,1,1,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
	);
	
	-- para que se utilice Block RAM (en lugar de LUT), específico para Xilinx
--    attribute rom_style : string;
--    attribute rom_style of portawait : signal is "block";


begin

    process(clock_in)
    begin
        if rising_edge(clock_in) then
            data_out <= portawait(addr_in);
        end if;
    end process;

end Behavioral;