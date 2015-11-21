--------------------------------------------------------------------------------
--
-- Title       : cl_select_text.vhd
-- Design      : Example
-- Author      : Kapitanov
-- Company     : InSys
-- 
-- Version     : 1.0
--------------------------------------------------------------------------------
--
-- Description : Text selector
--
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity cl_select_text is
	port(
		x_char	:  in	std_logic_vector(6 downto 0);	--! X line: 0:79
		y_char	:  in	std_logic_vector(4 downto 0);	--! Y line: 0:29
		win		:  in	std_logic;						--! win value 					
		lose	:  in	std_logic;						--! lose value
		game	:  in	std_logic;						--! game value 
		cntgames:  in	std_logic;						--! games counter enable 	
		addr_rnd:  in 	std_logic_vector(4 downto 0);	--! address round 		
		ch_data	:  out	std_logic_vector(7 downto 0)	--! selected data
		);                                                  
end cl_select_text;

architecture cl_select_text of cl_select_text is

signal x_int	: integer range 0 to 79 :=0;
signal y_int	: integer range 0 to 29 :=0;
signal addr		: integer range 0 to 31 :=0;

begin

x_int <= to_integer(unsigned(x_char));
y_int <= to_integer(unsigned(y_char));	

addr <= to_integer(unsigned(addr_rnd)); 

process(y_int, x_int, addr, win, lose, game, cntgames) is
begin
	if y_int = 5 then
		case x_int is
			when 16 => ch_data <= x"54"; -- T
			when 17 => ch_data <= x"68"; -- h
			when 18 => ch_data <= x"65"; -- e
			when 19 => ch_data <= x"00"; -- 
			when 20 => ch_data <= x"4D"; -- M
			when 21 => ch_data <= x"69"; -- i
			when 22 => ch_data <= x"6E"; -- n
			when 23 => ch_data <= x"65"; -- e
			when 24 => ch_data <= x"73"; -- s
			when 25 => ch_data <= x"77"; -- w
			when 26 => ch_data <= x"65"; -- e
			when 27 => ch_data <= x"65"; -- e
			when 28 => ch_data <= x"70"; -- p
			when 29 => ch_data <= x"65"; -- e
			when 30 => ch_data <= x"72"; -- r
			when 31 => ch_data <= x"00"; --	  			
			when 32 => ch_data <= x"67"; -- g   			
			when 33 => ch_data <= x"61"; -- a   			
			when 34 => ch_data <= x"6D"; -- m   			
			when 35 => ch_data <= x"65"; -- e   			
			when 36 => ch_data <= x"00"; --    			
			when 37 => ch_data <= x"6F"; -- o   			
			when 38 => ch_data <= x"6E"; -- n   			
			when 39 => ch_data <= x"00"; --    			
			when 40 => ch_data <= x"46"; -- F   			
 			when 41 => ch_data <= x"50"; -- P    			
			when 42 => ch_data <= x"47"; -- G   
			when 43 => ch_data <= x"41"; -- A 
			when 44 => ch_data <= x"00"; -- 
			when 45 => ch_data <= x"58"; -- X
			when 46 => ch_data <= x"43"; -- C
			when 47 => ch_data <= x"33"; -- 3
			when 48 => ch_data <= x"35"; -- 5
			when 49 => ch_data <= x"30"; -- 0
			when 50 => ch_data <= x"30"; -- 0			
			when 51 => ch_data <= x"45"; -- E				
			when others => ch_data <= x"00";
		end case; 
	elsif y_int = 6 then
		case x_int is
			when 32 => ch_data <= x"62"; -- b
			when 33 => ch_data <= x"79"; -- y
			when 34 => ch_data <= x"00"; -- 
			when 35 => ch_data <= x"4B"; -- K
			when 36 => ch_data <= x"61"; -- a
			when 37 => ch_data <= x"70"; -- p
			when 38 => ch_data <= x"69"; -- i
			when 39 => ch_data <= x"74"; -- t
			when 40 => ch_data <= x"61"; -- a
			when 41 => ch_data <= x"6E"; -- n
			when 42 => ch_data <= x"6F"; -- o
			when 43 => ch_data <= x"76"; -- v
			when 44 => ch_data <= x"00"; -- 
			when 45 => ch_data <= x"41"; -- A
			when 46 => ch_data <= x"6C"; -- l
			when 47 => ch_data <= x"65"; --	e			
			when 48 => ch_data <= x"78"; -- x   			
			when 49 => ch_data <= x"61"; -- a   			
			when 50 => ch_data <= x"6E"; -- n   			
			when 51 => ch_data <= x"64"; -- d   			
			when 52 => ch_data <= x"65"; -- e 			
			when 53 => ch_data <= x"72"; -- r   			
			when 54 => ch_data <= x"00"; --    			
			when 55 => ch_data <= x"2A"; -- $  			
			when others => ch_data <= x"00";
		end case;			
	elsif y_int = 7 then
		case x_int is
			when 16 => ch_data <= x"52"; -- R
			when 17 => ch_data <= x"75"; -- u
			when 18 => ch_data <= x"6C"; -- l
			when 19 => ch_data <= x"65"; -- e
			when 20 => ch_data <= x"73"; -- s
			when 21 => ch_data <= x"3A"; -- : 
			when others => ch_data <= x"00";
		end case;		
	elsif y_int = 8 then
		case x_int is
			when 17 => ch_data <= x"3E"; -- >
			when 18 => ch_data <= x"00"; -- 
			when 19 => ch_data <= x"53"; -- S    
			when 20 => ch_data <= x"50"; -- P  
			when 21 => ch_data <= x"41"; -- A  
			when 22 => ch_data <= x"43"; -- C  
			when 23 => ch_data <= x"45"; -- E  
			when 24 => ch_data <= x"00"; --   
			when 25 => ch_data <= x"2D"; -- -   
			when 26 => ch_data <= x"00"; --   
			when 27 => ch_data <= x"73"; -- s  
			when 28 => ch_data <= x"74"; -- t  
			when 29 => ch_data <= x"61"; -- a  
			when 30 => ch_data <= x"72"; -- r  
			when 31 => ch_data <= x"74"; -- t 
			when 32 => ch_data <= x"00"; --    			
			when 33 => ch_data <= x"6e"; -- n  			
			when 34 => ch_data <= x"65"; -- e  			
			when 35 => ch_data <= x"77"; -- w   			
			when 36 => ch_data <= x"00"; --    			
			when 37 => ch_data <= x"67"; -- g  			
			when 38 => ch_data <= x"61"; -- a  			
			when 39 => ch_data <= x"6D"; -- m   			
			when 40 => ch_data <= x"65"; -- e  			
			when 41 => ch_data <= x"2C"; -- ,   			  			
			when others => ch_data <= x"00";
		end case;
	elsif y_int = 9 then
		case x_int is
			when 17 => ch_data <= x"3E"; -- >
			when 18 => ch_data <= x"00"; -- 
			when 19 => ch_data <= x"45"; -- E    
			when 20 => ch_data <= x"4E"; -- N  
			when 21 => ch_data <= x"54"; -- T  
			when 22 => ch_data <= x"45"; -- E  
			when 23 => ch_data <= x"52"; -- R  
			when 24 => ch_data <= x"00"; --   
			when 25 => ch_data <= x"2D"; -- -   
			when 26 => ch_data <= x"00"; --   
			when 27 => ch_data <= x"63"; -- c  
			when 28 => ch_data <= x"68"; -- h  
			when 29 => ch_data <= x"65"; -- e  
			when 30 => ch_data <= x"63"; -- c  
			when 31 => ch_data <= x"6B"; -- k 
			when 32 => ch_data <= x"00"; --    			
			when 33 => ch_data <= x"61"; -- a  			
			when 34 => ch_data <= x"00"; --   			
			when 35 => ch_data <= x"66"; -- f   			
			when 36 => ch_data <= x"69"; -- i  			
			when 37 => ch_data <= x"65"; -- e  			
			when 38 => ch_data <= x"6C"; -- l  			
			when 39 => ch_data <= x"64"; -- d   			 			
			when 40 => ch_data <= x"2C"; -- ,   			  			
			when others => ch_data <= x"00";
		end case;	
	elsif y_int = 10 then
		case x_int is
			when 17 => ch_data <= x"3E"; -- >
			when 18 => ch_data <= x"00"; -- 
			when 19 => ch_data <= x"27"; -- "    
			when 20 => ch_data <= x"57"; -- W  
			when 21 => ch_data <= x"53"; -- S  
			when 22 => ch_data <= x"41"; -- A  
			when 23 => ch_data <= x"44"; -- D  
			when 24 => ch_data <= x"27"; -- "  
--			when 25 => ch_data <= x"00"; --    
			when 25 => ch_data <= x"2D"; -- -  
			when 26 => ch_data <= x"00"; --    
			when 27 => ch_data <= x"6B"; -- k  
			when 28 => ch_data <= x"65"; -- e  
			when 29 => ch_data <= x"79"; -- y  
			when 30 => ch_data <= x"73"; -- s 
			when 31 => ch_data <= x"00"; --    			
			when 32 => ch_data <= x"66"; -- f  			
			when 33 => ch_data <= x"6F"; -- o  			
			when 34 => ch_data <= x"72"; -- r   			
			when 35 => ch_data <= x"00"; --    			
			when 36 => ch_data <= x"6D"; -- m  			
			when 37 => ch_data <= x"6F"; -- o  			
			when 38 => ch_data <= x"76"; -- v   			
			when 39 => ch_data <= x"69"; -- i  			
			when 40 => ch_data <= x"6E"; -- n   			
 			when 41 => ch_data <= x"67"; -- g  			
			when 42 => ch_data <= x"2C"; -- ,
			when others => ch_data <= x"00";
		end case;	
	elsif y_int = 11 then
		case x_int is
			when 17 => ch_data <= x"3E"; -- >
			when 18 => ch_data <= x"00"; -- 
			when 19 => ch_data <= x"45"; -- E    
			when 20 => ch_data <= x"53"; -- S  
			when 21 => ch_data <= x"43"; -- C  
			when 22 => ch_data <= x"00"; --   
			when 23 => ch_data <= x"2D"; -- -  
			when 24 => ch_data <= x"00"; --   
			when 25 => ch_data <= x"65"; -- e   
			when 26 => ch_data <= x"78"; -- x  
			when 27 => ch_data <= x"69"; -- i  
			when 28 => ch_data <= x"74"; -- t  			
			when 29 => ch_data <= x"2C"; -- .
			when others => ch_data <= x"00";
		end case;
	elsif y_int = 12 then
		case x_int is
			when 17 => ch_data <= x"3E"; -- >
			when 18 => ch_data <= x"00"; -- 
			when 19 => ch_data <= x"38"; -- 8    
			when 20 => ch_data <= x"00"; --   
			when 21 => ch_data <= x"6D"; -- m  
			when 22 => ch_data <= x"69"; -- i  
			when 23 => ch_data <= x"6E"; -- n  
			when 24 => ch_data <= x"65"; -- e  
			when 25 => ch_data <= x"73"; -- s   
			when 26 => ch_data <= x"00"; --   
			when 27 => ch_data <= x"6F"; -- o  
			when 28 => ch_data <= x"6E"; -- n	
			when 29 => ch_data <= x"6C"; -- l
			when 30 => ch_data <= x"79"; -- y
			when 31 => ch_data <= x"2E"; -- .
			when others => ch_data <= x"00";
		end case;				
	elsif y_int = 14 then
		case x_int is
			when 16 => ch_data <= x"47"; -- G
			when 17 => ch_data <= x"41"; -- A
			when 18 => ch_data <= x"4D"; -- M    
			when 19 => ch_data <= x"45"; -- E 
			when 20 => ch_data <= x"00"; --
			when 21 => 
				if cntgames = '1' then
					if (addr < 10) then
						ch_data <= x"30";
					elsif ((10 <= addr) and (addr < 20)) then
						ch_data <= x"31";
					elsif ((20 <= addr) and (addr < 30)) then
						ch_data <= x"32";				
					else
						ch_data <= x"33";
					end if;
				else 
					ch_data <= x"05";
				end if;
			when 22 => 
				if cntgames = '1' then
					if ((addr = 0) or (addr = 10) or (addr = 20) or (addr = 30)) then
						ch_data <= x"30";
					elsif ((addr = 1) or (addr = 11) or (addr = 21) or (addr = 31)) then
						ch_data <= x"31";
					elsif ((addr = 2) or (addr = 12) or (addr = 22)) then
						ch_data <= x"32";				
					elsif ((addr = 3) or (addr = 13) or (addr = 23)) then
						ch_data <= x"33";	
					elsif ((addr = 4) or (addr = 14) or (addr = 24)) then
						ch_data <= x"34";	
					elsif ((addr = 5) or (addr = 15) or (addr = 25)) then
						ch_data <= x"35";						
					elsif ((addr = 6) or (addr = 16) or (addr = 26)) then
						ch_data <= x"36";						
					elsif ((addr = 7) or (addr = 17) or (addr = 27)) then
						ch_data <= x"37";						
					elsif ((addr = 8) or (addr = 18) or (addr = 28)) then
						ch_data <= x"38";						
					elsif ((addr = 9) or (addr = 19) or (addr = 29)) then
						ch_data <= x"39";
					else
						null;
					end if;	
				else 
					ch_data <= x"05";
				end if;				
			when others => ch_data <= x"00";
		end case;		
	elsif y_int = 16 then
		if lose = '1' then
			case x_int is
				when 26 => ch_data <= x"0F"; --  :(
				when 27 => ch_data <= x"00"; -- 
				when 28 => ch_data <= x"47"; --  G   
				when 29 => ch_data <= x"41"; --  A
				when 30 => ch_data <= x"4D"; --  M
				when 31 => ch_data <= x"45"; --  E
				when 32 => ch_data <= x"00"; --   			
				when 33 => ch_data <= x"4F"; --  O			
				when 34 => ch_data <= x"56"; --  V			
				when 35 => ch_data <= x"45"; --  E
				when 36 => ch_data <= x"52"; --  R
				when 37 => ch_data <= x"00"; -- 
				when 38 => ch_data <= x"0F"; --  :(			
				when others => ch_data <= x"00";
			end case;
		elsif win = '1' then
			case x_int is
				when 26 => ch_data <= x"01"; --  :)
				when 27 => ch_data <= x"00"; -- 
				when 28 => ch_data <= x"59"; --  Y   
				when 29 => ch_data <= x"4F"; --  O
				when 30 => ch_data <= x"55"; --  U
				when 31 => ch_data <= x"00"; --  
				when 32 => ch_data <= x"57"; --  W 			
				when 33 => ch_data <= x"49"; --  I			
				when 34 => ch_data <= x"4E"; --  N			
				when 35 => ch_data <= x"21"; --  !
				when 36 => ch_data <= x"21"; --  !
				when 37 => ch_data <= x"00"; -- 
				when 38 => ch_data <= x"01"; --  :)			
				when others => ch_data <= x"00";
			end case;
		else
			ch_data <= x"00";
		end if;
	elsif y_int = 19 then
		if game = '1' then
			case x_int is
				when 26 => ch_data <= x"4E"; -- N
				when 27 => ch_data <= x"65"; -- e
				when 28 => ch_data <= x"77"; -- w  
				when 29 => ch_data <= x"00"; --  
				when 30 => ch_data <= x"67"; -- g 
				when 31 => ch_data <= x"61"; -- a  
				when 32 => ch_data <= x"6D"; -- m 			
				when 33 => ch_data <= x"65"; -- e 			
				when 34 => ch_data <= x"00"; -- 			
				when 35 => ch_data <= x"7b"; -- {
				when 36 => ch_data <= x"59"; -- Y
				when 37 => ch_data <= x"2F"; -- /
				when 38 => ch_data <= x"4e"; -- N
				when 39 => ch_data <= x"7d"; -- } 
				when 40 => ch_data <= x"3F"; -- ?		
				when others => ch_data <= x"00";
			end case;
		else
			ch_data <= x"00";
		end if;
	else 
		ch_data <= x"00";
	end if;
end process;
			
end cl_select_text;