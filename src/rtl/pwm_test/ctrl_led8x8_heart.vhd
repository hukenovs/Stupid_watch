-------------------------------------------------------------------------------
--
-- Title       : ctrl_led8x8_heart
-- Author      : Alexander Kapitanov
-- Company     : Instrumental Systems
-- E-mail      : kapitanov@insys.ru
--
-- Version     : 1.0
--
-------------------------------------------------------------------------------
--
-- Description : Controller for LED Matrix	
-- 					
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity ctrl_led8x8_heart is
	port (
		clk    		: in std_logic;                    		--! clock
		rst    		: in std_logic;                    		--! reset
		rst_reg		: in std_logic;                    		--! count reset
		ch_freq		: in std_logic;                    		--! change frequency
		led_y  		: out std_logic_vector(7 downto 0);		--! LED Y    
		led_x  		: out std_logic_vector(7 downto 0) 		--! LED X
	);  
end ctrl_led8x8_heart;

architecture ctr_led8x8 of ctrl_led8x8_heart is

constant	Nled	: integer:=12; -- 12

signal cnt_led 		: std_logic_vector(Nled downto 0);
signal cnt_cmd		: std_logic_vector(2 downto 0);

signal led_cmd 		: std_logic_vector(3 downto 0);
signal data_led 	: std_logic_vector(7 downto 0);

signal en_xhdl 		: std_logic_vector(7 downto 0);

signal ch_freqz		: std_logic;
signal ch_freqx		: std_logic;

signal case_cnt		: std_logic_vector(1 downto 0);

begin

ch_freqz <= ch_freq after 1 ns when rising_edge(clk);
ch_freqx <= ch_freq and not ch_freqz when rising_edge(clk);


led_y <= data_led;
led_x <= en_xhdl;

pr_case: process(clk, rst) is
begin 
	if rst = '0' then
		case_cnt <= (others => '0');
	elsif rising_edge(clk) then
--		if rst_reg = '0' then
--			case_cnt <= (others => '0');
--		elsif ch_freqx = '1' then	
--			case_cnt <= case_cnt + '1';
--		else
--			null;
--		end if;
		if ch_freqx = '1' then
			case_cnt <= case_cnt + '1';
		else
			null;
		end if;
	end if;
end process;

pr_cnt: process(clk, rst) is
begin 
	if rst = '0' then
		cnt_led <= (others => '0');
	elsif rising_edge(clk) then
		if rst_reg = '0' then
			cnt_led <= (others => '0');
		else
			case case_cnt is
				when	"00"	=> cnt_led <= cnt_led + '1';
				when	"01"	=> cnt_led <= cnt_led + "10";
				when	"10"	=> cnt_led <= cnt_led + "11";
				when others => cnt_led <= cnt_led + "100";
			end case;
		end if;
	end if;
end process;

cnt_cmd <= cnt_led(Nled downto Nled-2);

pr_3x8: process(cnt_cmd) is
begin
	case cnt_cmd is
		when	"000"	=> en_xhdl	<=	"11111110";
		when	"001"	=> en_xhdl	<=	"11111101";
		when	"010"	=> en_xhdl	<=	"11111011";
		when	"011"	=> en_xhdl	<=	"11110111";
		when	"100"	=> en_xhdl	<=	"11101111";
		when	"101"	=> en_xhdl	<=	"11011111";
		when	"110"	=> en_xhdl	<=	"10111111";
		when	"111"	=> en_xhdl	<=	"01111111";
		when others => en_xhdl	<=	"11111110";
	end case;
end process;

pr_8x4: process(en_xhdl) is
begin
	case en_xhdl is
		when	 "11111110"	=> led_cmd	<=	"0000";
		when	 "11111101"	=> led_cmd	<=	"0001";
		when	 "11111011"	=> led_cmd	<=	"0010";
		when	 "11110111"	=> led_cmd	<=	"0011";
		when	 "11101111"	=> led_cmd	<=	"0100";
		when	 "11011111"	=> led_cmd	<=	"0101";
		when	 "10111111"	=> led_cmd	<=	"0110";
		when	 "01111111"	=> led_cmd	<=	"0111";
		when others 		=> led_cmd	<=	"1000";
	end case;
end process;

pr_4x8: process(led_cmd) is
begin
	case led_cmd is		
		when "0000" =>	           
			data_led <= "11111111";    
		when "0001" =>	           
			data_led <= "11100111";    
		when "0010" =>	           
			data_led <= "11011011";    
		when "0011" =>	           
			data_led <= "10111101";    
		when "0100" =>	           
			data_led <= "01111110";    
		when "0101" =>	           
			data_led <= "01100110";    
		when "0110" =>	           
			data_led <= "10011001";    
		when "0111" =>
			data_led <= "11111111";        
		when others =>
			data_led <= "11111111"; 
	end case;
end process;

end ctr_led8x8;