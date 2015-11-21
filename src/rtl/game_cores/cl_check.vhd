--------------------------------------------------------------------------------
--
-- Title       : cl_check.vhd
-- Design      : Example
-- Author      : Kapitanov
-- Company     : InSys
-- 
-- Version     : 1.0
--------------------------------------------------------------------------------
--
-- Description : Game block for square 8x8
--
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all; 							 	       
use ieee.numeric_std.all;									 	       
															 	       
entity cl_check is											 	       
	generic(												 	       
		constant yend		: std_logic_vector(4 downto 0);	--! Y end area    	       
		constant ystart		: std_logic_vector(4 downto 0);	--! Y start area  	       
														  		              	       
		constant xend		: std_logic_vector(6 downto 0);	--! X end area    	       
		constant xstart		: std_logic_vector(6 downto 0)	--! X start area  	       
	);														                                           
	port(													                 
		-- system signals:									                 
		clk			:  in 	std_logic;						--! clock        
		reset		:  in	std_logic;						--! system reset 
		-- vga XoY coordinates:								    
		cnt_yy		:  in	std_logic_vector(2 downto 0);	--! counter for Y data	
		cnt_xx		:  in	std_logic_vector(2 downto 0);	--! counter for X data		
		--data_hide	:  in	std_logic;                          
		display		:  in	std_logic;						--! display enable
		x_char		:  in	std_logic_vector(9 downto 0);	--! X line: 0:79
		y_char		:  in	std_logic_vector(8 downto 0);	--! Y line: 0:29
		-- out color scheme:
		rgb			:  out	std_logic_vector(2 downto 0)	--! RGB Colour	
		);
end cl_check;

architecture cl_check of cl_check is

signal data_rom 		: std_logic_vector(7 downto 0);

signal x_in				: std_logic_vector(6 downto 0);
signal y_in				: std_logic_vector(4 downto 0);

signal data				: std_logic;

signal x_rev			: std_logic_vector(2 downto 0);
signal x_del			: std_logic_vector(2 downto 0);

signal y_charz			: std_logic_vector(3 downto 0);
constant color			: std_logic_vector(2 downto 0):="111";

signal comp_yy			: std_logic_vector(3 downto 0);
signal comp_xx			: std_logic_vector(3 downto 0);

signal data_x, data_y	: std_logic;

begin 
---------------- stage 1: Get XoY ----------------	  
y_charz <= y_char(3 downto 0) when rising_edge(clk);
	
g_rev: for ii in 0 to 2 generate
begin
	x_rev(ii) <= not x_char(ii) when rising_edge(clk);
end generate;

x_del <= x_rev when rising_edge(clk);
		
comp_yy <= '0' & cnt_yy;	
comp_xx <= '0' & cnt_xx;	
	
x_in <= x_char(9 downto 3);
y_in <= y_char(8 downto 4);		
---------------- stage 2: Convert XY ----------------	
pr_select: process(clk, reset) is
begin
	if reset = '0' then
		data_x <= '0';
		data_y <= '0';
	elsif rising_edge(clk) then
		if display = '1' then
			if (x_in = (xstart + comp_xx)) then
				data_x <= '1';
			else
				data_x <= '0';
			end if;
			if (y_in = (ystart + comp_yy)) then
				data_y <= '1';
			else						 
				data_y <= '0';
			end if;	 
		else
			data_x <= '0';
			data_y <= '0';
		end if;
	end if;
end process;
---------------- stage 3: Data ROM ----------------	
pr_new_box: process(clk, reset)
begin
	if reset = '0' then
		data_rom <= x"00";
	elsif rising_edge(clk) then
		if (data_x = '1' and data_y = '1') then
			case y_charz(3 downto 0) is
				when x"0" => data_rom	<= x"FF";
				when x"1" => data_rom	<= x"81";
				when x"2" => data_rom	<= x"81";
				when x"3" => data_rom	<= x"81";
				when x"4" => data_rom	<= x"81";
				when x"5" => data_rom	<= x"81";
				when x"6" => data_rom	<= x"81";
				when x"7" => data_rom	<= x"81";
				when x"8" => data_rom	<= x"81";
				when x"9" => data_rom	<= x"81";
				when x"A" => data_rom	<= x"81";
				when x"B" => data_rom	<= x"81";
				when x"C" => data_rom	<= x"81";
				when x"D" => data_rom	<= x"83";
				when x"E" => data_rom	<= x"87";
				when others => data_rom	<= x"FF";			
			end case;
		else
			data_rom <= x"00";
		end if;
	end if;
end process;
	
---------------- stage 4: RGB DATA ----------------	
pr_sw_sel: process(clk, reset) is
begin
	if reset = '0' then
		data <= '0';
	elsif rising_edge(clk) then
		data <= data_rom(to_integer(unsigned(x_del)));
	end if;
end process;

g_rgb: for ii in 0 to 2 generate
begin
	rgb(ii) <= data and color(ii);
end generate;	
	
end cl_check;	 

