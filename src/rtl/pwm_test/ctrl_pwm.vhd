--------------------------------------------------------------------------------
--
-- Title       : ctrl_pwm.vhd
-- Design      : Example
-- Author      : Kapitanov
-- Company     : InSys
-- 
-- Version     : 1.0
--------------------------------------------------------------------------------
--
-- Description : Pulse-width modulation
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity ctrl_pwm is
	port (
		clk            : in  std_logic;  --! clock  
		rst            : in  std_logic;  --! reset
		rst_reg		   : in  std_logic;  --! count reset      
		zoom_reg	   : in  std_logic;  --! switch change 
		zoom_cnt	   : in  std_logic;  --! switch counter
		log_led        : out std_logic	 --! pulsed LED enable    
	);  
end ctrl_pwm;

architecture ctrl_pwm of ctrl_pwm is
 
constant Nmax		: integer:=19;
constant Ncnt		: integer:=13;
 
signal cnt_dec		: std_logic_vector(Ncnt downto 0);
signal thrsh		: std_logic_vector(Ncnt downto 0); 

signal cnt_big		: std_logic_vector(Nmax downto 0);



signal zoom_regz	: std_logic;
signal front_reg	: std_logic;

signal zoom_cntz	: std_logic;
signal front_cnt	: std_logic;

signal switch_reg : std_logic_vector(2 downto 0);
signal switch_cnt : std_logic_vector(2 downto 0);

begin

zoom_cntz <= zoom_cnt when rising_edge(clk);
zoom_regz <= zoom_reg when rising_edge(clk);

front_reg <= zoom_reg and not zoom_regz after 1 ns when rising_edge(clk);
front_cnt <= zoom_cnt and not zoom_cntz after 1 ns when rising_edge(clk);

pr_switch: process(clk, rst) is
begin
	if rst = '0' then	
		switch_reg <= (others => '0');
		switch_cnt <= (others => '0');
	elsif rising_edge(clk) then
--		if rst_reg = '0' then
--			switch_reg <= (others => '0');
--			switch_cnt <= (others => '0');
--		else
			if front_reg = '1' then
				switch_reg <= switch_reg + '1';
			else
				null;
			end if;
			if front_cnt = '1' then
				switch_cnt <= switch_cnt + '1';
			else
				null;
			end if;			
--		end if;
	end if;
end process;		

pr_case_cnt: process(clk, rst) is
begin
	if rst = '0' then	
		cnt_dec <= (others => '0');
	elsif rising_edge(clk) then
--		if rst_reg = '0' then
--			cnt_dec <= (others => '0') after 1 ns;
--		else
			if cnt_dec(Ncnt) = '0' then
				cnt_dec <= cnt_dec + '1' after 1 ns;
			else
				cnt_dec <= (others => '0') after 1 ns;
--			end if;
		end if;
	end if;
end process;

pr_thrs: process(clk, rst) is
begin
	if rst = '0' then	
		thrsh	<= (others => '0');
	elsif rising_edge(clk) then	
--		if rst_reg = '0' then
--			thrsh <= (others => '0') after 1 ns;
--		else		
			if cnt_big(Nmax) = '1' then	
				if thrsh(Ncnt) = '1' then
					thrsh <= (others => '0') after 1 ns;
				else
					thrsh <= thrsh + '1' after 1 ns;
				end if;
			else
				null;
			end if;
--		end if;
	end if;
end process;

pr_case_reg: process(clk, rst) is
begin
	if rst = '0' then	
		cnt_big 	<= (others => '0');
	elsif rising_edge(clk) then
--		if rst_reg = '0' then
--			cnt_big <= (others => '0') after 1 ns;
--		else			
			if cnt_big(Nmax) = '0' then
				case switch_cnt is 
					when "000" => cnt_big <= cnt_big + '1' after 1 ns;
					when "001" => cnt_big <= cnt_big + "10" after 1 ns;
					when "010" => cnt_big <= cnt_big + "100" after 1 ns;
					when "011" => cnt_big <= cnt_big + "1000" after 1 ns;
					when "100" => cnt_big <= cnt_big + "1100" after 1 ns;				
					when "101" => cnt_big <= cnt_big + "10000" after 1 ns;				
					when "110" => cnt_big <= cnt_big + "10100" after 1 ns;	
					when others => cnt_big <= cnt_big + "11100" after 1 ns;					
				end case;
			else
				cnt_big <= (others => '0') after 1 ns;
			end if;
--		end if;
	end if;
end process;
	
log_led <= '0' when unsigned(cnt_dec) < unsigned(thrsh) else '1';

end ctrl_pwm;