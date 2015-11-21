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
-- Description : Debounce module: remove glitches
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity ctrl_jazz is
	port(
		clk			:  in   std_logic;  --! clock	
		button		:  in	std_logic;  --! button in
		reset		:  in   std_logic;  --! reset		
		clrbutton	:  out	std_logic   --! button out
	);
end ctrl_jazz;

architecture ctrl_jazz of ctrl_jazz is

signal gcnt		: std_logic_vector(23 downto 0);
signal glbut	: std_logic;

begin

CLRBUTTON <= glbut;

glbut <= gcnt(23) when rising_edge(clk);

pr_glitches: process(clk, reset) is
begin
	if reset = '0' then
		gcnt 	<= (others => '0');
	elsif rising_edge(clk) then
		if button = '0' then
			gcnt <= gcnt + '1';
		else
			gcnt <= (others => '0');
		end if;
	end if;
end process;

end ctrl_jazz;