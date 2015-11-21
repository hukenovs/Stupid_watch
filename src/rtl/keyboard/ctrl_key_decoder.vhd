--------------------------------------------------------------------------------
--
-- Title       : ctrl_key_decoder.vhd
-- Design      : Example
-- Author      : Kapitanov
-- Company     : InSys
-- 
-- Version     : 1.0
--------------------------------------------------------------------------------
--
-- Description : Keyboard data decoder
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use work.ctrl_types_pkg.key_data;

entity ctrl_key_decoder is
	port(
		-- system signals	
		clk			:  in 	std_logic;						--! system clock
		-- keyboard in: 									  
		ps2_clk		:  in 	std_logic;						--! PS/2 CLK
		ps2_data	:  in	std_logic;						--! PS/2 DATA		
		-- keyboard out: 									  
		keys_out	:  out	key_data;						--! key data
		new_key		:  out	std_logic						--! detect new key
	);
end ctrl_key_decoder;

architecture ctrl_key_decoder of ctrl_key_decoder is

component ps2_keyboard is
    generic(
        clk_freq     : integer; 							--! System clock frequency in Hz
        db_cnt_size  : integer								--! Set such that (2^size)/clk_freq = 5us (size = 8 for 50MHz)
    );         		
    port(													   
        clk          : in  std_logic;                     	--! System clock
        ps2_clk      : in  std_logic;                     	--! Clock signal from PS/2 keyboard
        ps2_data     : in  std_logic;                     	--! Data signal from PS/2 keyboard
        ps2_code_new : out std_logic;                     	--! New PS/2 code is available
        ps2_code     : out std_logic_vector(7 downto 0)		--! Code received from PS/2
    ); 
end component;

signal new_code		: std_logic;
signal key_code		: std_logic_vector(7 downto 0);
signal key_codez	: std_logic_vector(7 downto 0);


signal arrowU, arrowD, arrowL, arrowR : std_logic;
signal arrowEn, arrowSp, arrowY, arrowN : std_logic;
signal Esc	: std_logic;

begin
	
key_codez <= key_code after 1 ns when rising_edge(clk);	
	
------------------------------------------------  	
new_key <= new_code when rising_edge(clk);		
------------------------------------------------
keys_out.wsad	<= arrowU & arrowD & arrowL & arrowR when rising_edge(clk);
keys_out.enter	<= arrowEn when rising_edge(clk);
keys_out.space	<= arrowSp when rising_edge(clk);	
keys_out.kY		<= arrowY when rising_edge(clk);	
keys_out.kN		<= arrowN when rising_edge(clk);
keys_out.Esc	<= Esc when rising_edge(clk);
------------------------------------------------	
arrowU <= '1' when key_codez = x"1D" and key_code = x"F0" else '0'; 
arrowD <= '1' when key_codez = x"1B" and key_code = x"F0" else '0'; 
arrowL <= '1' when key_codez = x"1C" and key_code = x"F0" else '0'; 
arrowR <= '1' when key_codez = x"23" and key_code = x"F0" else '0'; 
 
arrowN <= '1' when key_codez = x"31" and key_code = x"F0" else '0';
arrowY <= '1' when key_codez = x"35" and key_code = x"F0" else '0';
arrowSp <= '1' when key_codez = x"29" and key_code = x"F0" else '0';
arrowEn <= '1' when key_codez = x"5A" and key_code = x"F0" else '0';
Esc <= '1' when	key_codez = x"76" and key_code = x"F0" else '0';
------------------------------------------------	
x_key: ps2_keyboard
	generic map(
		clk_freq        => 50_000_000,
		db_cnt_size 	=> 8
	)        
	port map(
		clk          => clk,
		ps2_clk      => ps2_clk,
		ps2_data     => ps2_data,
		ps2_code_new => new_code,
		ps2_code     => key_code
	);

end ctrl_key_decoder;