--------------------------------------------------------------------------------
--
-- Title       : cl_timer_data.vhd
-- Design      : Example
-- Author      : Kapitanov
-- Company     : InSys
-- 
-- Version     : 1.0
--------------------------------------------------------------------------------
--
-- Description : Test example for DS1302 timer settings and LCD1602 RAM loading
--					DS1302 -> LCD1602
-- 
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_ARITH.all;
use IEEE.STD_LOGIC_UNSIGNED.all;

entity cl_timer_data is
	generic	( 
		TIME_SECS	: in integer range 0 to 59:=12;			--! Seconds
		TIME_MINS	: in integer range 0 to 59:=35;			--! Minutes
		TIME_HRS	: in integer range 0 to 23:=17;			--! Hours
		TIME_DTS	: in integer range 0 to 30:=13;			--! Dates
		TIME_MTHS	: in integer range 0 to 11:=07;			--! Months
		TIME_DAYS	: in integer range 0 to 59:=17;			--! Days
		TIME_YRS	: in integer range 0 to 99:=16;			--! Years
		TD			: in time := 1 ns						--! simulation time;
	);
	port(
		---- Global signals ----
		reset		:  in   std_logic;  					--! asycnchronous reset
		clk			:  in   std_logic;						--! clock 50 MHz
		restart		:  in	std_logic;						--! restart timer
		---- DS1302 signals ----
		addr		:  out	std_logic_vector(7 downto 0);	--! address for timer
		data_o		:  out  std_logic_vector(7 downto 0);	--! input data (to timer)
		data_i		:  in	std_logic_vector(7 downto 0);	--! output data (from timer)
		data_v 		:  in	std_logic;						--! valid data (from timer)
		ready		:  in	std_logic;						--! timer is ready for data
		enable		:  out	std_logic;						--! timer enable
		---- LCD1602 signals ----
		load_ena 	:  out	std_logic;						--! enable writing to LCD RAM                   
		load_dat 	:  out	std_logic_vector(7 downto 0);	--! data to LCD RAM
		load_addr	:  out	std_logic_vector(4 downto 0)	--! address to LCD RAM	
	);
end cl_timer_data;

architecture cl_timer_data of cl_timer_data is
                   	
signal sec0_lcd			: std_logic_vector(3 downto 0);	
signal sec1_lcd			: std_logic_vector(3 downto 0);
signal min0_lcd			: std_logic_vector(3 downto 0);	
signal min1_lcd			: std_logic_vector(3 downto 0);
signal hrs0_lcd			: std_logic_vector(3 downto 0);	
signal hrs1_lcd			: std_logic_vector(3 downto 0);
signal dts0_lcd			: std_logic_vector(3 downto 0);	
signal dts1_lcd			: std_logic_vector(3 downto 0);
signal mth0_lcd			: std_logic_vector(3 downto 0);	
signal mth1_lcd			: std_logic_vector(3 downto 0);
signal days_lcd			: std_logic_vector(3 downto 0);
signal yrs0_lcd			: std_logic_vector(3 downto 0);	
signal yrs1_lcd			: std_logic_vector(3 downto 0);
signal data_rom			: std_logic_vector(3 downto 0);

signal time_addr 		: std_logic_vector(3 downto 0);                 	
signal timer_v			: std_logic_vector(3 downto 0);

type tdata_timer is (secs, mins, hours, dates, months, days, years, nulls); --days,				
signal time_code 		: tdata_timer; 
signal time_codex 		: tdata_timer; 
signal time_set			: std_logic_vector(4 downto 0);
signal time_get			: std_logic_vector(3 downto 0);
signal mode				: std_logic;
signal timer_conf		: std_logic;
                    	
signal readyz			: std_logic;
signal ena				: std_logic;
signal load				: std_logic;

signal lcd_addr			: std_logic_vector(4 downto 0);

---------------- INTEGER TO STD_LOGIC_VECTOR TO BCD CONVERTER ----------------
constant n 				: integer:=8;
constant q 				: integer:=2;

function to_bcd ( bin : std_logic_vector((n-1) downto 0) ) return std_logic_vector is
	variable i : integer:=0;
	variable j : integer:=1;
	variable bcd : std_logic_vector(((4*q)-1) downto 0) := (others => '0');
	variable bint : std_logic_vector((n-1) downto 0) := bin;
begin
	for i in 0 to n-1 loop -- repeating 8 times.
		bcd(((4*q)-1) downto 1) := bcd(((4*q)-2) downto 0); --shifting the bits.
		bcd(0) := bint(n-1);
		bint((n-1) downto 1) := bint((n-2) downto 0);
		bint(0) :='0';
		
		l1: for j in 1 to q loop
			if(i < n-1 and bcd(((4*j)-1) downto ((4*j)-4)) > "0100") then --add 3 if BCD digit is greater than 4.
				bcd(((4*j)-1) downto ((4*j)-4)) := bcd(((4*j)-1) downto ((4*j)-4)) + "0011";
			end if;
		end loop l1;
	end loop;
	return bcd;
end to_bcd; 

constant temp_secs		: std_logic_vector(7 downto 0):=to_bcd(conv_std_logic_vector(TIME_SECS, 8));	-- Seconds  
constant temp_mins		: std_logic_vector(7 downto 0):=to_bcd(conv_std_logic_vector(TIME_MINS, 8));	-- Minutes  
constant temp_hrs		: std_logic_vector(7 downto 0):=to_bcd(conv_std_logic_vector(TIME_HRS,  8));	-- Hours    
constant temp_dts		: std_logic_vector(7 downto 0):=to_bcd(conv_std_logic_vector(TIME_DTS,  8));	-- Dates    
constant temp_mths		: std_logic_vector(7 downto 0):=to_bcd(conv_std_logic_vector(TIME_MTHS, 8));	-- Months   
constant temp_days		: std_logic_vector(7 downto 0):=to_bcd(conv_std_logic_vector(TIME_DAYS, 8));	-- Days     
constant temp_yrs		: std_logic_vector(7 downto 0):=to_bcd(conv_std_logic_vector(TIME_YRS,  8));	-- Years    

begin
 
readyz 		<= not ready after td when rising_edge(clk);	
ena 		<= ready and readyz after td when rising_edge(clk);	
enable 		<= ena when rising_edge(clk);	
	
--addr 		<= x"8" & time_addr after td when rising_edge(clk);	
pr_addr: process(clk, reset) is
begin
	if (reset = '0') then
		addr <= x"00";
	elsif (rising_edge(clk)) then
		addr <= x"8" & time_addr after td;
	end if;
end process;

load_dat 	<= x"3" & data_rom after td when rising_edge(clk);
load_addr 	<= lcd_addr after td when rising_edge(clk);	
load_ena 	<= load after td when rising_edge(clk);

timer_v 	<= timer_v(2 downto 0) & data_v after td when rising_edge(clk);	

---------------- TIMER CONFIGURE DATA ----------------
pr_conf: process(clk, reset) is
begin
	if (reset = '0') then
		data_o 		<= x"00";
		time_set	<= "00000";
		timer_conf	<= '0';
	elsif (rising_edge(clk)) then
		if (restart = '0') then
			time_set <= "00000" after td; 
		end if;		
		timer_conf <= time_set(4) after td; 
		if (ena = '1') then
			if time_set(4) = '0' then
				time_set <= time_set + '1' after td;
			else
				null;
			end if;
		end if;
		case time_set(3 downto 0) is 	
			when x"1" => data_o <= x"00"; -- WP: (7) bit should be '0' to enable writing data				
			when x"2" => data_o <= temp_yrs;--temp_yrs;				
			when x"3" => data_o <= temp_days;			
			when x"4" => data_o <= temp_mths;			
			when x"5" => data_o <= temp_dts;	
			when x"6" => data_o <= temp_hrs;	
			when x"7" => data_o <= temp_mins;
			when x"8" => data_o <= temp_secs; -- CH: (7) bit should be '0' to start clocking				
			when others => data_o <= x"80"; --null;
		end case;
	end if;
end process; 	
---------------- TIMER GETTING DATA ----------------
pr_timeget: process(clk, reset) is
begin
	if (reset = '0') then
		time_get 	<= x"0";
		mode		<= '1';
	elsif (rising_edge(clk)) then
		if ((ena = '1') and (timer_conf = '1')) then
			time_get <= time_get + '1' after td;
			mode 	 <= not mode after td;
		end if;
	end if;
end process;

pr_rom_load: process(clk, reset) is
begin
	if (reset = '0') then
		load <= '0';
	elsif (rising_edge(clk)) then
		if (timer_conf = '0') then
			load <= '0' after td;
		else
			load <= timer_v(3) after td;	 
		end if;
	end if;
end process;

---------------- TIMER READING DATA ----------------
pr_readback: process(clk, reset) is
begin
	if (reset = '0') then
		time_addr	<= x"0";
	elsif (rising_edge(clk)) then 
		if (restart = '0') then
			time_addr <= x"0" after td; 
		end if;
		if (timer_conf = '0') then
			case time_set(3 downto 0) is 	
				when x"1" => time_addr	<= x"E"; -- set write protect					
				when x"2" => time_addr	<= x"C"; -- year
				when x"3" => time_addr	<= x"A"; -- day					
				when x"4" => time_addr	<= x"8"; -- month					
				when x"5" => time_addr	<= x"6"; -- date					
				when x"6" => time_addr	<= x"4"; -- hour
				when x"7" => time_addr	<= x"2"; -- minute					
				when x"8" => time_addr	<= x"0"; -- second
				when others => time_addr <= x"E";
			end case;
		else
			case time_get is 	
				when x"1" | x"2" => time_addr <= x"D"; -- year					
				when x"3" | x"4" => time_addr <= x"B"; -- day					
				when x"5" | x"6" => time_addr <= x"9"; -- month					
				when x"7" | x"8" => time_addr <= x"7"; -- date					
				when x"9" | x"A" => time_addr <= x"5"; -- hour
				when x"B" | x"C" => time_addr <= x"3"; -- minute					
				when x"D" | x"E" => time_addr <= x"1"; -- second						
				when others => null;
			end case;
		end if;
	end if;
end process; 

---------------- TIMER CODES ----------------
time_codex <= secs 		when	time_addr(3 downto 1) = "000" else
			 mins 		when	time_addr(3 downto 1) = "001" else
			 hours 		when	time_addr(3 downto 1) = "010" else
			 dates		when	time_addr(3 downto 1) = "011" else
			 months 	when	time_addr(3 downto 1) = "100" else
			 days 		when	time_addr(3 downto 1) = "101" else
			 years 		when	time_addr(3 downto 1) = "110" else
		     nulls; 
		
time_code <= time_codex after td when rising_edge(clk);			 
			 
---------------- TIMER WRITE ROM ----------------
pr_data_rom: process(clk, reset) is
begin
	if (reset = '0') then
		data_rom <= x"0";
	elsif (rising_edge(clk)) then
		if (restart = '0') then
			data_rom <= x"0" after td; 
		end if;		
		if (timer_v(2) = '1') then
			case time_code is 	
				when secs => 	
					if mode = '0' then
						lcd_addr <= "11100" after td;
						data_rom <= sec0_lcd after td;
					else
						lcd_addr <= "11011" after td;
						data_rom <= sec1_lcd after td;
					end if;
				when mins =>
					if mode = '0' then
						lcd_addr <= "11001" after td;
						data_rom <= min0_lcd after td;
					else
						lcd_addr <= "11000" after td;
						data_rom <= min1_lcd after td;
					end if;			
				when hours =>
					if mode = '0' then
						lcd_addr <= "10110" after td;
						data_rom <= hrs0_lcd after td;
					else
						lcd_addr <= "10101" after td;
						data_rom <= hrs1_lcd after td;
					end if;					   
				when dates =>
					if mode = '0' then 
						lcd_addr <= "00110" after td;
						data_rom <= dts0_lcd after td;
					else
						lcd_addr <= "00101" after td;
						data_rom <= dts1_lcd after td;
					end if;				
				when months =>
					if mode = '0' then
						lcd_addr <= "01001" after td;
						data_rom <= mth0_lcd after td;
					else
						lcd_addr <= "01000" after td;
						data_rom <= mth1_lcd after td;
					end if;
	--			when days =>
	--				data_rom <= days_lcd after td;			
				when years =>
					if mode = '0' then
						lcd_addr <= "01100" after td;
						data_rom <= yrs0_lcd after td;
					else
						lcd_addr <= "01011" after td;
						data_rom <= yrs1_lcd after td;
					end if;					
				when others => 
					null;
			end case;
		end if;
	end if;
end process;

---------------- SECONDS LSB ----------------
pr_conv_sec0: process(clk, reset) is
begin
	if (reset = '0') then
		sec0_lcd 	<= x"0";
	elsif (rising_edge(clk)) then
		if ((data_v = '1') and (time_code = secs)) then
			sec0_lcd <= data_i(3 downto 0) after td;			
		end if;
	end if;
end process;
---------------- SECONDS MSB ----------------
pr_conv_sec1: process(clk, reset) is
begin
	if (reset = '0') then
		sec1_lcd 	<= x"0";
	elsif (rising_edge(clk)) then
		if ((data_v = '1') and (time_code = secs)) then
			case data_i(6 downto 4) is
				when "000" => sec1_lcd <= x"0" after td;
				when "001" => sec1_lcd <= x"1" after td;
				when "010" => sec1_lcd <= x"2" after td;
				when "011" => sec1_lcd <= x"3" after td;
				when "100" => sec1_lcd <= x"4" after td;
				when "101" => sec1_lcd <= x"5" after td;
				when others => null;
			end case;
		end if;
	end if;
end process;
---------------- MINUTES LSB ----------------
pr_conv_min0: process(clk, reset) is
begin
	if (reset = '0') then
		min0_lcd 	<= x"0";
	elsif (rising_edge(clk)) then
		if ((data_v = '1') and (time_code = mins)) then
			min0_lcd <= data_i(3 downto 0) after td;
		end if;
	end if;
end process;
---------------- MINUTES MSB ----------------
pr_conv_min1: process(clk, reset) is
begin
	if (reset = '0') then
		min1_lcd 	<= x"0";
	elsif (rising_edge(clk)) then
		if ((data_v = '1') and (time_code = mins)) then
			case data_i(6 downto 4) is
				when "000" => min1_lcd <= x"0" after td;
				when "001" => min1_lcd <= x"1" after td;
				when "010" => min1_lcd <= x"2" after td;
				when "011" => min1_lcd <= x"3" after td;
				when "100" => min1_lcd <= x"4" after td;
				when "101" => min1_lcd <= x"5" after td;
				when others => null;
			end case;
		end if;
	end if;
end process;
---------------- DATES LSB ----------------
pr_conv_dts0: process(clk, reset) is
begin
	if (reset = '0') then
		dts0_lcd 	<= x"0";
	elsif (rising_edge(clk)) then
		if ((data_v = '1') and (time_code = dates)) then
			dts0_lcd <= data_i(3 downto 0) after td;
		end if;
	end if;
end process;
---------------- DATES MSB ----------------
pr_conv_dts1: process(clk, reset) is
begin
	if (reset = '0') then
		dts1_lcd 	<= x"0";
	elsif (rising_edge(clk)) then
		if ((data_v = '1') and (time_code = dates)) then
			case data_i(5 downto 4) is
				when "00" => dts1_lcd <= x"0" after td;
				when "01" => dts1_lcd <= x"1" after td;
				when "10" => dts1_lcd <= x"2" after td;
				when "11" => dts1_lcd <= x"3" after td;
				when others => null;
			end case;
		end if;
	end if;
end process;
---------------- MONTHS LSB ----------------
pr_conv_mth0: process(clk, reset) is
begin
	if (reset = '0') then
		mth0_lcd 	<= x"0";
	elsif (rising_edge(clk)) then
		if ((data_v = '1') and (time_code = months)) then
			mth0_lcd <= data_i(3 downto 0) after td;
		end if;
	end if;
end process;
---------------- MONTHS MSB ----------------
pr_conv_mth1: process(clk, reset) is
begin
	if (reset = '0') then
		mth1_lcd 	<= x"0";
	elsif (rising_edge(clk)) then
		if ((data_v = '1') and (time_code = months)) then
			case data_i(4) is
				when '0' => mth1_lcd <= x"0" after td;
				when '1' => mth1_lcd <= x"1" after td;
				when others => null;
			end case;
		end if;
	end if;
end process;
---------------- DAYS ----------------
pr_conv_days: process(clk, reset) is
begin
	if (reset = '0') then
		days_lcd 	<= x"0";
	elsif (rising_edge(clk)) then
		if (time_code = days) then
			case data_i(2 downto 0) is
				when "000" => days_lcd <= x"1" after td;
				when "001" => days_lcd <= x"2" after td;
				when "010" => days_lcd <= x"3" after td;
				when "011" => days_lcd <= x"4" after td;
				when "100" => days_lcd <= x"5" after td;
				when "101" => days_lcd <= x"6" after td;				
				when "110" => days_lcd <= x"7" after td;				
				--when "111" => days_lcd <= x"7" after td;				
				when others => null;
			end case;
		end if;
	end if;
end process; 
---------------- HOURS LSB ----------------
pr_conv_hrs: process(clk, reset) is
begin
	if (reset = '0') then
		hrs0_lcd 	<= x"0";
		hrs1_lcd 	<= x"0";
	elsif (rising_edge(clk)) then
		if ((data_v = '1') and (time_code = hours)) then
			hrs0_lcd <= data_i(3 downto 0) after td;
			hrs1_lcd <= data_i(7 downto 4) after td;
		end if;
	end if;
end process;
---------------- YEARS LSB ----------------
pr_conv_yrs: process(clk, reset) is
begin
	if (reset = '0') then
		yrs0_lcd 	<= x"0";
		yrs1_lcd 	<= x"0";
	elsif (rising_edge(clk)) then
		if ((data_v = '1') and (time_code = years)) then
			yrs0_lcd <= data_i(3 downto 0) after td;
			yrs1_lcd <= data_i(7 downto 4) after td;
--			case data_i(3 downto 0) is
--				when x"0" => yrs0_lcd <= x"0" after td;
--				when x"1" => yrs0_lcd <= x"1" after td;
--				when x"2" => yrs0_lcd <= x"2" after td;
--				when x"3" => yrs0_lcd <= x"3" after td;
--				when x"4" => yrs0_lcd <= x"4" after td;
--				when x"5" => yrs0_lcd <= x"5" after td;
--				when x"6" => yrs0_lcd <= x"6" after td;
--				when x"7" => yrs0_lcd <= x"7" after td;
--				when x"8" => yrs0_lcd <= x"8" after td;
--				when x"9" => yrs0_lcd <= x"9" after td;
--				when others => null;
--			end case;
--			case data_i(7 downto 4) is
--				when x"0" => yrs1_lcd <= x"0" after td;
--				when x"1" => yrs1_lcd <= x"1" after td;
--				when x"2" => yrs1_lcd <= x"2" after td;
--				when x"3" => yrs1_lcd <= x"3" after td;
--				when x"4" => yrs1_lcd <= x"4" after td;
--				when x"5" => yrs1_lcd <= x"5" after td;
--				when x"6" => yrs1_lcd <= x"6" after td;
--				when x"7" => yrs1_lcd <= x"7" after td;
--				when x"8" => yrs1_lcd <= x"8" after td;
--				when x"9" => yrs1_lcd <= x"9" after td;
--				when others => null;
--			end case;
		end if;
	end if;
end process;

end cl_timer_data;