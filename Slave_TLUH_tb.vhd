library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity Slave_TLUH_tb is
--  Port ( );
end Slave_TLUH_tb;

architecture Behavioral of Slave_TLUH_tb is

component Slave_TLUH
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
    a_address: in std_logic_vector(31 downto 0); -- to represent from 0 to 15
    
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
end component;

signal a_source_tb : std_logic_vector(1 downto 0) := "00";
signal d_source_tb : std_logic_vector(1 downto 0);
signal d_sink_tb : std_logic_vector(1 downto 0);

signal a_valid_tb, a_ready_tb, d_valid_tb, d_ready_tb: std_logic := '0';
signal a_mask_tb: unsigned(3 downto 0) := (others => '0');
signal a_data_tb: std_logic_vector(31 downto 0) := (others => '0');
signal d_data_tb: std_logic_vector(31 downto 0);
signal clk_tb : std_logic := '0';
signal rst_tb : std_logic := '0';
signal a_address_tb : unsigned(31 downto 0) := (others => '0');
signal a_size_tb: unsigned(1 downto 0);
signal d_size_tb: std_logic_vector(1 downto 0);
signal a_code_tb: unsigned(2 downto 0) := (others => '0');
signal d_code_tb: std_logic_vector(2 downto 0);
signal a_param_tb: std_logic_vector(2 downto 0) := (others => '0');
signal d_param_tb: std_logic_vector(2 downto 0);
signal a_corrupt_tb: std_logic := '0';
signal d_corrupt_tb: std_logic;
signal d_denied_tb: std_logic;
constant clk_period : time := 10 ns;

begin
DUT: Slave_TLUH 
    generic map(
        Slave_ADDR => 1
    )
    port map(
    clk => clk_tb,
    rst => rst_tb,
    
    a_valid => a_valid_tb,
    a_ready => a_ready_tb,
    
    a_code => std_logic_vector(a_code_tb),
    d_code => d_code_tb,
    
    a_source => a_source_tb,
    d_source => d_source_tb,
    d_sink => d_sink_tb,
    
    a_param => a_param_tb,
    d_param => d_param_tb,
    
    a_address => std_logic_vector(a_address_tb),
    
    a_mask => std_logic_vector(a_mask_tb),
    
    a_data => a_data_tb,
    d_data => d_data_tb,
    
    a_corrupt => a_corrupt_tb,
    d_corrupt => d_corrupt_tb,
    d_denied => d_denied_tb,
    
    a_size => std_logic_vector(a_size_tb),
    d_size => d_size_tb,
    
    d_valid => d_valid_tb,
    d_ready => d_ready_tb);

clock: process
    begin
        wait for clk_period/2;
        clk_tb <= not clk_tb;
    end process clock;

rst_tb <= '0';

a_valido: process
    begin
        a_valid_tb <= '0';
        wait for 2*clk_period;
        a_valid_tb <= '1';
        wait for clk_period;
   end process a_valido;

d_ready_tb <= a_valid_tb;

a_code_tb <= to_unsigned(3, a_code_tb'length);

a_mask_tb <= "0001";

a_data_tb <= x"00000003";

a_address_tb(31 downto 6) <= "00000000000000000000000001"; -- CS
a_address_tb(5 downto 2) <= "0001"; -- Word Address
a_address_tb(1 downto 0) <= "11"; -- Byte Address
a_size_tb <= to_unsigned(2, a_size_tb'length);

a_param_tb <= "011";

a_corrupt_tb <= '0';

a_source_tb <= (others => '0');


end Behavioral;
