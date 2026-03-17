library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.std_logic_arith.all;
  use ieee.std_logic_unsigned.all;

entity memory_unit is
 port (
      clk    : in std_logic;
      mem_write    : in  std_logic;
    
     alu_res_in      : in  std_logic_vector(15 downto 0);
     rd2   : in  std_logic_vector(15 downto 0);
     mem_data   : out  std_logic_vector(15 downto 0)
   
    );

end memory_unit;


architecture Behavioral of memory_unit is

--signal rd2: std_logic_vector(15 downto 0);
--signal alu_res_in: std_logic_vector(15 downto 0);
--signal mem_data: std_logic_vector(15 downto 0);
--signal alu_res_out: std_logic_vector(15 downto 0);
 
component ram_mem is
 port (
    clk    : in std_logic;
    wen    : in  std_logic;
   -- en     : in  std_logic;
    addr   : in  std_logic_vector(3 downto 0);
    di     : in  std_logic_vector(15 downto 0);
    do     : out std_logic_vector(15 downto 0)
    );

end component;

begin 
inst_ram : ram_mem
  port map (
   clk =>clk,
   wen=>mem_write,
   addr =>alu_res_in(3 downto 0),
   di => rd2,
   do=> mem_data 
  );
  
  --alu_res_out<=alu_res_in;


end Behavioral;