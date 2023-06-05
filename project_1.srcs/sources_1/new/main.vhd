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
    d: out std_logic_vector(15 downto 0)) is
variable remh, reml, quoth, qoutl: std_logic_vector(7 downto 0);
begin
    div8("00000000" & a(15 downto 8), b, quoth, remh);
    div8(remh & a(7 downto 0), b, qoutl, reml);
    d(15 downto 8) := quoth;
    d(7 downto 0) := qoutl;
end procedure;

procedure comp1 (
    variable x: in std_logic;
    variable y: in std_logic;
    variable gin: in std_logic;
    variable lin: in std_logic;
    variable gout: out std_logic;
    variable lout: out std_logic;
    variable eout: out std_logic
) is

begin
    gout:= (x and not y) or (x and gin) or (not y and gin);
    eout:=(not x and not y and not gin and not lin)or(x and y and not gin and not lin);
    lout:=(not x and y) or (not x and lin) or (y and lin);

end procedure;

procedure comparer (
    variable a : in std_logic_vector;
    variable b : in std_logic_vector;
    variable gt : out std_logic;
    variable eq : out std_logic;
    variable lt : out std_logic
)is
    variable g,l,e: std_logic_vector(a'length downto 0);

begin
 if(True)then
    g(0):='0';
    l(0):='0';
    for i in 0 to a'length-1 loop
        comp1(a(i),b(i),g(i),l(i),g(i+1),l(i+1),e(i+1));
    end loop;
    eq:=e(a'length);
    gt:=g(a'length);
    lt:=l(a'length);
    else
    eq:='0';
    gt:='0';
    lt:='0';
    end if;
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
    
------------------Maquina de estadoos-----------------------
type ROM_MEMORY_array is array(0 to 80) of std_logic_vector(15 downto 0);
    constant Content: ROM_MEMORY_array:=(
           --programa 1
          0=> "1011000000010100", -- LOAD 13 in r1
          1=> "0000000000000000", -- send r1 to acc
          2=> "1011000000011011", -- LOAD X in r1
          3=> "1001000000000000", -- MULTI acc by X=r1 and store r1
          4=> "1011000100010101", -- LOAD 23 in r2
		  5=> "0000000100000000", -- send r2 to acc
		  6=> "1011000100011100", -- LOAD Y in r2
		  7=> "1001010100000000", --MULTI acc by Y=r2 and store r2
		  8=> "0000000100000000", --send r2 to acc
		  9=> "0111000000000000", --add acc by r1 and store r1	
		  10=>"1011000100010110", -- LOAD 4 in r2	 
		  
		  11=> "0000000100000000", -- send r2 to acc
		  12=> "1011000100011101", -- LOAD W in r2
		  13=> "1010010100000000", -- DIVIDE r2 from acc and store r2
		  14=> "0000000100000000", -- send r2 to acc
		  15=> "1000000000000000", -- substract r1 from acc and store r1
		  
		  16=> "1101000000000000", -- send r1 to display
		  17=> "1111000000000000", -- FIN DEL PROGRAMA
		  -- void
		  18=> "1111000000000000", -- LOAD Zero in r1
		  19=> "1111000000000000", -- send r1 to display
		  -- CONSTANTES
		  20 => "0000000000001101", -- 13
		  21 => "0000000000010111", -- 23
		  22 => "0000000000000100", -- 4 
		  23 => "0000000000000101", -- 5
		  24 => "0000000000011110", -- 30
		  25 => "0000000000000010", -- 2
		  26 => "0000000000000111", -- 7
		  -- VALUES x,y,w,z
		  27=> "0000000000000011",-- X = 3
		  28=> "0000000000000010", -- Y = 2
		  29=> "0000000000001111",  -- W = 15
		  30=> "0000000000001010", -- Z = 10
		  --Zero value
          31=> "0000000000000000", -- Zero
          
          --Programa 2
          32=> "0111111111111111", -- 0
          33=> "0000000000000001", -- Valor de 1
          
          34=> "1001000000000000", -- MULTI acc by X=r1 and store r1
          35=> "1011000100010111", -- LOAD 5 in r2
          36=> "0000000100000000", -- send r2 to acc
		  37=>"1001000000000000", -- MULTI acc by X=r1 and store r1
		  38=> "1011000100011011", -- LOAD X in r2
		  39=> "0000000100000000", -- send r2 to acc
		  40=> "1011000100011000", -- LOAD 30 in r2
		  41=> "1001010100000000", -- MULTI acc by X=r2 and store r2
		  42=> "0000000100000000", -- send r2 to acc	 
		  43=> "0111000000000000", -- add acc by r1 and store r1	
		  
		      
		  44=> "1011000100011001", -- LOAD 2 in r2
		  45=> "0000000100000000", -- send r2 to acc
		  46=> "1011000100011110", -- LOAD Z in r2
		  47=> "1010010100000000", -- DIVIDE r2 from acc and store r2
		  48=> "0000000100000000", -- send r2 to acc
		  49=> "1000000000000000", -- substract r1 from acc and store r1
		  
		  50=> "1101000000000000", -- send r1 to display
		  51=> "1111000000000000", -- FIN DEL PROGRAMA
		  --programa 4
		  52=> "1011000000011111", -- LOAD Zero in r1
		  
		  
		  
		  
		  --Programa 3
          
          55=> "1011000000011011", -- LOAD X in r1
          56=> "0000000000000000", -- send r1 to acc
          57=> "1001000000000000", -- MULTI acc by X=r1 and store r1
          58=> "1011000100011010", -- LOAD 7 in r2
          59=> "0000000100000000", -- send r2 to acc
		  60=>"1001000000000000", -- MULTI acc by X=r1 and store r1
		  
		  61=> "1011000100011110", -- LOAD Z in r2
		  62=> "0000000100000000", -- send r2 to acc

		  63=> "1011000100010111", -- LOAD 5 in r2
		  64=> "1001010100000000", -- MULTI acc by 5=r2 and store r2
		  65=> "0000000100000000", -- send r2 to acc	 
		  66=> "0111000000000000", --add acc by r1 and store r1
		  --67=> "0010000000000000",-- COMP2 r1 and store r1
		  67=> "1011000100010111", -- LOAD 5 in r2
		  68=> "0000000100000000", -- send r2 to acc
		  69=> "1011000100011101", -- LOAD W in r2
		  70=> "1010010100011001", -- DIVIDE r2 from acc and store r2
		  71=> "0000000100000000", -- send r2 to acc
		  72=> "0111000000000000", -- ADD r1 from acc and store r1
		  73=> "1011001000100000", -- LOAD DIRECCION MEMORIA 32 in r3

		  74=> "1101000000000000", -- send r1 to display
		  75=> "1011001100100001", -- LOAD DIRECCION MEMORIA 33 in r4
		  76=> "0000001100000000", -- send r4 to acc
		  77=> "1000101000000000", -- SUBTRACR R3 - acc and store in r3
		  
		  78=> "0011100001001010", -- BNZ regC
		  
		  79=> "1111000000000000", -- FIN DEL PROGRAMA
        OTHERS => "0000000000000000"
        );
type estados is (init, fetch, decode, load,load1,load2, operation,operation1,endprog,send,jmp,jalr,comp,bnc,bnz,bnv,move,bs,ret, bnz2);
signal actual, sig: estados;
--------------------Signals----------------------
signal sal: std_logic_vector(15 downto 0);
signal resaum: std_logic_vector(11 downto 0);
signal getsal :std_logic;
signal seld: std_logic_vector(1 downto 0);
signal initialice: std_logic_vector(7 downto 0);
signal rg1,rg2,rg3,rg4: std_logic_vector(15 downto 0);
signal pcsig: std_logic_vector(7 downto 0);
signal equal : std_logic;
begin

clko<=clk;



process (actual,clk, rst) is
variable pcvar,dato1,dato2: std_logic_vector(15 downto 0);
variable mdr: std_logic_vector(15 downto 0);

variable res: std_logic_vector(15 downto 0);
variable pcreg,ret_pc: std_logic_vector(7 downto 0);
variable mar: std_logic_vector(7 downto 0);
variable resaum: std_logic_vector(11 downto 0);
variable cir: std_logic_vector(7 downto 0);
variable acc,regA,regB,regC,regD,op1: std_logic_vector(15 downto 0);
variable nu1,nu2,nu3,nu4,eq,gt,lt: std_logic;
variable carry :  std_logic;
variable overflow: std_logic;
variable zero: std_logic;
variable Neg: std_logic;

begin
if rst='1' then
    actual <= init;
elsif rising_edge (clk) then
actual<=sig;
case actual is 
     --              INIT            --
	when init=>
	pcreg:=initialice;
    getsal<='0';
	sig<=fetch;
	--            FETCH            --
	when fetch=>
	mar:=pcreg;
	mdr:= Content(to_integer(unsigned(pcreg)));
	cir:= Content(to_integer(unsigned(pcreg)))(15 downto 8);
	alu("00000000"&pcreg,"0000000000000001","0111",pcvar,nu1,nu2,nu3,nu4); -- Aqui se suma el pcreg
	pcreg:=pcvar(7 downto 0);
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
    -- Nuevas Intrucciones --
    when "0001" =>
    sig<=jmp;
    when "0010" =>
    sig<=jalr;
    
    when "0011" =>
    sig<=bnz;
    
    when "0100" =>
    sig<=bs;
    when "0101" =>
    sig<=bnc;
    when "0110" =>
    sig<=bnv;
    --     FIN   --
    -- ADD
    when "0111" =>
    mar:=mdr(7 downto 0);
    sig<=operation;
    -- SUBTRACT
    when "1000" =>
    mar:=mdr(7 downto 0);
    sig<=operation;
    -- MULTI
    when "1001" =>
    mar:=mdr(7 downto 0);
    sig<=operation;
    -- LOAD
    when "1011" =>
    mar:=mdr(7 downto 0);
    sig<=load;
    -- DIVIDE
    when "1010" =>
    mar:=mdr(7 downto 0);
    sig<=operation;
    -- ret
    when "1100" =>
    mar:=mdr(7 downto 0);
    sig<=ret;
    -- SEND DISP
    when "1101" =>
    case cir(1 downto 0) is
        when "00"=>sal<=regA;
        when "01"=>sal<=regB;
        when "10"=>sal<=regC;
        when "11"=>sal<=regD;
        when others=>sal<=(others=>'0');
        end case;
    sig<=send;
    -- COMPARADOR
    when "1110"=>
    sig<=comp;
    --fin del programa
    when "1111" =>
    sig<=endprog;
    when others=>sig<=init;
    end case;
    
    --             EXECUTE            --
    
    --              load specific register            ---
    
    when load=>
        mdr:= Content(to_integer(unsigned(mar)));
        sig<=load1;
    when load1=>
        case cir(1 downto 0) is
        when "00"=>regA:=mdr;
        when "01"=>regB:=mdr;
        when "10"=>regC:=mdr;
        when "11"=>regD:=mdr;
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
        alu(op1,acc,cir(7 downto 4),res,carry,overflow,zero,Neg);
        mdr:=res;
        sig<=load1;


   --             saltos            --
  --          JUMP            --
    when jmp=>
        pcreg:=mdr(7 downto 0); 
        sig<=fetch;
    --          JALR           
    when jalr=>
         ret_pc:=pcreg;
         pcreg:=mdr(7 downto 0);
    sig<=fetch;
    when ret=>
        pcreg:= ret_pc;
        ret_pc:="00000000";
    --          BNZ      -- Compara registro especifico     
    
    when bnz=>
    dato1:= "0000000000000000";
    case cir(3 downto 2) is
        when "00"=>dato2:=regA;
        when "01"=>dato2:=regB;
        when "10"=>dato2:=regC;
        when "11"=>dato2:=regD;
        when others=>dato2:=regA;
    end case;
   
    comparer(dato1,dato2, gt,eq,lt);
    equal <= eq;
    sig<=bnz2;
    
    when bnz2 =>
    
    if(eq = '1') then 
        sig<=fetch;
    else
        pcreg:=mdr(7 downto 0); 
        sig<=fetch;
    end if;
    
    --          BS            -- Compara registro especifico
    when bs=>
    case cir(3 downto 2) is
        when "00"=>dato2:=regA;
        when "01"=>dato2:=regB;
        when "10"=>dato2:=regC;
        when "11"=>dato2:=regD;
        when others=>dato2:=regA;
    end case;
    if(dato2(15) = '1') then 
        pcreg:=mdr(7 downto 0); 
    end if;
    sig<=fetch;
     --          BNC            --  Compara la operacion de add anterior si hubo carry
    when bnc=>
    if(carry = '1') then 
        pcreg:=mdr(7 downto 0); 
        carry := '0';
    end if;
    sig<=fetch;
      --          BNV            -- Compara la operacion add anterior si hubo overflow
    when bnv=>
    if(overflow = '1') then 
        pcreg:=mdr(7 downto 0); 
        overflow := '0';
    end if;
    sig<=fetch;
    when comp=>
    case cir(1 downto 0) is
        when "00"=>dato1:=regA;
        when "01"=>dato1:=regB;
        when "10"=>dato1:=regC;
        when "11"=>dato1:=regD;
        when others=>sig<=init;
        end case;
    case cir(3 downto 2) is
        when "00"=>dato2:=regA;
        when "01"=>dato2:=regB;
        when "10"=>dato2:=regC;
        when "11"=>dato2:=regD;
        when others=>sig<=init;
        end case;
    comparer(dato1,dato2,gt,eq,lt);
    sig<=fetch;
    --              move            --
    when move=>
    sig<=fetch;
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
  rg1<=regA;  
  rg2<=regB;  
  rg3<=regC;  
  rg4<=regD;  
  pcsig<=pcreg;
  equal<=eq;
end if;

end process;





initialicepc: process (sel,clk) is begin
    if(clk'event and clk='1') then
    case sel is
        when "00"=>initialice<="00000000";
        when "01"=>initialice<="00100000";
        when "10"=>initialice<="00110110";
        when "11"=>initialice<="00110100";
        when others=>null;
        end case;
        
        seld<=sel;
        end if;
        
    end process;
    
    process (clk) is begin
    if(clk'event and clk='1') then 
    if(getsal='1') then
    resaum<=sal(11 downto 0);
    else
    resaum<=(others=>'0');
    end if;
    end if;
    end process;
    
    
    dispacccon: bintodisp port map(clk=>clk,rst=>'0',segment=>segment,display=>display,resaum=>resaum);
    end architecture;