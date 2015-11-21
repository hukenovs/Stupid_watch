--------------------------------------------------------------------------------
--
-- Title       : ctrl_fanout.vhd
-- Design      : Example
-- Author      : Kapitanov
-- Company     : InSys
-- 
-- Version     : 1.0
--------------------------------------------------------------------------------
--
-- Description : Simple FD from Xilinx Spartan3e primitive
-- 
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

library unisim;
use unisim.vcomponents.FD;

entity ctrl_fanout is 
	generic(
		FD_WIDTH 	: in integer 	--! data width
	);
	port(			  
		clk			: in std_logic; --! clock		
		data_in		: in std_logic;	-- input
		data_out	: out std_logic_vector(FD_WIDTH-1 downto 0) --! output
	 ); 
end ctrl_fanout;
														 
architecture ctrl_fanout of ctrl_fanout is  

begin

x_fd_gen: for ii in 0 to FD_WIDTH-1 generate
	x_fdr: FD
		port map (
		    Q => data_out(ii),		
		    C => clk,
		    D => data_in
		);
end generate;		
		
end ctrl_fanout;