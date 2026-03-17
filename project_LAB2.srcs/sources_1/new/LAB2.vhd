library ieee;
  use ieee.std_logic_1164.all;
  use ieee.std_logic_arith.all;
  use ieee.std_logic_unsigned.all;

entity LAB2 is
  port (
    clk : in  std_logic;
    btn : in  std_logic_vector(4  downto 0);
    sw  : in  std_logic_vector(15 downto 0);
    led : out std_logic_vector(15 downto 0);
    an  : out std_logic_vector(7  downto 0);
    cat : out std_logic_vector(6  downto 0)
  );
end entity LAB2;

architecture behavioral of LAB2 is
  
  signal s_mpg_out : std_logic_vector(4  downto 0) := b"0_0000";

  -- 7-segment display
  signal s_digits       : std_logic_vector(31 downto 0) := x"0000_0000";
  signal s_digits_upper : std_logic_vector(15 downto 0) := x"0000";
  signal s_digits_lower : std_logic_vector(15 downto 0) := x"0000";
  
  -- Instruction Fetch
  signal s_if_in_jump_address : std_logic_vector(15 downto 0) := x"0000";
  signal s_if_out_instruction : std_logic_vector(15 downto 0) := x"0000";
  signal s_if_out_pc_plus_one : std_logic_vector(15 downto 0) := x"0000";

  -- Main Control
  signal s_ctrl_reg_dst    : std_logic                    := '0';
  signal s_ctrl_ext_op     : std_logic                    := '0';
  signal s_ctrl_alu_src    : std_logic                    := '0';
  signal s_ctrl_branch     : std_logic                    := '0';
  signal s_ctrl_jump       : std_logic                    := '0';
  signal s_ctrl_alu_op     : std_logic_vector(2 downto 0) := b"000";
  signal s_ctrl_mem_write  : std_logic                    := '0';
  signal s_ctrl_mem_to_reg : std_logic                    := '0';
  signal s_ctrl_reg_write  : std_logic                    := '0';

  -- Instruction Decode
  signal s_id_in_reg_write : std_logic                     := '0';
  signal s_id_in_wd        : std_logic_vector(15 downto 0) := x"0000";
  signal s_id_out_ext_imm  : std_logic_vector(15 downto 0) := x"0000";
  signal s_id_out_func     : std_logic_vector(2  downto 0) := b"000";
  signal s_id_out_rd1      : std_logic_vector(15 downto 0) := x"0000";
  signal s_id_out_rd2      : std_logic_vector(15 downto 0) := x"0000";
  signal s_id_out_sa       : std_logic                     := '0';

  -- Execution Unit
  signal s_eu_out_alu_res : std_logic_vector(15 downto 0) := x"0000";
  signal s_eu_out_bta     : std_logic_vector(15 downto 0) := x"0000";
  signal s_eu_out_zero    : std_logic                     := '0';

  -- Memory Unit
  signal s_mu_in_mem_write : std_logic                     := '0';
  signal s_mu_out_mem_data : std_logic_vector(15 downto 0) := x"0000";
  signal s_mu_out_alu_res  : std_logic_vector(15 downto 0) := x"0000";

  -- Write Back unit
  signal s_wb_out_wd : std_logic_vector(15 downto 0) := x"0000";
  
  ------------////////////////////-----------registers for pipeline
signal reg_if_id: std_logic_vector(31 downto 0) := (others=>'0');
signal reg_id_ex: std_logic_vector(82 downto 0) :=(others=> '0');
signal reg_ex_mem: std_logic_vector(55 downto 0):= (others=>'0');
signal reg_mem_wb : std_logic_vector(36 downto 0) := (others => '0');

signal ex_mux_out: std_logic_vector(2 downto 0);---mux ul din ex

--------///////////////-------------------------semnale pt separare etape
signal s_exmem_branch     : std_logic;
signal s_exmem_zero       : std_logic;
signal s_exmem_bta        : std_logic_vector(15 downto 0);
signal s_exmem_reg_write  : std_logic;
signal s_exmem_mem_to_reg : std_logic;
-------------------------/////////////--------------


  -- Component Declarations
  component mpg
  port (
    clk    : in  std_logic;
    btn    : in  std_logic_vector(4  downto 0);
    enable : out std_logic_vector(4  downto 0)
  );
  end component;
  
  component seven_seg_display
  port (
    clk    : in  std_logic;
    digits : in  std_logic_vector(31  downto 0);
    an     : out std_logic_vector(7  downto 0);
    cat    : out std_logic_vector(6  downto 0)
  );
  end component;
  
  component inst_fetch
  port (
    clk                   : in  std_logic;
    branch_target_address : in  std_logic_vector(15 downto 0);
    jump_address          : in  std_logic_vector(15 downto 0);
    jump                  : in  std_logic;
    pc_src                : in  std_logic;
    pc_en                 : in  std_logic;
    pc_reset              : in  std_logic;
    instruction           : out std_logic_vector(15 downto 0);
    pc_plus_one           : out std_logic_vector(15 downto 0)
  );
  end component;

  component control_unit
  port (
    op_code    : in std_logic_vector(2 downto 0);
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
  end component;

  component instr_decode
  port (
    clk       : in  std_logic;
    instr     : in  std_logic_vector(15 downto 0);
    wd        : in  std_logic_vector(15 downto 0);
    wa        :in std_logic_vector(2 downto 0);--------------------------------for pipeline
    ext_op    : in  std_logic;
    reg_dst   : in  std_logic;
    reg_write : in  std_logic;
    ext_imm   : out std_logic_vector(15 downto 0);
    func      : out std_logic_vector(2  downto 0);
    rd1       : out std_logic_vector(15 downto 0);
    rd2       : out std_logic_vector(15 downto 0);
    sa        : out std_logic
  );
  end component;

  component exec_unit
  port (
    ext_imm     : in  std_logic_vector(15 downto 0);
    func        : in  std_logic_vector(2  downto 0);
    rd1         : in  std_logic_vector(15 downto 0);
    rd2         : in  std_logic_vector(15 downto 0);
    pc_plus_one : in  std_logic_vector(15 downto 0);
    sa          : in  std_logic;
    alu_op      : in  std_logic_vector(2  downto 0);
    alu_src     : in  std_logic;
    alu_res     : out std_logic_vector(15 downto 0);
    bta         : out std_logic_vector(15 downto 0);
    zero        : out std_logic
  );
  end component;

  component memory_unit 
  port (
    clk         : in  std_logic;
    alu_res_in  : in  std_logic_vector(15 downto 0);
    rd2         : in  std_logic_vector(15 downto 0);
    mem_write   : in  std_logic;
    mem_data    : out std_logic_vector(15 downto 0)
   -- alu_res_out : out std_logic_vector(15 downto 0)
  );
  end component;

-----------------------registers for the pipeline implemetation
begin

 mpg_inst : mpg
  port map (
    clk => clk,
    btn => btn,
    enable => s_mpg_out
  );
  
  seven_seg_disp_inst: seven_seg_display
  port map (
    clk    => clk,
    digits => s_digits,
    an     => an,
    cat    => cat
  );
  
  infe : inst_fetch
  port map (
    clk                    => clk,
    --branch_target_address  => s_eu_out_bta,
    branch_target_address=>s_exmem_bta,-------------////-------------
    jump_address           => s_if_in_jump_address,
    jump                   => s_ctrl_jump,
   -- pc_src                 => s_ctrl_branch,
    pc_src                =>s_exmem_branch and s_exmem_zero,-----------/////////----------
    pc_en                  => s_mpg_out(0),
    pc_reset               => s_mpg_out(1),
    instruction            => s_if_out_instruction,
    pc_plus_one            => s_if_out_pc_plus_one
  );

  inst_cu : control_unit
  port map (
    op_code    => s_if_out_instruction(15 downto 13),
    reg_dst    => s_ctrl_reg_dst,
    ext_op     => s_ctrl_ext_op,
    alu_src    => s_ctrl_alu_src,
    branch     => s_ctrl_branch,
    jump       => s_ctrl_jump,
    alu_op     => s_ctrl_alu_op,
    mem_write  => s_ctrl_mem_write,
    mem_to_reg => s_ctrl_mem_to_reg,
    reg_write  => s_ctrl_reg_write
  );

  instr_decode_inst : instr_decode
  port map (
    clk       => clk,
   -- instr     => s_if_out_instruction,
    instr     =>reg_if_id(15 downto 0),---------////////////--------------
    wd        => s_id_in_wd,
    wa         =>reg_mem_wb(36 downto 34),
    ext_op    => s_ctrl_ext_op,
   -- reg_dst   => s_ctrl_reg_dst,
    reg_dst    =>reg_id_ex(10),
    reg_write => s_id_in_reg_write,  --il am mai jos facut cu o formula
    ext_imm   => s_id_out_ext_imm,
    func      => s_id_out_func,
    rd1       => s_id_out_rd1,
    rd2       => s_id_out_rd2,
    sa        => s_id_out_sa
  );

  exec_unit_inst : exec_unit
  port map (
   -- ext_imm     => s_id_out_ext_imm,
   -- func        => s_id_out_func,
   -- rd1         => s_id_out_rd1,
   -- rd2         => s_id_out_rd2,
   -- pc_plus_one => s_if_out_pc_plus_one,
   -- sa          => s_id_out_sa,
    --alu_op      => s_ctrl_alu_op,
    --alu_src     => s_ctrl_alu_src,
    ext_imm     =>  reg_id_ex(50 downto 35),----------////////----------
    func        => reg_id_ex(34 downto 32),---------////////----------
    rd1         => reg_id_ex(82 downto 67),---------////--------
    rd2         => reg_id_ex(66 downto 51),-----------///////////----
    pc_plus_one => reg_id_ex(30 downto 15),----//////-------
    sa          => reg_id_ex(31),----------///////---------
    alu_op      => reg_id_ex(14 downto 12),-----------///////----------
    alu_src     => reg_id_ex(11),-----///////////---------

    alu_res     => s_eu_out_alu_res,
    bta         => s_eu_out_bta,
    zero        => s_eu_out_zero
  );

  inst_mu: memory_unit
  port map (
    clk         => clk,
    --alu_res_in  => s_eu_out_alu_res,
    --rd2         => s_id_out_rd2,
    --mem_write   => s_mu_in_mem_write,
    alu_res_in  => reg_ex_mem(52 downto 37), --//-- sau (3 downto 0) dacă iei doar cei 4 LSB,????????
    rd2         => reg_ex_mem(19 downto 4),---------///////----------
    mem_write   => reg_ex_mem(2) and s_mpg_out(0),-------------de la linia 362 /////////--------
    mem_data    => s_mu_out_mem_data
    
  );
  
  -------------/////////////procese pipeline
  --if/id
  process(clk)
begin
if rising_edge(clk) then
  if s_mpg_out(0)='1' then
   reg_if_id(31 downto 16) <=s_if_out_pc_plus_one;
   reg_if_id(15 downto 0)<= s_if_out_instruction;
end if;
end if;
end process;

----------------------id/ex
process(clk)
begin
if rising_edge(clk) then
if s_mpg_out(0)='1' then
 --data:
  reg_id_ex(82 downto 67) <= s_id_out_rd1;              --16 bits
  reg_id_ex(66 downto 51)<= s_id_out_rd2;                  --16 bits
  reg_id_ex(50 downto 35)<= s_id_out_ext_imm;                --16 bits
  reg_id_ex(34 downto 32)<= s_id_out_func;                  -- 3 bits
  reg_id_ex(31)<= s_id_out_sa;                             --1 bit
  reg_id_ex(30 downto 15)<= reg_if_id(31 downto 16); --pc+1   16 bits

--control:EX
  reg_id_ex(14 downto 12)<= s_ctrl_alu_op;  --ALUOp 3 bits
  reg_id_ex(11)<=s_ctrl_alu_src;            --ALUSrc  1 bit
  reg_id_ex(10)<=s_ctrl_reg_dst;            --REGDst not passing/ passing it if I move the mux  1bit

--control: M
  reg_id_ex(9)<= s_ctrl_branch;           --Branch  1 bit
  reg_id_ex(8)<=s_ctrl_mem_write;         --MemWrite  1 bit

--control: WB
  reg_id_ex(7)<= s_ctrl_reg_write;    --RegWrite 1 bit
  reg_id_ex(6)<= s_ctrl_mem_to_reg;   --MemtoReg 1 bit
  --
  reg_id_ex(5 downto 3)<=reg_if_id(9 downto 7); --rt  3 bits
  reg_id_ex(2 downto 0)<=reg_if_id(6 downto 4); --rd  --3bits
  
end if;
end if;
end process;


ex_mux_out<= reg_id_ex(5 downto 3) when reg_id_ex(10)='1' else reg_id_ex(2 downto 0);

---------------EX/MEM--------------
process(clk)
begin
if rising_edge(clk) then
if s_mpg_out(0)='1' then
 --data:
  reg_ex_mem(55 downto 53)<=ex_mux_out;  ---------------------------------------- ex mux out
  reg_ex_mem(52 downto 37) <= s_eu_out_alu_res; --ALU result
  reg_ex_mem(36)<= s_eu_out_zero;             --zero
  reg_ex_mem(35 downto 20) <= s_eu_out_bta;  --bta  
  reg_ex_mem(19 downto 4)<= reg_id_ex(66 downto 51); --rd2 din id/ex

--control:
  reg_ex_mem(3)<=reg_id_ex(9); --Branch
  reg_ex_mem(2)<= reg_id_ex(8); --MemWrite
  reg_ex_mem(1)<=reg_id_ex(7); --RegWrite    
  reg_ex_mem(0)<= reg_id_ex(6);  --MemtoReg
  
  --NEED TO ADD ex_mux_out
end if;
end if;
end process;

s_exmem_branch     <= reg_ex_mem(3);
s_exmem_zero       <= reg_ex_mem(36);
s_exmem_bta        <= reg_ex_mem(35 downto 20);
s_exmem_reg_write  <= reg_ex_mem(1);
s_exmem_mem_to_reg <= reg_ex_mem(0);


--------------/////////////MEM/WB
process(clk)
begin
  if rising_edge(clk) then
  if s_mpg_out(0)='1' then
    
     reg_mem_wb(36 downto 34)<=reg_ex_mem(55 downto 53); -----------------------------------------ex mux out
      reg_mem_wb(33 downto 18) <= s_mu_out_mem_data;
      reg_mem_wb(17 downto 2)  <= reg_ex_mem(52 downto 37); -- alu_res din EX/MEM
      reg_mem_wb(1)            <= reg_ex_mem(1); -- RegWrite
      reg_mem_wb(0)            <= reg_ex_mem(0); -- MemToReg
      
      --NEED TO ADD ex_mux_out and to add the wa in the component instr decode for the register file
    end if;
  end if;
end process;

-------/////////------------------------------------


  -- IF related
  s_if_in_jump_address <= x"00" &  reg_if_id(15 downto 0);

  -- ID related
  --s_id_in_reg_write <= s_ctrl_reg_write and s_mpg_out(0);
  --s_id_in_wd        <= s_wb_out_wd;
  s_id_in_reg_write <= reg_mem_wb(1) and s_mpg_out(0);
s_id_in_wd        <= s_wb_out_wd;

  -- MU related
  s_mu_in_mem_write <= s_ctrl_mem_write and s_mpg_out(0);

  -- WB related
 -- s_wb_out_wd <= s_mu_out_mem_data when s_ctrl_mem_to_reg = '1' else s_mu_out_alu_res;
 s_wb_out_wd <= reg_mem_wb(33 downto 18) when reg_mem_wb(0) = '1' else reg_mem_wb(17 downto 2);

 
 
  
  -- MUX for 7-segment display left side (31 downto 16)
  process (sw(11 downto 9), s_if_out_pc_plus_one, s_if_out_instruction, s_id_out_rd1, s_id_out_rd2, s_id_in_wd)
  begin
    case sw(11 downto 9) is
      when "000"  => s_digits_upper <= s_if_out_instruction;
      when "001"  => s_digits_upper <= s_if_out_pc_plus_one;
      when "010"  => s_digits_upper <= s_id_out_rd1;
      when "011"  => s_digits_upper <= s_id_out_rd2;
      when "100"  => s_digits_upper <= s_id_out_ext_imm;
      when "101"  => s_digits_upper <= s_eu_out_alu_res;
      when "110"  => s_digits_upper <= s_mu_out_mem_data;
      when "111"  => s_digits_upper <= s_wb_out_wd;
    end case;
  end process;

  -- MUX for 7-segment display right side (15 downto 0)
  process (sw(6 downto 4), s_if_out_pc_plus_one, s_if_out_instruction, s_id_out_rd1, s_id_out_rd2, s_id_in_wd)
  begin
    case sw(6 downto 4) is
      when "000"  => s_digits_lower <= s_if_out_instruction;
      when "001"  => s_digits_lower <= s_if_out_pc_plus_one;
      when "010"  => s_digits_lower <= s_id_out_rd1;
      when "011"  => s_digits_lower <= s_id_out_rd2;
      when "100"  => s_digits_lower <= s_id_out_ext_imm;
      when "101"  => s_digits_lower <= s_eu_out_alu_res;
      when "110"  => s_digits_lower <= s_mu_out_mem_data;
      when "111"  => s_digits_lower <= s_wb_out_wd;
    end case;
  end process;

  s_digits <= s_digits_upper & s_digits_lower;

  -- LED with signals from Main Control Unit
  led <= s_ctrl_alu_op     & -- ALU operation        15:13
         b"0000_0"         & -- Unused               12:8
         s_ctrl_reg_dst    & -- Register destination 7
         s_ctrl_ext_op     & -- Extend operation     6
         s_ctrl_alu_src    & -- ALU source           5
         s_ctrl_branch     & -- Branch               4
         s_ctrl_jump       & -- Jump                 3
         s_ctrl_mem_write  & -- Memory write         2
         s_ctrl_mem_to_reg & -- Memory to register   1
         s_ctrl_reg_write;   -- Register write       0


end architecture behavioral; 