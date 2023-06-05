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





-----------------------------Funciones---------------------------
procedure regasig(signal rega: in std_logic_vector (9 downto 0);signal regb: out std_logic_vector (9 downto 0)) is
begin
regb<=rega;
end procedure;
function add (a: std_logic_vector; b: std_logic_vector;ctr: std_logic) return std_logic_vector is
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
end function add;

function multiply(a : std_logic_vector; b : std_logic_vector) return std_logic_vector is
    variable pv : std_logic_vector(9 downto 0);
    variable bp : std_logic_vector(9 downto 0);
begin
    pv := (others => '0');
    bp := "00000"&b;
    for i in 0 to 4 loop
        if a(i) = '1' then
            pv:= add(pv, bp, '0')(9 downto 0);
        end if;
        bp := bp(8 downto 0) & '0';
    end loop;
    
    return pv;
end function multiply;

function div5(numer: in std_logic_vector(9 downto 0);
                denom: in std_logic_vector(4 downto 0)) return std_logic_vector is
 
variable d, n1: std_logic_vector(5 downto 0);
variable n2: std_logic_vector(4 downto 0);

begin
    d:= '0'&denom;
    n2:=numer(4 downto 0);
    n1:='0'&numer(9 downto 5);
    for i in 0 to 4 loop
        n1:= n1(4 downto 0)&n2(4);
        n2:= n2(3 downto 0)&'0';
        if n1>= d then 
         n1:=add(n1,d,'1')(5 downto 0);
         n2(0):='1';
         end if;
    end loop;
    return n2;
end function; 

procedure alu ( a: in std_logic_vector(9 downto 0); b: in std_logic_vector(9 downto 0); F: in std_logic_vector(3 downto 0); Z: out std_logic_vector(9 downto 0)) is

    begin
        case F is
            when "0001" => Z := not a;
            when "0010" => Z := add("0000000000",a,'1')(9 downto 0);-- complemento a 2
            when "0011" => Z := a and b;
            when "0100" => Z := a or b;
            when "0101" => Z := a(8 downto 0) & '0';
            when "0110" => 
            if(a(9)='1') then 
            Z := '1'&a(9 downto 1);
            else
            Z := '0'&a(9 downto 1);
            end if;
            when "0111" => Z := '0'&add(a(7 downto 0),b(7 downto 0),'0');--suma
            when "1000" =>
             if(a>=b) then 
            Z := "00"&add(a(7 downto 0),b(7 downto 0),'1')(7 downto 0);--resta
            else
            Z := "11"&add(a(7 downto 0),b(7 downto 0),'1')(7 downto 0);--resta
            end if;
            
             
            when "1001" => Z := multiply(a(4 downto 0), b(4 downto 0));--multiplicacion 5 bits
            when "1010" => Z := "00000"&div5(a,b(4 downto 0)); --division 5 bits
         
            when others => Z := (others=>'0');
        end case;
    end procedure alu;
    
------------------Maquina de estadoos-----------------------
type ROM_MEMORY_array is array(0 to 60) of std_logic_vector(17 downto 0);
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
		  10=> "101100010000011101", -- LOAD W in r2
		  11=> "000000010000000000", -- send r2 to acc
		  12=> "100000000000000000", -- substract r1 from acc and store r1
		  13=> "101100010000010110", -- LOAD 4 in r2
		  14=> "000000010000000000", -- send r2 to acc
		  15=> "101000000000011001", -- DIVIDE r1 from acc and store r1
		  16=> "110100000000000000", -- send r1 to display
		  17=> "111100000000000000", -- FIN DEL PROGRAMA
		  -- PROGRAMA 4
		  18=> "000000000000000000", -- send r1 to acc
		  19=> "111100000000000000", -- FIN DEL PROGRAMA
		  -- CONSTANTES
		  20 => "000000000000001101", -- 13
		  21 => "000000000000010111", -- 23
		  22 => "000000000000000100", -- 4 
		  23 => "000000000000000101", -- 5
		  24 => "000000000000011110", -- 30
		  25 => "000000000000000010", -- 2
		  26 => "000000000000000111", -- 7
		  -- VALUES x,y,w,z
		  27=> "000000000000000001",-- X = 1
		  28=> "000000000000000010", -- Y = 2
		  29=> "000000000000000011",  -- W = 3 
		  30=> "000000000000000100", -- Z = 4 
		  --Zero value
          31=> "000000000000000000", -- send r1 to acc
          
          --Programa 2
          32=> "101100000000011011", -- LOAD X in r1
          33=> "100100000000000000", -- MULTI acc by X=r1 and store r1
          34=> "101100010000010101", -- LOAD 23 in r2
		  35=> "000000010000000000", -- send r2 to acc
		  36=> "101100010000011100", -- LOAD Y in r2
		  37=> "100101010000000000", --MULTI acc by Y=r2 and store r2
		  38=> "000000010000000000", --send r2 to acc
		  39=> "011100000000000000", --add acc by r1 and store r1		 
		  40=> "101100000000010100", -- LOAD 13 in r1
          41=> "000000000000000000", -- send r1 to acc
          42=> "101100000000011011", -- LOAD X in r1
          43=> "100100000000000000", -- MULTI acc by X=r1 and store r1
          44=> "101100010000010101", -- LOAD 23 in r2
		  45=> "000000010000000000", -- send r2 to acc
		  46=> "101100010000011100", -- LOAD Y in r2
		  47=> "100101010000000000", --MULTI acc by Y=r2 and store r2
		  48=> "000000010000000000", --send r2 to acc
		  49=> "011100000000000000", --add acc by r1 and store r1		 
		  
		  
		  
		  
		  

		  
        OTHERS => "000000000000000000"
        );
type estados is (init, fetch, decode, load,load1,load2, operation,operation1,endprog,send);
signal actual, sig: estados;
--------------------Signals----------------------
signal sal: std_logic_vector(9 downto 0);
signal resaum: std_logic_vector(11 downto 0);
signal getsal :std_logic;
signal counter: integer range 0 to 10000000:=0;

------------------Seï¿½ales de control------------------
---------------------------------------------
begin

clko<=clk;
-------------------Procesos Estados -------------------

--process_for_mealy: process(clk,rst) is
--begin 

--elsif(rising_edge(clk)) then
        --if(counter<10000000) then
        --counter<=counter+1;
        --else 
        
        --counter<=0;
        --clk<=not clk;
        --end if;

--end process;
--------------------Procesos de control----------------------
--resaum<="00"&pcreg;


process (actual, sel,sal,getsal,clk, rst) is
variable pcvar: std_logic_vector(9 downto 0);
variable mdr: std_logic_vector(17 downto 0);


variable res: std_logic_vector(9 downto 0);
variable pcreg: std_logic_vector(9 downto 0);
variable mar: std_logic_vector(7 downto 0);
variable resaum: std_logic_vector(11 downto 0);
variable cir: std_logic_vector(7 downto 0);
variable acc,regA,regB,regC,regD,op1: std_logic_vector(9 downto 0);
begin
if rst='1' then
    actual <= init;
elsif rising_edge (clk) then
actual<=sig;
case actual is 
    --fetch
	when init=>
	case sel is
    when "00"=>pcreg:="0000000000";
    when "01"=>pcreg:="0000000000";
    when "10"=>pcreg:="0000000000";
    when "11"=>pcreg:="0000010001";
    when others=>pcreg:="1111111111";
    end case;
    getsal<='0';
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
    when others=>sig<=endprog;
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
        when others=>sig<=endprog;
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
        when others=>sig<=endprog;
        end case;
        sig<=operation1;
    when operation1=>
        alu(op1,acc,cir(7 downto 4),res);
        mdr(9 downto 0):=res;
        sig<=load2;
    when send=>
    getsal<='1';
    sig<=fetch;
        
    when endprog=>
    
    sig<=endprog;         
	when others=>sig<=endprog; 	
end case;
end if;
end process;
process (getsal,sal) is begin
if (getsal='1')then 
    resaum<="00"&sal;
else
    resaum<=(others=>'1');
end if;
end process;
dispacccon: bintodisp port map(clk=>clk,rst=>rst,segment=>segment,display=>display,resaum=>resaum);
end architecture;