--------------------------------------------------------------------------------
--
-- Title       : cl_text.vhd
-- Design      : Example
-- Author      : Kapitanov
-- Company     : InSys
-- 
-- Version     : 1.0
--------------------------------------------------------------------------------
--
-- Description : Game block for main text
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

use work.ctrl_types_pkg.array8x8;

entity cl_text is
	generic(
		constant yend		: std_logic_vector(4 downto 0);		    --! Y end area    
		constant ystart		: std_logic_vector(4 downto 0);		    --! Y start area  
																    	              
		constant xend		: std_logic_vector(6 downto 0);		    --! X end area    
		constant xstart		: std_logic_vector(6 downto 0)		    --! X start area  
	);															                     
	port(														                     
		-- system signals:										                     
		clk			:  in 	std_logic;							    --! clock         
		reset		:  in	std_logic;							    --! system reset  
		-- control signals:	  									                      
		addr_rnd	:  in 	std_logic_vector(4 downto 0);		    --! address round    
		display		:  in	std_logic;							    --! display enable                  
		cntgames	:  in	std_logic; 							    --! games counter enable
		win			:  in	std_logic; 							    --! win value  
		lose		:  in	std_logic; 							    --! lose value  
		game		:  in	std_logic; 							    --! game value                  
		flash		:  in	std_logic_vector(2 downto 0);		    --! RGB blinking      
		-- vga XoY:												          
		x_char		:  in	std_logic_vector(9 downto 0);			--! X line: 0:79  
		y_char		:  in	std_logic_vector(8 downto 0);			--! Y line: 0:29 
		-- out color scheme:
		rgb			:  out	std_logic_vector(2 downto 0)			--! RGB Colour
		);
end cl_text;

architecture cl_text of cl_text is

component ctrl_8x16_rom is
	port(
		clk		:	in std_logic;
		addr	:	in std_logic_vector(10 downto 0);
		data	:	out std_logic_vector(7 downto 0)
	);
end component;

component cl_select_text is
	port(
		x_char	:  in	std_logic_vector(6 downto 0); 
		y_char	:  in	std_logic_vector(4 downto 0); 		
		win		:  in	std_logic;
		lose	:  in	std_logic;
		game	:  in	std_logic;
		cntgames:  in	std_logic; 	
		addr_rnd:  in 	std_logic_vector(4 downto 0);			
		ch_data	:  out	std_logic_vector(7 downto 0)
		);
end component;

signal x_in				: std_logic_vector(6 downto 0);
signal y_in				: std_logic_vector(4 downto 0);

signal data				: std_logic;

signal x_rev			: std_logic_vector(2 downto 0);
signal x_del			: std_logic_vector(2 downto 0);

signal color			: std_logic_vector(2 downto 0):="111";

signal addr_rom			: std_logic_vector(10 downto 0);
signal data_rom 		: std_logic_vector(7 downto 0);

signal data_box			: std_logic_vector(7 downto 0);

begin 
 	
x_in <= x_char(9 downto 3);
y_in <= y_char(8 downto 4);	 
		
x_select_text: cl_select_text
	port map (
		x_char	=> x_in,
		y_char	=> y_in,
		win		=> win,
		lose	=> lose,
		game	=> game,
		cntgames=> cntgames,
		addr_rnd=> addr_rnd,
		ch_data	=> data_box
	);

addr_rom <= data_box(6 downto 0) & y_char(3 downto 0) when rising_edge(clk);

x_char_rom: ctrl_8x16_rom 
	port map (
		clk		=> clk,
		addr	=> addr_rom,
		data	=> data_rom
	);	

g_rev: for ii in 0 to 2 generate
begin
	x_rev(ii) <= not x_char(ii) when rising_edge(clk);
end generate;

x_del <= x_rev when rising_edge(clk);

color <= flash when (x_in > "0011001") and (y_in = "10000") else "100" when (y_in < "00111") else "010";

pr_sw_sel: process(clk, reset) is
begin
	if reset = '0' then
		data <= '0';
	elsif rising_edge(clk) then
		if display = '0' then
			data <= '0';
		else
			data <= data_rom(to_integer(unsigned(x_del)));
		end if;
	end if;
end process; 

g_rgb: for ii in 0 to 2 generate
begin
	rgb(ii) <= data and color(ii);
end generate;

end cl_text;