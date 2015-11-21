--------------------------------------------------------------------------------
--
-- Title       : ctrl_comp_pkg.vhd
-- Design      : Example
-- Author      : Kapitanov
-- Company     : InSys
-- 
-- Version     : 1.0
--------------------------------------------------------------------------------
--
-- Description : Components for display
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

use work.ctrl_types_pkg.array8x8;

package ctrl_comp_pkg is
	
component cl_square is
	generic(
		constant yend		: std_logic_vector(4 downto 0);
		constant ystart		: std_logic_vector(4 downto 0);
														   
		constant xend		: std_logic_vector(6 downto 0);
		constant xstart		: std_logic_vector(6 downto 0) 
	);													   
	port(												   
		-- system signals:								   
		clk			:  in 	std_logic;					   
		reset		:  in	std_logic;					   
		-- vga XoY coordinates:
		show_disp	:  in	array8x8;							
		display		:  in	std_logic;						
		x_char		:  in	std_logic_vector(9 downto 0); 	
		y_char		:  in	std_logic_vector(8 downto 0); 	
		-- out color scheme:
		rgb			:  out	std_logic_vector(2 downto 0)	
	);
end component;	

component cl_borders is
	generic(
		constant yend		: std_logic_vector(4 downto 0);
		constant ystart		: std_logic_vector(4 downto 0);
		
		constant xend		: std_logic_vector(6 downto 0);
		constant xstart		: std_logic_vector(6 downto 0)
	);		
	port(
		-- system signals:
		clk			:  in 	std_logic;
		reset		:  in	std_logic;
		-- vga XoY coordinates:
		display		:  in	std_logic;
		x_char		:  in	std_logic_vector(9 downto 0); -- X line: 0:79
		y_char		:  in	std_logic_vector(8 downto 0); -- Y line: 0:29
		-- out color scheme:
		rgb			:  out	std_logic_vector(2 downto 0)
	);
end component;

component cl_mines is
	generic(
		constant yend		: std_logic_vector(4 downto 0);
		constant ystart		: std_logic_vector(4 downto 0);
		
		constant xend		: std_logic_vector(6 downto 0);
		constant xstart		: std_logic_vector(6 downto 0)
	);		
	port(
		-- system signals:
		clk			:  in 	std_logic;
		reset		:  in	std_logic;
		-- vga XoY coordinates:
		show_disp	:  in	array8x8;	
		-- vga XoY coordinates:
		addr_rnd	:  in 	std_logic_vector(4 downto 0);
		display		:  in	std_logic;
		x_char		:  in	std_logic_vector(9 downto 0); -- X line: 0:79
		y_char		:  in	std_logic_vector(8 downto 0); -- Y line: 0:29
		-- out color scheme:
		data_out	:  out	std_logic_vector(7 downto 0);
		rgb			:  out	std_logic_vector(2 downto 0)
	);
end component;

component cl_text is
	generic(
		constant yend		: std_logic_vector(4 downto 0);
		constant ystart		: std_logic_vector(4 downto 0);
		
		constant xend		: std_logic_vector(6 downto 0);
		constant xstart		: std_logic_vector(6 downto 0)
	);	
	port(
		-- system signals:
		clk			:  in 	std_logic;
		reset		:  in	std_logic;	
		-- control signals:
		addr_rnd	:  in 	std_logic_vector(4 downto 0);		
		display		:  in	std_logic; 
		cntgames	:  in	std_logic; 
		win			:  in	std_logic; 
		lose		:  in	std_logic; 
		game		:  in	std_logic; 
		flash		:  in	std_logic_vector(2 downto 0);
		-- vga XoY:
		x_char		:  in	std_logic_vector(9 downto 0);
		y_char		:  in	std_logic_vector(8 downto 0);
		-- out color scheme:
		rgb			:  out	std_logic_vector(2 downto 0)
	);
end component; 

component cl_check is
	generic(
		constant yend		: std_logic_vector(4 downto 0);
		constant ystart		: std_logic_vector(4 downto 0);
		
		constant xend		: std_logic_vector(6 downto 0);
		constant xstart		: std_logic_vector(6 downto 0)
	);	
	port(
		-- system signals:
		clk			:  in 	std_logic;
		reset		:  in	std_logic;
		-- vga XoY coordinates:
		cnt_yy		:  in	std_logic_vector(2 downto 0);
		cnt_xx		:  in	std_logic_vector(2 downto 0);		
		--data_hide	:  in	std_logic;
		display		:  in	std_logic;
		x_char		:  in	std_logic_vector(9 downto 0); -- X line: 0:79
		y_char		:  in	std_logic_vector(8 downto 0); -- Y line: 0:29
		-- out color scheme:
		rgb			:  out	std_logic_vector(2 downto 0)
		);
end component;

end ctrl_comp_pkg;