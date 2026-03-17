library ieee;
  use ieee.std_logic_1164.all;
  use ieee.std_logic_arith.all;
  use ieee.std_logic_unsigned.all;

entity exec_unit is
  port (
    -- inputs
    ext_imm     : in std_logic_vector(15 downto 0);
    func        : in std_logic_vector(2  downto 0);
    rd1         : in std_logic_vector(15 downto 0);
    rd2         : in std_logic_vector(15 downto 0);        
    pc_plus_one : in std_logic_vector(15 downto 0);
    sa          : in std_logic;
    -- control signals
    alu_op    : in  std_logic_vector(2 downto 0);
    alu_src   : in  std_logic;
    -- outputs
    alu_res : out std_logic_vector(15 downto 0);
    bta     : out std_logic_vector(15 downto 0);
    zero    : out std_logic
  );
end entity;

architecture rtl of exec_unit is

  signal s_alu_control    : std_logic_vector(2  downto 0);
  signal s_alu_res        : std_logic_vector(15 downto 0);
  signal s_second_operand : std_logic_vector(15 downto 0);

begin

  -- ALU Control
  process (alu_op, func)
  begin
    case alu_op is
      when "000" =>
        case func is
            when "000"  => s_alu_control <= "000"; -- ADD
            when "001"  => s_alu_control <= "001"; -- SUB
            when "010"  => s_alu_control <= "010"; -- SLL
            when "011"  => s_alu_control <= "011"; -- SRL
            when "100"  => s_alu_control <= "100"; -- AND
            when "101"  => s_alu_control <= "101"; -- OR
            when others => s_alu_control <= "111";
        end case;        
      when "001"  => s_alu_control <= "000"; -- ADDI codul de la adunare
      when "010"  => s_alu_control <= "000"; -- LW codul de la adunare
      when "011"  => s_alu_control <= "000"; -- SW codul de la adunare
      when "100"  => s_alu_control <= "001"; -- BEQ codul de la scadere
      when others => s_alu_control <= "111";
    end case;
  end process;

  -- MUX for Second Operand
  s_second_operand <=Ext_imm when alu_src='0' else rd2;

  -- ALU
  process (s_alu_control, sa, rd1, s_second_operand)
  begin
    case s_alu_control is
      when "000"  => s_alu_res <=rd1+ s_second_operand ;
      when "001"  => s_alu_res <=rd1- s_second_operand;
      when "010"  => s_alu_res <= rd1(14 downto 0) & '0';
      when "011"  => s_alu_res <= '0' & rd1(15 downto 1);
      when "100"  => s_alu_res <=rd1 and s_second_operand ;
      when "101"  => s_alu_res <=rd1 or s_second_operand ;
      when others => s_alu_res <= (others => '0');
    end case;    
  end process;
  
  alu_res <= s_alu_res; -- DUE TO ZERO FLAG, output cannot be a variable for condition in 'when' statement

  -- Branch Target Address
  bta <= ext_imm + pc_plus_one ;
 
  -- Zero Flag
  zero <= '1' when s_alu_res=x"0000" else '0';

end architecture;