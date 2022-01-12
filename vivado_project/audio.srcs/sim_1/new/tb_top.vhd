library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity tb_top is
--  Port ( );
end tb_top;

architecture Behavioral of tb_top is

component top is
  Port ( clk : in std_logic;
         reset : in std_logic);
        -- sw: in std_logic_vector(3 downto 0));
end component top;


signal clk,reset: std_logic;
--signal sw: std_logic_vector(3 downto 0) := "0110";

begin 
    
    uut: top port map (clk => clk, reset => reset);
    
    p_clk : process
    begin
        clk <='0'; wait for 5ns; clk <= '1'; wait for 5ns;
    end process;

    p_rst: process 
    begin  
    reset<='1'; wait for 15 ns; reset<='0'; wait for 15ns; 
    end process; 


end Behavioral;