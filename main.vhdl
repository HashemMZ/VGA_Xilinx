library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

--  Uncomment the following lines to use the declarations that are
--  provided for instantiating Xilinx primitive components.
--library UNISIM;
--use UNISIM.VComponents.all;

entity main is
    Port ( resetn:in std_logic;	  -- Micro switch
           orient:in std_logic;	  -- DIP1
           clk:in std_logic; 
           Hsync:out std_logic;
           Vsync:out std_logic;
		     red:out std_logic_vector(1 downto 0);
		     green:out std_logic_vector(1 downto 0);
		     blue:out std_logic_vector(1 downto 0));
end main;

architecture Behavioral of main is

--//----------- Begin Cut here for INSTANTIATION Template ---// INST_TAG

component  clockGen 
port
   (-- Clock in ports
    CLK_IN1:      in std_logic;--// IN
    --// Clock out ports
    CLK_OUT1:     out std_logic;
    --// Status and control signals
    LOCKED : out std_logic
	 );
end component;
--// INST_TAG_END ------ End INSTANTIATION Template ---------

--Horizontal timing constants

--constant H_PIXELS:integer:=410; 	--number of pixels per line
--constant H_FRONTPORCH:integer:=10;	--gap before sync pulse
--constant H_SYNCTIME:integer:=61;	--width of sync pulse
--constant H_BACKPORCH:integer:=31;	--gap after sync pulse




constant H_PIXELS:integer:=189; 	--number of pixels per line
constant H_FRONTPORCH:integer:=5;	--gap before sync pulse
constant H_SYNCTIME:integer:=28;	--width of sync pulse
constant H_BACKPORCH:integer:=14;	--gap after sync pulse

constant H_SYNCSTART:integer:=H_PIXELS+H_FRONTPORCH;
constant H_SYNCEND:integer:=H_SYNCSTART+H_SYNCTIME;
constant H_PERIOD:integer:=H_SYNCEND+H_BACKPORCH;

--Vertical timing constants
constant V_LINES:integer:=480;	    --number of lines per frame
constant V_FRONTPORCH:integer:=10;  --gap before sync pulse
constant V_SYNCTIME:integer:=2;	    --width of sync pulse
constant V_BACKPORCH:integer:=33;   --gap after sync pulse
constant V_SYNCSTART:integer:=V_LINES + V_FRONTPORCH;
constant V_SYNCEND:integer:=V_SYNCSTART + V_SYNCTIME;
constant V_PERIOD:integer:=V_SYNCEND + V_BACKPORCH;
signal hcnt:std_logic_vector (9 downto 0); 	 --horizontal counter of pixels
signal vcnt:std_logic_vector (9 downto 0);	 --vertical counter of lines
signal hsyncint: std_logic ;			  	 --internal horizontal sync
signal enable:std_logic;					 --output enable for pixel data

signal clock,locked:std_logic;
begin

sysclk : clockGen
port map
(
CLK_IN1 => clk,

CLK_OUT1 => clock,
LOCKED => locked
);

-- Horizontal counter of pixels
HORIZONTAL_COUNTER: process(clock, resetn)
 begin
   if (resetn='0') then
	 hcnt <= (others =>'0');
 	 elsif (clock'event and clock ='1') then
	   if hcnt < H_PERIOD then
		  hcnt <= hcnt + '1';
	   else
		hcnt <= (others =>'0');
   	   end if ;
  end if ;
end process;

--Internal horizontal synchronization pulse generation ( negative polarity)
HORIZONTAL_SYNC: process(clock, resetn)
   begin
     if ( resetn ='0') then
	  hsyncint <= '1';
     elsif ( clock'event and clock = '1') then
         if (hcnt >= H_SYNCSTART and hcnt < H_SYNCEND) then
            hsyncint <= '0';
         else
            hsyncint <= '1';
	    end if ;
      end if ;
end process;

 --Horizontal synchronization output
hsync <= hsyncint;

 --Vertical counter of lines
VERTICAL_COUNTER: process(hsyncint, resetn)
   begin
    if ( resetn = '0') then
	 vcnt <= (others => '0');
	  elsif (hsyncint'event and hsyncint = '1') then
		if vcnt < V_PERIOD then
		    vcnt <= vcnt + 1;
		else
		   vcnt <= (others => '0');
		end if ;
     end if ;
end process;

--Vertical synchronization pulse generation ( negative polarity)
VERTICAL_SYNC: process(hsyncint, resetn)
begin
  if ( resetn = '0') then
	   vsync <= '1';
  elsif (hsyncint'event and hsyncint = '1') then
	 if (vcnt >= V_SYNCSTART and vcnt < V_SYNCEND) then
	    vsync <= '0';
	  else
	     vsync <= '1';
    	  end if ;
  end if ;
end process;

--Enabling of color outputs
OUTPUT_ENABLE: process(clock)
   begin
    if ( clock'event and clock = '1') then
	  if (hcnt >= H_PIXELS or vcnt >= V_LINES) then
	    enable <= '0';
  	   else
	     enable <= '1';
        end if ;
      end if ;
end process;
--Output image generation ( horizontal or vertical color stripes)
IMAGE: process(enable, orient, hcnt, vcnt)
    begin
	 if (enable = '0') then
		  blue(0) <= '0'; 
		  blue(1)	<= '0';
		  green(0)<= '0';
		  green(1)<= '0'; 
		  red(0)  <= '0';
		  red(1)  <= '0';
	elsif ( orient = '1') then
	       blue(0) <= hcnt(2); 
		  blue(1)	<= hcnt(3);
		  green(0)<= hcnt(4);
		  green(1)<= hcnt(5); 
		  red(0)  <= hcnt(6);
		  red(1)  <= hcnt(7);

	else
	   	  blue(0) <= vcnt(2); 
		  blue(1)	<= vcnt(3);
		  green(0)<= vcnt(4);
		  green(1)<= vcnt(5); 
		  red(0)  <= vcnt(6);
		  red(1)  <= vcnt(7);
	end if ;
end process;

end Behavioral;
