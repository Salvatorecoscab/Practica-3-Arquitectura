----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 31.05.2023 00:16:28
-- Design Name: 
-- Module Name: aluP - Behavioral
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

---Se añade un comentario de prueba
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity aluP is
  port(
    a: in std_logic_vector(15 downto 0);
    b: in std_logic_vector(15 downto 0);
    F: in std_logic_vector(3 downto 0);
    Sal: out std_logic_vector(15 downto 0);
    overflowF: out std_logic;
    ZeroF: out std_logic;
    NegF: out std_logic;
    carryF : out std_logic
  );
end aluP;

architecture Behavioral of aluP is
-----------------------------Funciones---------------------------
--AdderSubstractor
procedure add (a: in std_logic_vector;
               b: in std_logic_vector;
               ctr: in std_logic;
               Z: out std_logic_vector;
               overflow: out std_logic;
               carry: out std_logic)is
    variable sum: std_logic_vector(a'length downto 0);
    variable carryv,bs: std_logic;

begin
    sum := (others => '0');
    carryv := ctr;

    for i in 0 to a'length-1 loop
        bs:= ctr xor b(i);
        sum(i) := a(i) xor bs xor carryv;
        carryv := (a(i) and bs) or (a(i) and carryv) or (bs and carryv);
    end loop;
    Z:= sum(a'length-1 downto 0);
    carry:=carryv;
    overflow:= carryv xor sum(a'length-1);
    
end procedure add;
function addF (a: std_logic_vector; b: std_logic_vector;ctr: std_logic) return std_logic_vector is
    variable sum: std_logic_vector(a'length downto 0);
    variable carry,bs: std_logic;

begin
    sum := (others => '0');
    carry := ctr;

    for i in 0 to a'length-1 loop
        bs:= ctr xor b(i);
        sum(i) := a(i) xor bs xor carry;
        carry := (a(i) and bs) or (a(i) and carry) or (bs and carry);
    end loop;
    sum(a'length):=carry;
    return sum;
end function addF;
procedure multiply(
    a : in std_logic_vector; 
    b : in std_logic_vector;
    m : out std_logic_vector) is
    variable pv : std_logic_vector(a'length+b'length-1 downto 0);
    variable bp : std_logic_vector(a'length+b'length-1 downto 0);
    variable carry : std_logic;
    variable ov : std_logic;
begin
    pv := (others => '0');
    bp := "00000000"&b;
    for i in 0 to a'length-1 loop
        if a(i) = '1' then
            add(pv, bp, '0',pv,ov,carry);
        end if;
        bp := bp(a'length+b'length-2 downto 0) & '0';
    end loop;
    m := pv;
end procedure multiply;
procedure div5(
    numer: in std_logic_vector(9 downto 0);
    denom: in std_logic_vector(4 downto 0);
    quotient: out std_logic_vector(4 downto 0);
    remainder: out std_logic_vector(4 downto 0)
) is 
variable d,n1: std_logic_vector(5 downto 0);
variable n2: std_logic_vector(4 downto 0);
variable carry: std_logic;
variable overflow: std_logic;
begin
    d:='0'&denom;
    n2:=numer(4 downto 0);
    n1:='0'&numer(9 downto 5);
    for i in 0 to 4 loop
        n1:=n1(4 downto 0) & n2(4);
        n2:=n2(3 downto 0) & '0';
        if n1>=d then
            add(n1,d,'1',n1,carry, overflow);
            -- n1:=addF(n1,d,'1')(5 downto 0);
            n2(0):='1';
        end if;
    end loop;
    quotient:=n2;
    remainder:=n1(4 downto 0);
    end procedure; 
procedure div10(a: in std_logic_vector(9 downto 0);
                b: in std_logic_vector(4 downto 0);
                d: out std_logic_vector(9 downto 0)) is
variable remh,reml, quoth,qoutl: std_logic_vector(4 downto 0);
begin
    div5("00000"&a(9 downto 5),b,quoth,remh);
    div5(remh&a(4 downto 0),b,qoutl,reml);
    d(9 downto 5):=quoth;
    d(4 downto 0):=qoutl;
end procedure;

procedure div8(
    numer: in std_logic_vector(15 downto 0);
    denom: in std_logic_vector(7 downto 0);
    quotient: out std_logic_vector(7 downto 0);
    remainder: out std_logic_vector(7 downto 0)
) is 
variable d, n1: std_logic_vector(8 downto 0);
variable n2: std_logic_vector(7 downto 0);
variable carry: std_logic;
variable overflow: std_logic;
begin
    d := '0' & denom;
    n2 := numer(7 downto 0);
    n1 := '0' & numer(15 downto 8);
    
    for i in 0 to 7 loop
        n1 := n1(7 downto 0) & n2(7);
        n2 := n2(6 downto 0) & '0';
        
        if n1 >= d then
            add(n1, d, '1', n1, carry, overflow);
            n2(0) := '1';
        end if;
    end loop;
    
    quotient := n2;
    remainder := n1(7 downto 0);
end procedure;

procedure div16(
    a: in std_logic_vector(15 downto 0);
    b: in std_logic_vector(7 downto 0);
    d: out std_logic_vector(15 downto 0)
) is
variable remh, reml, quoth, qoutl: std_logic_vector(7 downto 0);
begin
    div8("00000000" & a(15 downto 8), b, quoth, remh);
    div8(remh & a(7 downto 0), b, qoutl, reml);
    d(15 downto 8) := quoth;
    d(7 downto 0) := qoutl;
end procedure;

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
    eq : out std_logic;
    gt : out std_logic;
    lt : out std_logic
)is
    variable g,l,e: std_logic_vector;

begin
    g(0):='0';
    l(0):='0';
    for i in 0 to a'length-1 loop
        comp1(a(i),b(i),g(i),l(i),g(i+1),l(i+1),e(i));
    end loop;
    eq:=e(a'length-1);
    gt:=g(a'length-1);
    lt:=l(a'length-1);
end procedure;



procedure alu ( a: in std_logic_vector(15 downto 0); 
                b: in std_logic_vector(15 downto 0); 
                F: in std_logic_vector(3 downto 0); 
                Z: out std_logic_vector(15 downto 0); 
                carry : out std_logic;
                overflow: out std_logic;
                Zero: out std_logic; 
                Neg: out std_logic) is
    variable zfv: std_logic;
    variable Zv: std_logic_vector(15 downto 0);
    begin
        carry:='0';
        overflow:='0';
        zfv:='0';
        case F is
            when "0001" => Zv := not a;
            when "0010" => add("0000000000000000",a,'1',Zv,overflow,carry);-- complemento a 2
            when "0011" => Zv := a and b;
            when "0100" => Zv := a or b;
            when "0101" => Zv := a(14 downto 0) & '0';
            when "0110" => Zv := a(a'length-1)&a(a'length-1 downto 1);
            when "0111" => add(a,b,'0',Zv,overflow,carry);--suma
            when "1000" => add(a,b,'1',Zv,overflow,carry);--resta
       
            when "1001" => multiply(a(7 downto 0), b(7 downto 0),Zv);--multiplicacion 8 bits
            when "1010" => 
            div16(a,b(7 downto 0),Zv); --division 16/8 bits
         
            when others => Zv := (others=>'0');
        end case;
        for i in 0 to 15 loop
            zfv:= zfv or Zv(i);
        end loop;
        Zero:= not zfv;
        Neg:= Zv(15);
        Z := Zv;
    end procedure alu;
    
begin
    process (a,b,F) is
    variable salida: std_logic_vector(15 downto 0);
    variable carry,overflow,Zero,Neg: std_logic;
    begin
    alu(a,b,F,salida,carry,overflow,Zero,Neg);
    sal <= salida;
    carryF <= carry;
    overflowF <= overflow;
    ZeroF <= Zero;
    NegF <= Neg;
    end process;
end Behavioral;

  