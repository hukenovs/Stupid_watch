--------------------------------------------------------------------------------
--
-- Title       : cl_square.vhd
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

use work.ctrl_types_pkg.array8x8;

entity cl_square is
	generic(
		constant yend		: std_logic_vector(4 downto 0);	  	--! Y end area    
		constant ystart		: std_logic_vector(4 downto 0);	  	--! Y start area  
															  		              
		constant xend		: std_logic_vector(6 downto 0);	  	--! X end area    
		constant xstart		: std_logic_vector(6 downto 0)	  	--! X start area  
	);	
	port(
		-- system signals:
		clk			:  in 	std_logic;						  	--! clock          
		reset		:  in	std_logic;						  	--! system reset   
		-- vga XoY coordinates:                                     
		show_disp	:  in	array8x8;							--! show square display		
		--data_hide	:  in	std_logic;                              
		display		:  in	std_logic;							--! display enable
		x_char		:  in	std_logic_vector(9 downto 0); 		--! X line: 0:79
		y_char		:  in	std_logic_vector(8 downto 0); 		--! Y line: 0:29
		-- out color scheme:
		rgb			:  out	std_logic_vector(2 downto 0)		--! RGB Colour		
	);
end cl_square;

architecture cl_square of cl_square is

signal data_rom 		: std_logic_vector(7 downto 0);

signal x_in				: std_logic_vector(6 downto 0);
signal y_in				: std_logic_vector(4 downto 0);

signal data				: std_logic;
signal dataxy			: std_logic;

signal x_rev			: std_logic_vector(2 downto 0);
signal x_del			: std_logic_vector(2 downto 0);
signal x_z				: std_logic_vector(2 downto 0);
signal y_charz			: std_logic_vector(3 downto 0);

constant color			: std_logic_vector(2 downto 0):="001";


begin 
  
y_charz <= y_char(3 downto 0) when rising_edge(clk);
	
x_in <= x_char(9 downto 3);
y_in <= y_char(8 downto 4);		

pr_select3: process(clk, reset) is
begin
	if reset = '0' then
		dataxy <= '0';
	elsif rising_edge(clk) then
		if display = '0' then
			dataxy <= '0';	
		else
			if ((xstart <= x_in) and (x_in < xend)) then
				if ((ystart <= y_in) and (y_in < yend)) then
					dataxy <= not show_disp(conv_integer(x_in(2 downto 0)))(conv_integer(y_in(2 downto 0)));
				else
					dataxy <= '0';
				end if;
			else
				dataxy <= '0';
			end if;
		end if;
	end if;
end process;

pr_new_box: process(clk, reset)
begin
	if reset = '0' then
		data_rom <= x"00";
	elsif rising_edge(clk) then
		if (dataxy = '1') then
			case y_charz(3 downto 0) is
				when x"0" => data_rom	<= x"FE";
				when x"1" => data_rom	<= x"FE";
				when x"2" => data_rom	<= x"FE";
				when x"3" => data_rom	<= x"FE";
				when x"4" => data_rom	<= x"FE";
				when x"5" => data_rom	<= x"FE";
				when x"6" => data_rom	<= x"FE";
				when x"7" => data_rom	<= x"FE";
				when x"8" => data_rom	<= x"FE";
				when x"9" => data_rom	<= x"FE";
				when x"A" => data_rom	<= x"FE";
				when x"B" => data_rom	<= x"FE";
				when x"C" => data_rom	<= x"FE";
				when x"D" => data_rom	<= x"FE";
				when x"E" => data_rom	<= x"FE";
				when others => data_rom <= x"00";			
			end case;
		else
			data_rom <= x"00";
		end if;
	end if;
end process;

g_rev: for ii in 0 to 2 generate
begin
	x_rev(ii) <= not x_char(ii) when rising_edge(clk);
end generate;

x_del <= x_rev when rising_edge(clk);
x_z <= x_del when rising_edge(clk);

pr_sw_sel: process(clk, reset) is
begin
	if reset = '0' then
		data <= '0';
	elsif rising_edge(clk) then
		data <= data_rom(to_integer(unsigned(x_z)));
	end if;
end process;

g_rgb: for ii in 0 to 2 generate
begin
	rgb(ii) <= data and color(ii);
end generate;

end cl_square;