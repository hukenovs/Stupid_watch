--------------------------------------------------------------------------------
--
-- Title       : rtl_game_int.vhd
-- Design      : Example
-- Author      : Kapitanov
-- Company     : InSys
-- 
-- Version     : 1.0
--------------------------------------------------------------------------------
--
-- Description : Main block for VGA game
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all; 
use ieee.numeric_std.all; 

use work.ctrl_types_pkg.all;

entity rtl_game_int is
	port(
		-- system signals
		reset		:  in	std_logic;						--! system reset        
		clk			:  in   std_logic;	 					--! pixel CLK ~25 MHz;  
		-- ps/2 signals										                       
		ps2_clk		:  in	std_logic;						--! PS/2 CLOCK          
		ps2_data	:  in	std_logic;						--! PS/2 SERIAL DATA    
		-- vga output signals								                       
		h_vga		:  out	std_logic;						--! horizontal          
		v_vga		:  out	std_logic;						--! vertical	           
		rgb			:  out	std_logic_vector(2 downto 0); 	--! rBG Colour                 
		-- test leds signals								                       
		leds		:  out	std_logic_vector(8 downto 1)	--! 8 LEDs                
		);
end rtl_game_int;

architecture rtl_game_int of rtl_game_int is

signal data_keyboard	: key_data;
signal data_new			: std_logic;

signal disp				: std_logic;                	
signal h_sync			: std_logic;
signal v_sync			: std_logic;
signal dataX			: std_logic_vector(9 downto 0);
signal dataY			: std_logic_vector(8 downto 0);

signal led				: std_logic_vector(8 downto 1);

constant yend			: std_logic_vector(4 downto 0):="11000"; 	-- Y end area
constant ystart			: std_logic_vector(4 downto 0):="10000"; 	-- Y start area
															 		 
constant xend			: std_logic_vector(6 downto 0):="0011000"; 	-- X end area  
constant xstart			: std_logic_vector(6 downto 0):="0010000";  -- X start area

begin
	
leds(6 downto 1) <=	led(6 downto 1);
leds(7) <= ps2_data;
leds(8) <= data_new;
	
h_vga <= h_sync after 1 ns when rising_edge(clk);	
v_vga <= v_sync after 1 ns when rising_edge(clk);	
	
---------------- stage 0: KEYBOARD CTRL ----------------		
x_keyboard: ctrl_key_decoder
	port map(
		-- system signals:	
		clk			=> clk,	
		-- keyboard in: 
		ps2_clk		=> ps2_clk,
		ps2_data	=> ps2_data,	
		-- keyboard out: 
		keys_out	=> data_keyboard,
		new_key		=> data_new
	);
---------------- stage 1: VGA CTRL ----------------	
x_vga_ctrl640x480 : vga_ctrl640x480
	port map(
		-- system signals: 
		clk		=>	clk,
		reset	=>  reset,
		-- Horizontal and Vertical sync:
		h_sync	=>	h_sync,
		v_sync	=>	v_sync,
		-- Display
		disp	=>	disp,
		-- vga XoY coordinates:
		x_out	=>	dataX,
		y_out	=>	dataY
	);	
---------------- stage 2: MAIN BLOCK ----------------	
x_rtl_game_int : ctrl_game_block	
	generic map(
		yend		=>	yend,
		ystart		=>	ystart,
		xend		=>	xend,
		xstart		=>	xstart
	)
	port map(
		-- system signals:
		clk			=> clk,
		reset		=> reset,
		-- keyboard: 
		push_keys	=> data_keyboard,
		-- vga XoY coordinates:
		display		=> disp,
		x_char		=> dataX,
		y_char		=> dataY,
		-- output vga scheme:
		rgb			=> rgb,
		leds		=> led
	);

end rtl_game_int;