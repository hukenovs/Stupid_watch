--------------------------------------------------------------------------------
--
-- Title       : cl_mines.vhd
-- Design      : Example
-- Author      : Kapitanov
-- Company     : InSys
-- 
-- Version     : 1.0
--------------------------------------------------------------------------------
--
-- Description : Game block for mines
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

use work.ctrl_types_pkg.array8x8;						
use work.ctrl_types_pkg.data3x8;
use work.ctrl_types_pkg.data8x8;

entity cl_mines is
	generic(
		constant yend		: std_logic_vector(4 downto 0);	--! Y end area    
		constant ystart		: std_logic_vector(4 downto 0);	--! Y start area  
														  			              
		constant xend		: std_logic_vector(6 downto 0);	--! X end area    
		constant xstart		: std_logic_vector(6 downto 0)	--! X start area  
	);		
	port(
		-- system signals:
		clk			:  in 	std_logic;					  	--! clock                
		reset		:  in	std_logic;					  	--! system reset         
		-- vga XoY coordinates:							  	                         
		show_disp	:  in	array8x8;					  	--! show square display        
		-- vga XoY coordinates:							  	      
		addr_rnd	:  in 	std_logic_vector(4 downto 0); 	--! address round 
		display		:  in	std_logic;						--! games counter enable 
		x_char		:  in	std_logic_vector(9 downto 0); 	--! X line: 0:79
		y_char		:  in	std_logic_vector(8 downto 0); 	--! Y line: 0:29
		-- out color scheme:
		data_out	:  out	std_logic_vector(7 downto 0);	--! send data
		rgb			:  out	std_logic_vector(2 downto 0)	--! RGB Colour	
		);
end cl_mines;

architecture cl_mines of cl_mines is

component ctrl_rounds_rom is
	port(
		clk		:	in std_logic;
		addr	:	in std_logic_vector(7 downto 0);
		data	:	out std_logic_vector(23 downto 0)
	);
end component;

component ctrl_8x16_rom is
	port(
		clk		:	in std_logic;
		addr	:	in std_logic_vector(10 downto 0);
		data	:	out std_logic_vector(7 downto 0)
	);
end component;

signal x_in				: std_logic_vector(6 downto 0);
signal y_in				: std_logic_vector(4 downto 0);

signal x_rev			: std_logic_vector(2 downto 0);
signal x_del			: std_logic_vector(2 downto 0);
signal x_z				: std_logic_vector(2 downto 0);

signal y_charzz			: std_logic_vector(3 downto 0);
signal y_charz			: std_logic_vector(3 downto 0);

constant color2			: std_logic_vector(2 downto 0):="010";

signal addr_round		: std_logic_vector(7 downto 0);
signal data_round		: std_logic_vector(23 downto 0);

signal addr_rom2		: std_logic_vector(10 downto 0);
signal data_rom2 		: std_logic_vector(7 downto 0);

signal data_box			: std_logic_vector(7 downto 0);

signal data_disp		: data8x8;

signal data2			: std_logic;

signal x_inz			: std_logic_vector(6 downto 0);
signal y_inz			: std_logic_vector(4 downto 0);

signal dataxy			: std_logic;

begin 
	
y_charz <= y_char(3 downto 0) when rising_edge(clk);
y_charzz <= y_charz when rising_edge(clk);
		
x_in <= x_char(9 downto 3);
y_in <= y_char(8 downto 4);		

x_inz <= x_in after 1 ns when rising_edge(clk);
y_inz <= y_in after 1 ns when rising_edge(clk);

addr_round <= ((not addr_rnd) & (not y_in(2 downto 0))) when (y_in(4 downto 3) = "10");

x_rounds: ctrl_rounds_rom
	port map(
		clk		=> clk,
		addr	=> addr_round,
		data	=> data_round
	);

x_char_rom2: ctrl_8x16_rom 
	port map(
		clk		=> clk,
		addr	=> addr_rom2,
		data	=> data_rom2
	);									 
 
x_gen_round: for ii in 0 to 7 generate	
	signal conv_3x8	: data3x8;	
begin
	conv_3x8(ii) <= data_round(23-3*ii downto 21-3*ii);
	pr_round_box2: process(clk, reset) is
	begin
		if reset = '0' then
			data_disp(ii) <= x"00";
		elsif rising_edge(clk) then
			case conv_3x8(ii) is
				when "000" => data_disp(ii) <= x"30";
				when "001" => data_disp(ii) <= x"31";
				when "010" => data_disp(ii) <= x"32";
				when "011" => data_disp(ii) <= x"33";
				when "100" => data_disp(ii) <= x"34";
				when "101" => data_disp(ii) <= x"35";			
				when "110" => data_disp(ii) <= x"36";			
				when others => data_disp(ii) <= x"0F";
			end case;	
		end if;
	end process;	
end generate;  

pr_select2: process(clk, reset) is
begin
	if reset = '0' then
		data_box <= x"00";
	elsif rising_edge(clk) then
		if (dataxy = '1') then
			if (ystart <= y_inz) and (y_inz < yend) then
				if x_inz(6 downto 3) = "0010" then
					case x_inz(2 downto 0) is
						when "000" => data_box <= data_disp(0); 
						when "001" => data_box <= data_disp(1);
						when "010" => data_box <= data_disp(2);
						when "011" => data_box <= data_disp(3);
						when "100" => data_box <= data_disp(4);
						when "101" => data_box <= data_disp(5);
						when "110" => data_box <= data_disp(6);
						when others => data_box <= data_disp(7);
					end case;
				else
					data_box <= x"00";	
				end if;
			else
				data_box <= x"00";
			end if;	 
		else
			data_box <= x"00";
		end if;
	end if;
end process;

addr_rom2 <= data_box(6 downto 0) & y_charzz(3 downto 0);	


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
					dataxy <= show_disp(conv_integer(x_in(2 downto 0)))(conv_integer(y_in(2 downto 0)));
				else
					dataxy <= '0';
				end if;
			else
				dataxy <= '0';
			end if;
		end if;
	end if;
end process;


data_out <= data_box;	

g_rev: for ii in 0 to 2 generate
begin
	x_rev(ii) <= not x_char(ii) when rising_edge(clk);
end generate;

x_del <= x_rev when rising_edge(clk);
x_z <= x_del when rising_edge(clk);

pr_sw_sel2: process(clk, reset) is
begin
	if reset = '0' then
		data2 <= '0';
	elsif rising_edge(clk) then
		data2 <= data_rom2(to_integer(unsigned(x_z)));
	end if;
end process;

g_rgb2: for ii in 0 to 2 generate
begin
	rgb(ii) <= data2 and color2(ii);
end generate;

end cl_mines;