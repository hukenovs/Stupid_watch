--------------------------------------------------------------------------------
--
-- Title       : cl_borders.vhd
-- Design      : Example
-- Author      : Kapitanov
-- Company     : InSys
-- 
-- Version     : 1.0
--------------------------------------------------------------------------------
--
-- Description : Game block for borders 8x8
--
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
 

entity cl_borders is
	generic(
		constant yend		: std_logic_vector(4 downto 0);		--! Y end area    
		constant ystart		: std_logic_vector(4 downto 0);		--! Y start area  
														   			              
		constant xend		: std_logic_vector(6 downto 0);		--! X end area    
		constant xstart		: std_logic_vector(6 downto 0) 		--! X start area  
	);
	port(
		-- system signals:
		clk			:  in 	std_logic;							--! clock         
		reset		:  in	std_logic;							--! system reset  
		-- vga XoY coordinates:                                     
		display		:  in	std_logic;							--! display enable
		x_char		:  in	std_logic_vector(9 downto 0); 		--! X line: 0:79
		y_char		:  in	std_logic_vector(8 downto 0); 		--! Y line: 0:29
		-- out color scheme:
		rgb			:  out	std_logic_vector(2 downto 0)		-- RGB Colour
		);
end cl_borders;

architecture cl_borders of cl_borders is

signal data_rom 		: std_logic_vector(7 downto 0);

signal x_in				: std_logic_vector(6 downto 0);
signal y_in				: std_logic_vector(4 downto 0);

signal data				: std_logic;
signal data_x1			: std_logic;
signal data_x2			: std_logic;
signal data_y1			: std_logic;
signal data_y2			: std_logic;
signal data_ul			: std_logic;
signal data_ur			: std_logic;
signal data_dl			: std_logic;
signal data_dr			: std_logic;

signal x_rev			: std_logic_vector(2 downto 0);
signal x_del			: std_logic_vector(2 downto 0);
--signal x_z				: std_logic_vector(2 downto 0);
signal y_charz			: std_logic_vector(3 downto 0);

constant color			: std_logic_vector(2 downto 0):="001";

begin 
  
y_charz <= y_char(3 downto 0) when rising_edge(clk);
	
	
g_rev: for ii in 0 to 2 generate
begin
	x_rev(ii) <= not x_char(ii) when rising_edge(clk);
end generate;

x_del <= x_rev when rising_edge(clk);
--x_z <= x_del when rising_edge(clk);

x_in <= x_char(9 downto 3);
y_in <= y_char(8 downto 4);		

pr_select3: process(clk, reset) is
begin
	if reset = '0' then
		data_x1 <= '0';
		data_x2 <= '0';
		data_y1 <= '0';
		data_y2 <= '0';		
		data_ul <= '0';
		data_ur <= '0';
		data_dl <= '0'; 
		data_dr <= '0'; 
	elsif rising_edge(clk) then
		if display = '0' then
			data_x1 <= '0';
			data_x2 <= '0';			
			data_y1 <= '0';
			data_y2 <= '0';
			data_ul <= '0';			
			data_ur <= '0';			
			data_dl <= '0';			
			data_dr <= '0';			
		else
			if (yend = y_in) then
				if (xstart-1 = x_in) then
					data_ul <= '1';
				else
					data_ul <= '0';
				end if;
			else
				data_ul <= '0';
			end if;
			if (yend = y_in) then
				if (xend = x_in) then
					data_ur <= '1';
				else
					data_ur <= '0';
				end if;
			else
				data_ur <= '0';
			end if;
			if (ystart-1 = y_in) then
				if (xstart-1 = x_in) then
					data_dl <= '1';
				else
					data_dl <= '0';
				end if;
			else
				data_dl <= '0';
			end if;
			if (ystart-1 = y_in) then
				if (xend = x_in) then
					data_dr <= '1';
				else
					data_dr <= '0';
				end if;
			else
				data_dr <= '0';
			end if;
			
			if (yend = y_in) then
				if (xstart <= x_in) and (x_in < xend) then
					data_x1 <= '1';
				else
					data_x1 <= '0';
				end if;
			else
				data_x1 <= '0';
			end if;
			
			if ((ystart-1) = y_in) then
				if (xstart <= x_in) and (x_in < xend) then
					data_x2 <= '1';
				else
					data_x2 <= '0';
				end if;
			else
				data_x2 <= '0';
			end if;		
			if (xstart-1 = x_in) then
				if (ystart <= y_in) and (y_in < yend) then
					data_y1 <= '1';
				else
					data_y1 <= '0';
				end if;
			else
				data_y1 <= '0';
			end if;
			if (xend = x_in) then
				if (ystart <= y_in) and (y_in < yend) then
					data_y2 <= '1';
				else
					data_y2 <= '0';
				end if;
			else
				data_y2 <= '0';
			end if;			
		end if;	
	end if;
end process;

pr_new_box: process(clk, reset)
begin
	if reset = '0' then
		data_rom <= x"00";
	elsif rising_edge(clk) then
		if data_x1 = '1' then
			case y_charz(3 downto 0) is
				when x"0" => data_rom	<= x"00";
				when x"1" => data_rom	<= x"00";
				when x"2" => data_rom	<= x"FF";
				when x"3" => data_rom	<= x"FF";
				when x"4" => data_rom	<= x"00";
				when x"5" => data_rom	<= x"00";
				when x"6" => data_rom	<= x"00";
				when x"7" => data_rom	<= x"00";
				when x"8" => data_rom	<= x"00";
				when x"9" => data_rom	<= x"00";
				when x"A" => data_rom	<= x"00";
				when x"B" => data_rom	<= x"00";
				when x"C" => data_rom	<= x"00";
				when x"D" => data_rom	<= x"00";
				when x"E" => data_rom	<= x"00";
				when others => data_rom <= x"00";			
			end case;
		elsif data_x2 = '1' then
			case y_charz(3 downto 0) is
				when x"0" => data_rom	<= x"00";
				when x"1" => data_rom	<= x"00";
				when x"2" => data_rom	<= x"00";
				when x"3" => data_rom	<= x"00";
				when x"4" => data_rom	<= x"00";
				when x"5" => data_rom	<= x"00";
				when x"6" => data_rom	<= x"00";
				when x"7" => data_rom	<= x"00";
				when x"8" => data_rom	<= x"00";
				when x"9" => data_rom	<= x"00";
				when x"A" => data_rom	<= x"00";
				when x"B" => data_rom	<= x"FF";
				when x"C" => data_rom	<= x"FF";
				when x"D" => data_rom	<= x"00";
				when x"E" => data_rom	<= x"00";
				when others => data_rom <= x"00";			
			end case;	
		elsif data_y1 = '1' then	
			case y_charz(3 downto 0) is
				when x"0" => data_rom	<= x"0C";
				when x"1" => data_rom	<= x"0C";
				when x"2" => data_rom	<= x"0C";
				when x"3" => data_rom	<= x"0C";
				when x"4" => data_rom	<= x"0C";
				when x"5" => data_rom	<= x"0C";
				when x"6" => data_rom	<= x"0C";
				when x"7" => data_rom	<= x"0C";
				when x"8" => data_rom	<= x"0C";
				when x"9" => data_rom	<= x"0C";
				when x"A" => data_rom	<= x"0C";
				when x"B" => data_rom	<= x"0C";
				when x"C" => data_rom	<= x"0C";
				when x"D" => data_rom	<= x"0C";
				when x"E" => data_rom	<= x"0C";
				when others => data_rom <= x"0C";			
			end case;
		elsif data_y2 = '1' then	
			case y_charz(3 downto 0) is
				when x"0" => data_rom	<= x"18";
				when x"1" => data_rom	<= x"18";
				when x"2" => data_rom	<= x"18";
				when x"3" => data_rom	<= x"18";
				when x"4" => data_rom	<= x"18";
				when x"5" => data_rom	<= x"18";
				when x"6" => data_rom	<= x"18";
				when x"7" => data_rom	<= x"18";
				when x"8" => data_rom	<= x"18";
				when x"9" => data_rom	<= x"18";
				when x"A" => data_rom	<= x"18";
				when x"B" => data_rom	<= x"18";
				when x"C" => data_rom	<= x"18";
				when x"D" => data_rom	<= x"18";
				when x"E" => data_rom	<= x"18";
				when others => data_rom <= x"18";			
			end case;			
		elsif data_ur = '1' then
			case y_charz(3 downto 0) is
				when x"0" => data_rom	<= x"18";
				when x"1" => data_rom	<= x"18";
				when x"2" => data_rom	<= x"F8";
				when x"3" => data_rom	<= x"F8";
				when x"4" => data_rom	<= x"00";
				when x"5" => data_rom	<= x"00";
				when x"6" => data_rom	<= x"00";
				when x"7" => data_rom	<= x"00";
				when x"8" => data_rom	<= x"00";
				when x"9" => data_rom	<= x"00";
				when x"A" => data_rom	<= x"00";
				when x"B" => data_rom	<= x"00";
				when x"C" => data_rom	<= x"00";
				when x"D" => data_rom	<= x"00";
				when x"E" => data_rom	<= x"00";
				when others => data_rom <= x"00";			
			end case;			 
		elsif data_ul = '1' then
			case y_charz(3 downto 0) is
				when x"0" => data_rom	<= x"0C";
				when x"1" => data_rom	<= x"0C";
				when x"2" => data_rom	<= x"0F";
				when x"3" => data_rom	<= x"0F";
				when x"4" => data_rom	<= x"00";
				when x"5" => data_rom	<= x"00";
				when x"6" => data_rom	<= x"00";
				when x"7" => data_rom	<= x"00";
				when x"8" => data_rom	<= x"00";
				when x"9" => data_rom	<= x"00";
				when x"A" => data_rom	<= x"00";
				when x"B" => data_rom	<= x"00";
				when x"C" => data_rom	<= x"00";
				when x"D" => data_rom	<= x"00";
				when x"E" => data_rom	<= x"00";
				when others => data_rom <= x"00";			
			end case;				
		elsif data_dr = '1' then
			case y_charz(3 downto 0) is
				when x"0" => data_rom	<= x"00";
				when x"1" => data_rom	<= x"00";
				when x"2" => data_rom	<= x"00";
				when x"3" => data_rom	<= x"00";
				when x"4" => data_rom	<= x"00";
				when x"5" => data_rom	<= x"00";
				when x"6" => data_rom	<= x"00";
				when x"7" => data_rom	<= x"00";
				when x"8" => data_rom	<= x"00";
				when x"9" => data_rom	<= x"00";
				when x"A" => data_rom	<= x"00";
				when x"B" => data_rom	<= x"F8";
				when x"C" => data_rom	<= x"F8";
				when x"D" => data_rom	<= x"18";
				when x"E" => data_rom	<= x"18";
				when others => data_rom <= x"18";			
			end case;				 
		elsif data_dl = '1' then
			case y_charz(3 downto 0) is
				when x"0" => data_rom	<= x"00";
				when x"1" => data_rom	<= x"00";
				when x"2" => data_rom	<= x"00";
				when x"3" => data_rom	<= x"00";
				when x"4" => data_rom	<= x"00";
				when x"5" => data_rom	<= x"00";
				when x"6" => data_rom	<= x"00";
				when x"7" => data_rom	<= x"00";
				when x"8" => data_rom	<= x"00";
				when x"9" => data_rom	<= x"00";
				when x"A" => data_rom	<= x"00";
				when x"B" => data_rom	<= x"0F";
				when x"C" => data_rom	<= x"0F";
				when x"D" => data_rom	<= x"0C";
				when x"E" => data_rom	<= x"0C";
				when others => data_rom <= x"0C";			
			end case;			
		else	
			data_rom <= x"00";
		end if;
	end if;
end process;

g_rgb: for ii in 0 to 2 generate
begin
	rgb(ii) <= data and color(ii);
end generate;

pr_sw_sel: process(clk, reset) is
begin
	if reset = '0' then
		data <= '0';
	elsif rising_edge(clk) then
		data <= data_rom(to_integer(unsigned(x_del)));
	end if;
end process;

end cl_borders;