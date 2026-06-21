----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 11/18/2021 06:55:22 PM
-- Design Name: 
-- Module Name: testPatternGenerator - Behavioral
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

entity testPatternGenerator is
Port ( 
    clk : in std_logic;
    rstn : in std_logic;
    m_axis_tuser : out std_logic;
    m_axis_tlast : out std_logic;
    m_axis_tvalid : out std_logic;
    m_axis_tdata : out std_logic_vector(23 downto 0);
    m_axis_tready : in std_logic;
    i_colorDataA : in std_logic_vector(31 downto 0);
    i_colorDataB : in std_logic_vector(31 downto 0)
);
end testPatternGenerator;

architecture Behavioral of testPatternGenerator is

type state_videostr is (WAITING, STREAMING, EOL);
signal lineCpt : unsigned(10 downto 0) := (others => '0');
signal columnCpt : unsigned(11 downto 0) := (others => '0');
signal current_state : state_videostr := WAITING;
signal next_state : state_videostr := WAITING;

begin

process(clk)
begin
    if(rstn = '0') then
        current_state <= WAITING;
    elsif(rising_edge(clk)) then
        current_state <= next_state;
        if(m_axis_tready = '1') then
             if(columnCpt = "00011111111") then
                    columnCpt <= "000000000000";
                    if(lineCpt = "00011011111") then
                        lineCpt  <= "00000000000";
                    else
                        lineCpt <= lineCpt + "1";
                    end if;
             else
                    columnCpt <= columnCpt + "1";
             end if;
         end if;
    end if;
end process;

process(current_state, m_axis_tready,columnCpt,lineCpt)
begin
    case current_state is
    when WAITING =>
        if(m_axis_tready = '1') then
            next_state <= STREAMING;
        else
            next_state <= WAITING;
        end if;
    when STREAMING =>
        if(columnCpt = "00011111111") then
            next_state <= EOL;
        else
            next_state <= STREAMING;
        end if;
    when EOL =>
         if(lineCpt = "00011011111") then
            next_state <= WAITING;
         else
            next_state <= STREAMING;
         end if;
    end case;
end process;
  
process(current_state,lineCpt)
begin
    case current_state is
    when WAITING =>
        m_axis_tvalid <= '1';
        m_axis_tuser <= '1';
        m_axis_tlast <= '0';
    when STREAMING =>
        m_axis_tvalid <= '1';
        m_axis_tlast <= '0';
        m_axis_tuser <= '0';
    when EOL =>
        m_axis_tvalid <= '1';
        m_axis_tlast <= '1';
        m_axis_tuser <= '0';
    end case;
    
     if(lineCpt(3) = '1') then
        m_axis_tdata <= i_colorDataA(23 downto 0);
     else 
        m_axis_tdata <= i_colorDataB(23 downto 0);
     end if;         
end process;     

end Behavioral;
