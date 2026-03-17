library ieee;
  use ieee.std_logic_1164.all;
  use ieee.std_logic_arith.all;
  use ieee.std_logic_unsigned.all;

entity control_unit is
  port (
    -- inputs
    op_code : in std_logic_vector(2 downto 0);
    -- outputs
    reg_dst    : out std_logic;
    ext_op     : out std_logic;
    alu_src    : out std_logic;
    branch     : out std_logic;
    jump       : out std_logic;
    alu_op     : out std_logic_vector(2 downto 0);
    mem_write  : out std_logic;
    mem_to_reg : out std_logic;
    reg_write  : out std_logic 
  );
end control_unit;

architecture behavioral of control_unit is

begin

    process(op_code)
    begin
      case op_code is
        when "000" =>
          reg_dst    <='1' ;
          ext_op     <= '0';
          alu_src    <= '0';
          branch     <= '0';
          jump       <= '0';
          alu_op     <= "000";
          mem_write  <= '0';
          mem_to_reg <= '0' ;
          reg_write  <= '1';
        when others =>
          reg_dst    <= '0';
          ext_op     <= '0';
          alu_src    <= '0';
          branch     <= '0';
          jump       <= '0';
          alu_op     <= "000";
          mem_write  <= '0';
          mem_to_reg <= '0';
          reg_write  <= '0';
      end case;
    end process;  

end behavioral;