library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
entity main is 
port(
    clk : in std_logic;
    rst : in std_logic;
    segment : out  STD_LOGIC_VECTOR (6 downto 0);
    display : out  STD_LOGIC_VECTOR (3 downto 0);
    --leds : out  STD_LOGIC_VECTOR (9 downto 0);
    clko:out std_logic;
    sel : in std_logic_vector(1 downto 0)
);
end entity;
architecture Behavioral of main is
------------------- Componentes -------------------
component bintodisp is
Port ( clk : in  STD_LOGIC;
           rst : in  STD_LOGIC;
           segment : out  STD_LOGIC_VECTOR (6 downto 0);
           display : out  STD_LOGIC_VECTOR (3 downto 0);
           resaum: in  STD_LOGIC_VECTOR (11 downto 0)
           );
end component;


-- Comentario Nuevo 


-----------------------------Funciones---------------------------

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
procedure multiply(
    a : in std_logic_vector; 
    b : in std_logic_vector;
    m : out std_logic_vector) is
    variable pv : std_logic_vector(9 downto 0);
    variable bp : std_logic_vector(9 downto 0);
    variable carry : std_logic;
begin
    pv := (others => '0');
    bp := "00000"&b;
    for i in 0 to 4 loop
        if a(i) = '1' then
            add(pv, bp, '0',pv,z);
        end if;
        bp := bp(8 downto 0) & '0';
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
begin
    d:='0'&denom;
    n2:=numer(4 downto 0);
    n1:='0'&numer(9 downto 5);
    for i in 0 to 4 loop
        n1:=n1(4 downto 0) & n2(4);
        n2:=n2(3 downto 0) & '0';
        if n1>=d then
            add(n1,d,'1',n1, carry);
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



procedure alu ( a: in std_logic_vector(9 downto 0); b: in std_logic_vector(9 downto 0); F: in std_logic_vector(3 downto 0); Z: out std_logic_vector(9 downto 0); carry : out std_logic) is
    
    begin
        case F is
            when "0001" => Z := not a;
            when "0010" => add((others=>'0'),a,'1',Z,carry);-- complemento a 2
            when "0011" => Z := a and b;
            when "0100" => Z := a or b;
            when "0101" => Z := a(8 downto 0) & '0';
            when "0110" => Z := a(a'length-1)&a(a'length-2 downto 0);
            when "0111" => add(a(7 downto 0),b(7 downto 0),'0',Z,carry);--suma
            when "1000" => 
             if(a>=b) then 
            Z := "00"&add(a(7 downto 0),b(7 downto 0),'1')(7 downto 0);--resta
            else
            Z := "11"&add(a(7 downto 0),b(7 downto 0),'1')(7 downto 0);--resta
            end if;
            
             
            when "1001" => multiply(a(4 downto 0), b(4 downto 0),Z);--multiplicacion 5 bits
            when "1010" => div10(a,b(4 downto 0),Z); --division 5 bits
         
            when others => Z := (others=>'0');
        end case;
    end procedure alu;
    
------------------Maquina de estadoos-----------------------
type ROM_MEMORY_array is array(0 to 80) of std_logic_vector(17 downto 0);
    constant Content: ROM_MEMORY_array:=(
           --programa 1
          0=> "101100000000010100", -- LOAD 13 in r1
          1=> "000000000000000000", -- send r1 to acc
          2=> "101100000000011011", -- LOAD X in r1
          3=> "100100000000000000", -- MULTI acc by X=r1 and store r1
          4=> "101100010000010101", -- LOAD 23 in r2
		  5=> "000000010000000000", -- send r2 to acc
		  6=> "101100010000011100", -- LOAD Y in r2
		  7=> "100101010000000000", --MULTI acc by Y=r2 and store r2
		  8=> "000000010000000000", --send r2 to acc
		  9=> "011100000000000000", --add acc by r1 and store r1	
		  10=> "101100010000010110", -- LOAD 4 in r2	 
		  
		  11=> "000000010000000000", -- send r2 to acc
		  12=> "101100010000011101", -- LOAD W in r2
		  13=> "101001010000011001", -- DIVIDE r2 from acc and store r2
		  14=> "000000010000000000", -- send r2 to acc
		  15=> "100000000000000000", -- substract r1 from acc and store r1
		  
		  16=> "110100000000000000", -- send r1 to display
		  17=> "111100000000000000", -- FIN DEL PROGRAMA
		  -- void
		  18=> "111100000000000000", -- LOAD Zero in r1
		  19=> "111100000000000000", -- send r1 to display
		  -- CONSTANTES
		  20 => "000000000000001101", -- 13
		  21 => "000000000000010111", -- 23
		  22 => "000000000000000100", -- 4 
		  23 => "000000000000000101", -- 5
		  24 => "000000000000011110", -- 30
		  25 => "000000000000000010", -- 2
		  26 => "000000000000000111", -- 7
		  -- VALUES x,y,w,z
		  27=> "000000000000000011",-- X = 3
		  28=> "000000000000000010", -- Y = 2
		  29=> "000000000000001111",  -- W = 15
		  30=> "000000000000001010", -- Z = 10
		  --Zero value
          31=> "000000000000000000", -- Zero
          
          --Programa 2
          32=> "101100000000011011", -- LOAD X in r1
          33=> "000000000000000000", -- send r1 to acc
          34=> "100100000000000000", -- MULTI acc by X=r1 and store r1
          35=> "101100010000010111", -- LOAD 5 in r2
          36=> "000000010000000000", -- send r2 to acc
		  37=>"100100000000000000", -- MULTI acc by X=r1 and store r1
		  38=> "101100010000011011", -- LOAD X in r2
		  39=> "000000010000000000", -- send r2 to acc
		  40=> "101100010000011000", -- LOAD 30 in r2
		  41=> "100101010000000000", -- MULTI acc by X=r2 and store r2
		  42=> "000000010000000000", -- send r2 to acc	 
		  43=> "011100000000000000", -- add acc by r1 and store r1	
		  
		  
		  44=> "101100010000011001", -- LOAD 2 in r2
		  45=> "000000010000000000", -- send r2 to acc
		  46=> "101100010000011110", -- LOAD Z in r2
		  47=> "101001010000011001", -- DIVIDE r2 from acc and store r2
		  48=> "000000010000000000", -- send r2 to acc
		  49=> "100000000000000000", -- substract r1 from acc and store r1
		  
		  50=> "110100000000000000", -- send r1 to display
		  51=> "111100000000000000", -- FIN DEL PROGRAMA
		  --programa 4
		  52=> "101100000000011111", -- LOAD Zero in r1
		  53=> "110100000000000000", -- send r1 to display
		  54=> "111100000000000000", -- FIN DEL PROGRAMA
		  --Programa 3
          55=> "101100000000011011", -- LOAD X in r1
          56=> "000000000000000000", -- send r1 to acc
          57=> "100100000000000000", -- MULTI acc by X=r1 and store r1
          58=> "101100010000011010", -- LOAD 7 in r2
          59=> "000000010000000000", -- send r2 to acc
		  60=>"100100000000000000", -- MULTI acc by X=r1 and store r1
		  
		  61=> "101100010000011110", -- LOAD Z in r2
		  62=> "000000010000000000", -- send r2 to acc
		  63=> "101100010000010111", -- LOAD 5 in r2
		  64=> "100101010000000000", -- MULTI acc by 5=r2 and store r2
		  65=> "000000010000000000", -- send r2 to acc	 
		  66=> "011100000000000000", --add acc by r1 and store r1
		  67=> "001000000000000000",-- COMP2 r1 and store r1
		  
		  68=> "101100010000010111", -- LOAD 5 in r2
		  69=> "000000010000000000", -- send r2 to acc
		  70=> "101100010000011101", -- LOAD W in r2
		  71=> "101001010000011001", -- DIVIDE r2 from acc and store r2
		  72=> "000000010000000000", -- send r2 to acc
		  73=> "011100000000000000", -- ADD r1 from acc and store r1
		  74=> "110100000000000000", -- send r1 to display
		  75=> "111100000000000000", -- FIN DEL PROGRAMA
		 
		  
		  

		  
        OTHERS => "000000000000000000"
        );
type estados is (init, fetch, decode, load,load1,load2, operation,operation1,endprog,send);
signal actual, sig: estados;
--------------------Signals----------------------
signal sal,initialice: std_logic_vector(9 downto 0);
signal resaum: std_logic_vector(11 downto 0);
signal getsal,changed :std_logic;
signal seld: std_logic_vector(1 downto 0);

begin

clko<=clk;
process (actual ,clk, rst) is
variable pcvar: std_logic_vector(9 downto 0);
variable mdr: std_logic_vector(17 downto 0);


variable res: std_logic_vector(9 downto 0);
variable pcreg: std_logic_vector(9 downto 0);
variable mar: std_logic_vector(7 downto 0);
--variable resaum: std_logic_vector(11 downto 0);10
variable cir: std_logic_vector(7 downto 0);
variable acc,regA,regB,regC,regD,op1: std_logic_vector(9 downto 0);
begin
if rst='1' then
    actual <= init;
elsif  (clk'event and clk='1') then
actual<=sig;
case actual is 
    --              INIT            --
	when init=>
	pcreg:=initialice;
    getsal<='0';
    changed<='0';
	sig<=fetch;
	--            FETCH            --
	when fetch=>
	mar:=pcreg(7 downto 0);
	mdr:= Content(to_integer(unsigned(pcreg(7 downto 0))));
	cir:= Content(to_integer(unsigned(pcreg(7 downto 0))))(17 downto 10);
	alu(pcreg,"0000000001","0111",pcvar);
	pcreg:=pcvar;
	
	sig<=decode;
	
    --              DECODE          --
    when decode=>
    case cir(7 downto 4) is
    when "0000" =>
    case cir(1 downto 0) is
        when "00"=>acc:=regA;
        when "01"=>acc:=regB;
        when "10"=>acc:=regC;
        when "11"=>acc:=regD;
        when others=>acc:=(others=>'0');
        end case;
    sig<=fetch;
    when "1011" =>
    sig<=load;
    when "0010" =>
    mar:=mdr(7 downto 0);
    sig<=operation;
    when "0111" =>
    mar:=mdr(7 downto 0);
    sig<=operation;
    when "1000" =>
    mar:=mdr(7 downto 0);
    sig<=operation;
    when "1001" =>
    mar:=mdr(7 downto 0);
    sig<=operation;
    when "1010" =>
    mar:=mdr(7 downto 0);
    sig<=operation;
    when "1101" =>
    case cir(1 downto 0) is
        when "00"=>sal<=regA;
        when "01"=>sal<=regB;
        when "10"=>sal<=regC;
        when "11"=>sal<=regD;
        when others=>sal<=(others=>'0');
        end case;
    sig<=send;
    when "1111" =>
    sig<=endprog;
    when others=>sig<=init;
    end case;
   
    
    --              load            ---
    when load=>
        mar:=mdr(7 downto 0);
        sig<=load1;
    when load1=>
        mdr:= Content(to_integer(unsigned(mar)));
        sig<=load2;
    when load2=>
        case cir(1 downto 0) is
        when "00"=>regA:=mdr(9 downto 0);
        when "01"=>regB:=mdr(9 downto 0);
        when "10"=>regC:=mdr(9 downto 0);
        when "11"=>regD:=mdr(9 downto 0);
        when others=>sig<=init;
        end case;
    sig<=fetch;
    
  
    --                operation             --
    
    when operation=>
        mdr:= Content(to_integer(unsigned(mar)));
        case cir(3 downto 2) is
        when "00"=>op1:=regA;
        when "01"=>op1:=regB;
        when "10"=>op1:=regC;
        when "11"=>op1:=regD;
        when others=>sig<=init;
        end case;
        sig<=operation1;
    when operation1=>
        alu(op1,acc,cir(7 downto 4),res);
        mdr(9 downto 0):=res;
        sig<=load2;
    --               sendto disp           --
    when send=>
    getsal<='1';
    sig<=fetch;
        
    when endprog=>
    if(sel=seld) then
    sig<=endprog;
    else 
    sig<=init;
    end if;         
	when others=>sig<=init; 	
end case;
end if;

end process;


initialicepc: process (sel,clk) is begin
if(clk'event and clk='1') then
case sel is
    when "00"=>initialice<="0000000000";
    --change<='1';
    when "01"=>initialice<="0000100000";
    --change<='1';
    when "10"=>initialice<="0000110111";
    --change<='1';
    when "11"=>initialice<="0000110100";
    --change<='1';
    when others=>null;
    end case;
    
    seld<=sel;
    end if;
    
end process;
--changed <= '0' when seld = sel else '1';

process (clk) is begin
if(clk'event and clk='1') then 
if(getsal='1') then
resaum<="00"&sal;
else
resaum<=(others=>'0');
end if;
end if;
end process;


dispacccon: bintodisp port map(clk=>clk,rst=>'0',segment=>segment,display=>display,resaum=>resaum);
end architecture;
