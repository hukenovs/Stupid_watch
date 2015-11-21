--------------------------------------------------------------------------------
--
-- Title       : k_vga_controller
-- Design      : Example
-- Author      : Kapitanov
-- Company     : InSys
-- 
-- Version     : 1.0
--------------------------------------------------------------------------------
--
-- Description : VGA controller for 60 Hz, 640x480 VGA Display
--
-- R G B Color  
-- 0 0 0 Black  
-- 0 0 1 Blue   
-- 0 1 0 Green  
-- 0 1 1 Cyan   
-- 1 0 0 Red    
-- 1 0 1 Magenta
-- 1 1 0 Yellow 
-- 1 1 1 White  
--
-- Sync: 
-- 
-- Ts + Tbp + Tdisp + Tfp = Ttotal
-- T1 = Tbp + Tdisp + Tfp -- logic '1' for display time and front/back porch;
-- T0 = Ts -- logic '0' for sync impulse;
--
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity vga_ctrl640x480 is
	port(
		clk		:  in   std_logic;						--! pixel clk - DCM should generate 25 MHz freq;  
		reset	:  in   std_logic;  					--! asycnchronous reset
		h_sync	:  out  std_logic;  					--! horiztonal sync pulse
		v_sync	:  out  std_logic;  					--! vertical sync pulse
		disp	:  out  std_logic;						--! display enable '1'
		x_out	:  out	std_logic_vector(9 downto 0);	--! X axis
		y_out	:  out  std_logic_vector(8 downto 0)	--! Y axis
		);
end vga_ctrl640x480;

architecture vga640x480 of vga_ctrl640x480 is

--  horizontal
constant	h_disp		:  integer		:= 640;  -- display
constant	h_s			:  integer		:= 96;   --	sync pulse 
constant	h_fp		:  integer		:= 16;   --	front porch
constant	h_bp		:  integer		:= 48;   --	back porch 
constant	h_t			:  integer		:= h_s + h_bp + h_disp + h_fp;  
--  vertical
constant	v_disp		:  integer		:= 480;   -- display
constant	v_s			:  integer		:= 2;     -- sync pulse
constant	v_fp     	:  integer		:= 10;    -- front porch
constant	v_bp     	:  integer		:= 36;    -- back porch ( --29 - XilinX, 33 -- VESA standard)
constant	v_t			:  integer		:= v_s + v_bp + v_disp + v_fp;

-- counters
signal cnt_h			: integer range 0 to h_t - 1 := 0;  
signal cnt_v			: integer range 0 to v_t - 1 := 0;      

signal vt, ht			: std_logic;

-- synopsys translate_off	
signal Tfp_h			: std_logic;
signal Tbp_h			: std_logic;
signal Tdi_h			: std_logic;
signal Tsc_h			: std_logic;
signal Ton_h			: std_logic;

signal Tfp_v			: std_logic;
signal Tbp_v			: std_logic;
signal Tdi_v			: std_logic;
signal Tsc_v			: std_logic;
signal Ton_v			: std_logic;

signal column			: integer range 0 to 640-1 := 0; -- horizontal
signal row				: integer range 0 to 480-1 := 0; -- vertical
-- synopsys translate_on

begin

pr_vga: process(reset, clk) is
begin
	if reset = '0' then
		cnt_h	<= 0;
		cnt_v	<= 0;  
		vt		<= '1';--'Z';	-- 1
		ht		<= '1';--'Z'; -- 1
		disp	<= '0';
		x_out	<= (others => '0');
		y_out	<= (others => '0');
	elsif rising_edge(clk) then
		-- counters
		if (cnt_h < h_t - 1) then
			cnt_h <= cnt_h + 1;
		else
			cnt_h <= 0;
			if(cnt_v < v_t - 1) then
				cnt_v <= cnt_v + 1;
			else
				cnt_v <= 0;
			end if;
		end if;
		--  sync pulses
		if (cnt_h < h_disp + h_fp or cnt_h >= h_disp + h_fp + h_s) then
			ht <= '1' after 1 ns;
		else
			ht <= '0' after 1 ns;
		end if;
		if (cnt_v < v_disp + v_fp or cnt_v >= v_disp + v_fp + v_s) then
			vt <= '1' after 1 ns; 
		else
			vt <= '0' after 1 ns; 
		end if;
		-- enable
		if(cnt_h < h_disp and cnt_v < v_disp) then  
			disp <= '1' after 1 ns;
		else
			disp <= '0' after 1 ns;
		end if;
		-- row and colomn
		if(cnt_h < h_disp) then  
			x_out <= std_logic_vector(to_unsigned(cnt_h,10)) after 1 ns;      
		end if;
		if(cnt_v < v_disp) then  
			y_out <= std_logic_vector(to_unsigned(cnt_v,9)) after 1 ns;      
		end if;		
	end if;		
end process;

h_sync <= ht;
v_sync <= vt;

-- synopsys translate_off 
pr_coordinate: process(reset, clk) is
begin
	if reset = '0' then
		column	<= 0;
		row		<= 0;  
	elsif rising_edge(clk) then
		if(cnt_h < h_disp) then  
			column <= cnt_h;   
		end if;
			if(cnt_v < v_disp) then 
			row <= cnt_v;         
		end if;	
	end if;		
end process;

Ton_h <= Tfp_h or Tbp_h or Tdi_h;	
pr_Thoriz: process(reset, clk) is
begin
	if reset = '0' then
		Tfp_h	<= 'X';
		Tbp_h	<= 'X';  
		Tdi_h	<= 'X';
		Tsc_h	<= 'X';
	elsif rising_edge(clk) then
		-- display
		if (cnt_h < h_disp) then
			Tdi_h <= '1';
		else
			Tdi_h <= '0';
		end if;
		-- back porch
		if (cnt_h >= h_fp + h_disp + h_s) then
			Tbp_h <= '1';
		else
			Tbp_h <= '0';
		end if;
		-- front porch
		if (cnt_h >= h_disp  and cnt_h < h_fp + h_disp) then
			Tfp_h <= '1';
		else
			Tfp_h <= '0';
		end if;		
		-- sync pulse
		if (cnt_h >= h_disp + h_fp and cnt_h < h_fp + h_disp + h_s) then
			Tsc_h <= '0';
		else
			Tsc_h <= 'Z';
		end if;			
	end if;		
end process;

Ton_v <= Tfp_v or Tbp_v or Tdi_v;	
pr_Tvert: process(reset, clk) is
begin
	if reset = '0' then
		Tfp_v	<= 'X';
		Tbp_v	<= 'X';  
		Tdi_v	<= 'X';
		Tsc_v	<= 'X';
	elsif rising_edge(clk) then
		-- display
		if (cnt_v < v_disp) then
			Tdi_v <= '1';
		else
			Tdi_v <= '0';
		end if;
		-- back porch
		if (cnt_v >= v_fp + v_disp + v_s) then
			Tbp_v <= '1';
		else
			Tbp_v <= '0';
		end if;
		-- front porch
		if (cnt_v >= v_disp  and cnt_v < v_fp + v_disp) then
			Tfp_v <= '1';
		else
			Tfp_v <= '0';
		end if;		
		-- sync pulse
		if (cnt_v >= v_disp + v_fp and cnt_v < v_fp + v_disp + v_s) then
			Tsc_v <= '0';
		else
			Tsc_v <= 'Z';
		end if;			
	end if;		
end process;
-- synopsys translate_on

end vga640x480; 