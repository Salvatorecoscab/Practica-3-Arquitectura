----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 06/05/2023 04:24:09 PM
-- Design Name: 
-- Module Name: compn - Behavioral
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
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity compn is
Port ( 
    a : in std_logic_vector(7 downto 0);
    b : in std_logic_vector(7 downto 0);
    gtf : out std_logic;
    eqf : out std_logic;
    ltf : out std_logic
);
end compn;

architecture Behavioral of compn is
procedure comp1 (
    x: in std_logic;
    y: in std_logic;
    gin: in std_logic;
    lin: in std_logic;
    gout: out std_logic;
    lout: out std_logic;
    eout: out std_logic
) is

begin
    gout:= (x and not y) or (x and gin) or (not y and gin);
    eout:=(not x and not y and not gin and not lin)or(x and y and not gin and not lin);
    lout:=(not x and y) or (not x and lin) or (y and lin);

end procedure;

procedure comparer (
    a : in std_logic_vector;
    b : in std_logic_vector;
    gt : out std_logic;
    eq : out std_logic;
    lt : out std_logic
)is
    variable g,l,e: std_logic_vector(a'length downto 0);

begin
    g(0):='0';
    l(0):='0';
    for i in 0 to a'length-1 loop
        comp1(a(i),b(i),g(i),l(i),g(i+1),l(i+1),e(i+1));
    end loop;
    eq:=e(a'length);
    gt:=g(a'length);
    lt:=l(a'length);
end procedure;
begin

process (a,b) is
    variable gtv,eqv,ltv: std_logic;
begin
    comparer(a,b,gtv,eqv,ltv);
    gtf<=gtv;
    eqf<=eqv;
    ltf<=ltv;
end process;
end Behavioral;
