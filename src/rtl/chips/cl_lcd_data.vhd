-------------------------------------------------------------------------------
--
-- Title       : cl_lcd_data
-- Author      : Alexander Kapitanov
-- Company     : Instrumental Systems
-- E-mail      : kapitanov@insys.ru
--
-- Version     : 1.0
--
-------------------------------------------------------------------------------
--
-- Description : Data for testing LCD Display LCD1602				
--
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all; 
use ieee.std_logic_unsigned.all;

entity cl_lcd_data is
	generic ( 
		TD				: in time								--! simulation time;
		);														    
	port(														    
		reset			: in  std_logic;						--! system reset
		clk				: in  std_logic;						--! clock 50 MHz
		
		test_mode		: in  std_logic;						--! select mode: test message or timer message
		
		load_ena		: in  std_logic;						--! load new data
		load_dat		: in  std_logic_vector(7 downto 0); 	--! new data;
		load_addr		: in  std_logic_vector(4 downto 0); 	--! new address;
																    
		disp_data		: out std_logic_vector(7 downto 0); 	--! data to display
		disp_ena		: out std_logic;						--! enable for data
		disp_init		: in  std_logic;						--! ready for data
		disp_rdyt		: in  std_logic							--! valid pulse for data		
		);                                                          
end cl_lcd_data;

architecture cl_lcd_data of cl_lcd_data is

signal cnt			: std_logic_vector(4 downto 0):="00000";
--signal data			: std_logic_vector(7 downto 0);

type ROM is array (integer range 0 to 31) of std_logic_vector(7 downto 0);

-- MEMORY for TIMER:
signal mem_test : ROM:=( x"21", x"21", x"A5", x"A5", x"A5", x"A5", x"A5", x"2F", x"A5", x"A5", x"2F", x"A5", x"A5", x"A5", x"A5", x"A5", 
					x"21", x"21", x"A5", x"A5", x"A5", x"A5", x"A5", x"2F", x"A5", x"A5", x"2F", x"A5", x"A5", x"A5", x"A5", x"A5");
-- HELLO HABR: www.habrahabr.ru 
signal mem_habr : ROM:=( x"2A", x"2A", x"A5", x"A5", x"48", x"65", x"6C", x"6C", x"6F", x"A0", x"48", x"41", x"42", x"52", x"A5", x"A5",   
						 x"2A", x"2A", x"46", x"72", x"6F", x"6D", x"A0", x"4B", x"61", x"70", x"69", x"74", x"61", x"6E", x"6F", x"76");
 			
attribute RAM_STYLE : string;
attribute RAM_STYLE of mem_test: signal is "DISTRIBUTED";  
attribute RAM_STYLE of mem_habr: signal is "DISTRIBUTED"; 

begin
	
pr_rom8x32: process(clk) is
begin
	if(rising_edge(clk)) then
		if (load_ena = '1') then
	    	mem_test(conv_integer(unsigned(load_addr))) <= load_dat after td;
		end if;
		--data <= mem_test(conv_integer(unsigned(load_addr)));
	end if; 
end process;

-- display 2x16 on LCD
pr_2to8: process(clk, reset) is
begin
	if (reset = '0') then
		disp_data 	<= x"00";
		disp_ena 	<= '0';
		cnt			<= "00000";
	elsif (rising_edge(clk)) then	
		if (disp_init = '1') then
			if (disp_rdyt = '1') then
				disp_ena  <= '1' after td;
				if (test_mode = '0') then
					disp_data <= mem_test(conv_integer(cnt)) after td;	
				else
					disp_data <= mem_habr(conv_integer(cnt)) after td;
				end if;
				if (cnt = "11111") then
					cnt <= "00000" after td;
				else
					 cnt <= cnt + 1 after td;
				end if;				
			end if;	
		else
			disp_data 	<= x"00" after td;
			disp_ena 	<= '0' after td;
		end if;
	end if;
end process;

end cl_lcd_data;