----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 30.05.2024 09:03:37
-- Design Name: 
-- Module Name: Slave_TLUH - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity Slave_TLUH is
 Generic(
    Slave_ADDR : integer := 1 
 );
 
 Port (
    
    -- Clock and Reset --
    clk: in std_logic;
    rst: in std_logic;
    
    -- Channel A Handshake Signals -- 
    a_valid: in std_logic;
    a_ready: out std_logic;
    
    -- Operation Code -- 
    a_code: in std_logic_vector(2 downto 0);
    d_code: out std_logic_vector(2 downto 0);
    
    -- Parameter Code --
    a_param: in std_logic_vector(2 downto 0);
    d_param: out std_logic_vector(2 downto 0);
    
    -- Source --
    a_source: in std_logic_vector(1 downto 0);
    d_source: out std_logic_vector(1 downto 0);
    d_sink: out std_logic_vector(1 downto 0);
    
    -- Address --
    a_address: in std_logic_vector(31 downto 0); 
    
    -- Mask --
    a_mask: in std_logic_vector(3 downto 0);
    
    -- Data --
    a_data: in std_logic_vector(31 downto 0);
    d_data: out std_logic_vector(31 downto 0);
    
    -- Corrupt --
    a_corrupt: in std_logic;
    d_corrupt: out std_logic;
    d_denied: out std_logic;
    
    -- Size: 0,1,2: 2^size = n. bytes to be read/written --
    a_size : in std_logic_vector(1 downto 0); 
    d_size : out std_logic_vector(1 downto 0);
    -- Channel D Handshake Signals --
    d_valid: out std_logic;
    d_ready: in std_logic
 );
end Slave_TLUH;

architecture Behavioral of Slave_TLUH is

type regs_array is array (0 to 15) of std_logic_vector(31 downto 0); -- 16x 4 bytes => 64 bytes
signal registers : regs_array := (x"00000001", x"00000002", x"00000003", x"00000004", x"00000005", x"00000006"
                                    , x"00000007", x"00000008", x"00000009", x"0000000A", x"0000000B", x"0000000C"
                                    , x"0000000D", x"0000000E", x"0000000F", x"00000010");
                                    
signal data_in, data_out : std_logic_vector(31 downto 0);
signal prev_data : std_logic_vector(31 downto 0);
signal max_slv, maxu_slv : std_logic_vector(31 downto 0);
signal min_slv, minu_slv : std_logic_vector(31 downto 0);
signal add_slv : std_logic_vector(31 downto 0);
signal xor_slv, or_slv, and_slv, swap_slv : std_logic_vector(31 downto 0);

signal arith_op, logical_op : std_logic;
signal any_op : std_logic; 

signal arith_event, logical_event, any_event : std_logic;

signal put_regs: std_logic;
signal get_regs: std_logic;
signal min_a, max_a, add_a, minu_a, maxu_a : std_logic;
signal xor_l, or_l, and_l, swap_l : std_logic;

signal int_addr: std_logic_vector(3 downto 0);
signal word_addr: integer;
signal cs : unsigned(25 downto 0);
signal slave_select : std_logic;

signal masked_data, tmp_masked : std_logic_vector(31 downto 0);
signal offset: unsigned(1 downto 0);


signal w_denied, temp_denied: std_logic;

begin
-- Signals to recognize Operations --
    put_regs <= '1' when (a_valid = '1' and d_ready = '1') and (a_code = "000" or a_code = "001") and (a_corrupt = '0') 
                         and (slave_select = '1')
                else '0'; -- In the condition d_ready should be a_ready (but since they are assigned to be the same...)
    
    get_regs <= '1' when (a_valid = '1' and d_ready = '1') and (a_code = "100") and (a_corrupt = '0') 
                         and (slave_select = '1')
                else '0';   
   
    min_a <= '1' when (a_valid = '1' and d_ready = '1') and (arith_op = '1') and (a_corrupt = '0') 
                      and (slave_select = '1') and (a_param = "000")
                 else '0';
    
    minu_a <= '1' when (a_valid = '1' and d_ready = '1') and (arith_op = '1') and (a_corrupt = '0') 
                      and (slave_select = '1') and (a_param = "010")
                 else '0';
    
    max_a <= '1' when (a_valid = '1' and d_ready = '1') and (arith_op = '1') and (a_corrupt = '0') 
                      and (slave_select = '1') and (a_param = "001")
                 else '0';
    
    maxu_a <= '1' when (a_valid = '1' and d_ready = '1') and (arith_op = '1') and (a_corrupt = '0') 
                      and (slave_select = '1') and (a_param = "011")
                 else '0';
    
    add_a <= '1' when (a_valid = '1' and d_ready = '1') and (arith_op = '1') and (a_corrupt = '0') 
                      and (slave_select = '1') and (a_param = "100")
                 else '0';
                 
    xor_l <= '1' when (a_valid = '1' and d_ready = '1') and (logical_op = '1') and (a_corrupt = '0') 
                      and (slave_select = '1') and (a_param = "000")
                 else '0';
                 
    or_l <= '1' when (a_valid = '1' and d_ready = '1') and (logical_op = '1') and (a_corrupt = '0') 
                      and (slave_select = '1') and (a_param = "001")
                 else '0';
    
    and_l <= '1' when (a_valid = '1' and d_ready = '1') and (logical_op = '1') and (a_corrupt = '0') 
                      and (slave_select = '1') and (a_param = "010")
                 else '0';
                 
    swap_l <= '1' when (a_valid = '1' and d_ready = '1') and (logical_op = '1') and (a_corrupt = '0') 
                       and (slave_select = '1') and (a_param = "011")
                  else '0';             
-- Signals that recognize if the operation is arithmetic or logical Codes--
    arith_op <= '1' when a_code = "010" else '0';
    logical_op <= '1' when a_code = "011" else '0';
    any_op <= '1' when ((arith_op or logical_op) or (put_regs or get_regs)) = '1' else '0';

-- Signals to recognize which operation is getting done --
-- Put -> put_regs
-- Get -> get_regs
    logical_event <= '1' when (a_valid = '1' and d_ready = '1') and (logical_op = '1') and (a_corrupt = '0') 
                       and (slave_select = '1')
                     else '0';
                     
    arith_event <= '1' when (a_valid = '1' and d_ready = '1') and (arith_op = '1') and (a_corrupt = '0') 
                      and (slave_select = '1')
                   else '0';
                   
    any_event <= '1' when ((get_regs or put_regs) or (logical_event or arith_event)) = '1' else '0';
    
-- Address Decomposition --

    int_addr <= a_address(5 downto 2);
    
    offset <= unsigned(a_address(1 downto 0));
    
    cs <= unsigned(a_address(31 downto 6));
    slave_select <= '1' when cs = to_unsigned(Slave_ADDR, 26) else '0';
    
    --word_addr <= to_integer(unsigned(int_addr));
    
-- Arithmetic Operations Q: Do i really need different signals for MAXU AND MAX? Q: ADD must operate with signed or unsigned? --  
    max_slv <= a_data when (signed(a_data) >= signed(registers(to_integer(unsigned(int_addr))))) else registers(to_integer(unsigned(int_addr)));
    min_slv <= a_data when (signed(a_data) <= signed(registers(to_integer(unsigned(int_addr))))) else registers(to_integer(unsigned(int_addr)));
    maxu_slv <= a_data when (unsigned(a_data) >= unsigned(registers(to_integer(unsigned(int_addr))))) else registers(to_integer(unsigned(int_addr)));
    minu_slv <= a_data when (unsigned(a_data) <= unsigned(registers(to_integer(unsigned(int_addr))))) else registers(to_integer(unsigned(int_addr)));
    add_slv <= std_logic_vector(unsigned(a_data) + unsigned(registers(to_integer(unsigned(int_addr)))));
    xor_slv <= a_data xor registers(to_integer(unsigned(int_addr)));
    or_slv <= a_data or registers(to_integer(unsigned(int_addr)));
    and_slv <= a_data and registers(to_integer(unsigned(int_addr)));
    swap_slv <= a_data;
    
-- Internal Slave Registers --    

    data_in <= masked_data when put_regs = '1' else
               add_slv when add_a = '1' else
               max_slv when max_a = '1' else
               maxu_slv when maxu_a = '1' else
               minu_slv when minu_a = '1' else
               min_slv when min_a = '1' else
               xor_slv when xor_l = '1' else
               or_slv when or_l = '1' else
               and_slv when and_l = '1' else
               swap_slv when swap_l = '1' else
               registers(to_integer(unsigned(int_addr)));

    regs: process(clk,rst)
    begin
        if(rst = '1') then
            registers  <= (others => (others => '0')); 
            prev_data <= (others => '0');
        elsif(rising_edge(clk)) then
            prev_data <= registers(to_integer(unsigned(int_addr)));
            registers(to_integer(unsigned(int_addr))) <= data_in;  -- Maybe here careful on a_address!
        end if;   
    end process regs;
    
    data_out <= std_logic_vector(shift_right(unsigned(registers(to_integer(unsigned(int_addr)))),8*to_integer(offset))) when get_regs = '1' else
                prev_data when (arith_event or logical_event) = '1' else
                (others => '0');                
               
-- Handshaking signals of Channel A and D 
    a_ready <= d_ready;
    d_valid <= a_valid;

-- Combinational Process for PutFull and PutPartial --
    masking: process(a_data, a_mask, int_addr, a_address, a_size, registers, offset) 
    variable mas_dat: std_logic_vector(31 downto 0);
    variable cnt_size: integer := 0;
    variable j: integer := 0;
    variable access_den : std_logic := '0';
    variable prio_one: unsigned(2 downto 0);
    begin
        mas_dat:= registers(to_integer(unsigned(int_addr)))(31 downto 0);
        cnt_size := 0;
        j := 0;
        access_den := '0';
        prio_one := (others => '0');
        
        -- Priority encoder to see if the Put is Illegal --
        for k in 0 to 3 loop
            if(a_mask(k) = '1') then
                prio_one := to_unsigned(k, 3);
            end if;
        end loop;
        
        if ( to_integer((resize(offset,3) + prio_one))*8 + 7 > 31 ) then
             access_den := '1';
        else
            for i in 0 to 3 loop
                if(cnt_size < 2**(to_integer(unsigned(a_size)))) then   
                    if(a_mask(i) = '1') then
                        mas_dat(((to_integer(offset) + j)*8 + 7) downto (to_integer(offset) + j)*8) := a_data((i*8+7) downto (i*8));
                        cnt_size := cnt_size + 1;                                        
                    end if;           
                j := j + 1;
                end if;           
            end loop;
        end if;
        tmp_masked <= std_logic_vector(mas_dat);
        temp_denied <= std_logic(access_den);     
    end process masking;     
    
    masked_data <= tmp_masked;
    w_denied <= temp_denied;
 
-- Channel D Responses --
    d_code <= "000" when put_regs = '1' else --AccessAck
              "001" when ((get_regs or arith_event) or logical_event) = '1' else --AccessAckData
              "010";
              
    d_size <= a_size when any_event = '1' else (others => '0');
    d_source <= a_source;
    d_data <= data_out;
        
    -- Reserved Signals --
    d_param <= (others => '0');
    d_sink <= (others => '0');
    d_corrupt <= '1' when (w_denied and put_regs) = '1' else '0'; -- d_corrupt must be high when d_denied is high
    d_denied <= '1' when (w_denied and put_regs) = '1' else '0'; -- Tells us that the slave didn't process the access (??)

end Behavioral;
