library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.std_logic_arith.all;
  use ieee.std_logic_unsigned.all;

entity ram_mem is
 port (
    clk    : in std_logic;
    wen    : in  std_logic;
    en   : in  std_logic;
    addr   : in  std_logic_vector(3 downto 0);
    di   : in  std_logic_vector(15 downto 0);
    do   : out std_logic_vector(15 downto 0)
    );

end ram_mem;

architecture Behavioral of ram_mem is

type ram_array is array (0 to 15) of std_logic_vector(15 downto 0);
signal ram: ram_array:=(
                              0=>(others=>'0'),
                              1=>x"0001",
                              2=>x"0002",
                              3=>x"0003",
                              others=>(others=>'0')
   
);

begin


process(clk)
    begin
        if rising_edge(clk) then
            if wen = '1' then
                ram(conv_integer(addr))<=di;
             end if;
        end if;

    end process;

               do<=ram(conv_integer(addr));
            

 




end Behavioral;
