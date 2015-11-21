--------------------------------------------------------------------------------
--
-- Title       : top_xc3s500e_ex.vhd
-- Design      : Example
-- Author      : Kapitanov
-- Company     : InSys
-- 
-- Version     : 1.0
--------------------------------------------------------------------------------
--
-- Description : Top level for timer based on Spartan3E Starter Kit
-- 
-- Xilinx Spartan3e - XC3S500E-4FG320C 
-- Switches, LEDs, TIMER (ds1302), display (lcd1602)
--
-- SW<0> - RESET
-- SW<1> - ENABLE
-- SW<2> - PWM
-- SW<3> - START
--
--
--------------------------------------------------------------------------------

library IEEE;	--! main standard libs
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_UNSIGNED.all;

library UNISIM;	--! xilinx unusim libs
use UNISIM.VCOMPONENTS.ALL;

library WORK;	--! user work libs
use WORK.ctrl_types_pkg.all;

entity top_xc3s500e_ex is
	generic	( 
		TD				: in time := 1 ns ;	--! simulation time;
		DIV_SCL			: in integer := 100	--! clock division for logic counters
	);
	port(
		---- SWITCHES ----
		RESET		:  in   std_logic;  --! asycnchronous reset: SW(0)
		PWM			:  in	std_logic;  --! PWM Enable : SW(1)
		LCD			:  in	std_logic;	--! LCD/LED Switch : SW(2)	
		START		:  in	std_logic;	--! LCD Controller Start : SW(3)
		RESTART		:  in	std_logic;	--! RESTART Timer DS1302
		TEST_LCD	:  in	std_logic;  --! TEST LCD DISPLAY
		---- PS/2 IO ----
		PS2_CLK		:  in	std_logic;	--! PS/2 clk (keyboard)
		PS2_DATA	:  in	std_logic;	--! PS/2 data (keyboad)			
		---- CLOCK 50 MHz ----
		CLK			:  in   std_logic;	--! main clock 50 MHz
		---- VGA SYNC ----
		VGA_HSYNC	:  out  std_logic;  --! horiztonal sync
		VGA_VSYNC	:  out  std_logic;  --! vertical sync
		VGA_R		:  out	std_logic;	--! VGA Red
		VGA_G		:  out	std_logic;	--! VGA Green
		VGA_B		:  out	std_logic;	--! VGA Blue
		---- LED DISPLAY ----
		LED_X		:  out	std_logic_vector(7 downto 3);	--! LEDs Y
		--LED_Y		:  out	std_logic_vector(7 downto 0);	--! LEDs X	
		---- BUTTONS ----
		KB			:  in	std_logic_vector(5 downto 1); --! Five Buttons
		---- SERIAL TIMER ----
		T_DT		: inout std_logic;	--! timer serial data
		T_CK		: out 	std_logic;	--! timer serial clock (~1 MHz)
		T_CE		: out	std_logic;	--! timer serial enable
		-- LCD1602 INTERFACE
		LCD_DT		: out	 std_logic_vector(7 downto 0);	--! LCD Data	
		LCD_EN		: out	 std_logic;						--! LCD Enable
		LCD_RW		: out	 std_logic;						--! LCD R/W (write - '0', read - '1')	
		LCD_RS		: out	 std_logic;						--! LCD RS (command - '0', data - '1')					
		-- TEST POINTS
		TST			: out	 std_logic_vector(2 downto 0);	--! Test points
		---- DOORBELL ----
		BELL		:  out	std_logic --! BELL (tie to VCC)
	);
end top_xc3s500e_ex;

architecture top_xc3s500e_ex of top_xc3s500e_ex is

---------------- SIGNALS DECLARATION ----------------
signal ps2_clock	: std_logic;
signal ps2_din		: std_logic;

signal sys_reset	: std_logic;
signal reset_v		: std_logic_vector(6 downto 0);
signal rst			: std_logic;
signal rstz			: std_logic;

signal RGB			: std_logic_vector(2 downto 0);

signal clk_fb		: std_logic;
signal clk0			: std_logic;
signal clk_in		: std_logic;
signal locked		: std_logic;
signal clk_dv		: std_logic;
signal rst_dcm		: std_logic;

signal v, h			: std_logic;

--signal leds			: std_logic_vector(8 downto 1);
signal led_hearty	: std_logic_vector(7 downto 0);
signal led_heartx : std_logic_vector(7 downto 0);

signal pwm_ena		: std_logic;

signal button 		: std_logic_vector(5 downto 1);


signal switch_lcd	: std_logic;

signal time_addr	: std_logic_vector(7 downto 0);
signal time_data_i	: std_logic_vector(7 downto 0);
signal time_data_o	: std_logic_vector(7 downto 0);
signal time_data_v	: std_logic;
signal time_rdy		: std_logic;
signal time_enable	: std_logic;

signal disp_dt		: std_logic_vector(7 downto 0);	
signal disp_en		: std_logic;						
signal disp_rw		: std_logic;						
signal disp_rs		: std_logic;						
signal disp_start	: std_logic;
signal disp_rdy		: std_logic;
signal disp_init	: std_logic;

signal disp_data	: std_logic_vector(7 downto 0);	
signal disp_com		: std_logic:='0';						
signal disp_ena		: std_logic;	

signal buff_dt		: std_logic_vector(7 downto 0);	
signal buff_en		: std_logic;						
signal buff_rw		: std_logic;						
signal buff_rs		: std_logic;
signal buff_xx		: std_logic_vector(7 downto 3);

--signal cnt			: std_logic_vector(5 downto 0):="000000";
signal rstart		: std_logic;

signal disp_rdyz	: std_logic;
signal disp_rdyt	: std_logic;

signal ds_data_i 	: std_logic;
signal ds_data_o 	: std_logic;
signal ds_data_t 	: std_logic;
signal ds_data_tn 	: std_logic;

signal load_ena 	: std_logic;				 
signal load_dat 	: std_logic_vector(7 downto 0);
signal load_addr	: std_logic_vector(4 downto 0);

signal test_mode	: std_logic;

begin

disp_rdyz <= not disp_rdy after td when rising_edge(clk_in);
disp_rdyt <= disp_rdyz and disp_rdy after td when rising_edge(clk_in);	

---------------- TIMER TRANSFER ----------------
x_SET_TIME: cl_timer_data 
	generic map (                  	
		TIME_SECS	=> 47,				-- seconds 
		TIME_MINS	=> 59,				-- minutes 
		TIME_HRS 	=> 13,				-- hours   
		TIME_DTS 	=> 19,				-- dates   
		TIME_MTHS	=> 09,				-- months  
		TIME_DAYS	=> 06,				-- days    
		TIME_YRS 	=> 15,				-- years   
		TD			=> TD				-- simulation time;
		)                          	
	port map(                      	
		---- Global signals ----   	
		reset		=> reset_v(0),  	-- asycnchronous reset   
		clk			=> clk_in,			-- clock 50 MHz          
		restart		=> rstart,			-- restart timer						
		---- DS1302 signals ----   	
		addr		=> time_addr,		-- address for timer
		data_o		=> time_data_i,		-- input data (to timer)
		data_i		=> time_data_o,	 	-- output data (from timer)
		data_v 		=> time_data_v,		-- valid data (from timer)
		ready		=> time_rdy,		-- timer is ready for data
		enable		=> time_enable,		-- timer enable
		---- LCD1602 signals ----
		load_ena 	=> load_ena,		-- enable writing to LCD RAM                   
		load_dat 	=> load_dat, 		-- data to LCD RAM
		load_addr	=> load_addr		-- address to LCD RAM	
	);
---------------- LCD1602 TRANSFER ----------------	
x_LCD_TST: cl_lcd_data 
	generic map ( 
		TD			=> TD	-- simulation time;
		)
	port map(
		reset			=> reset_v(1),  -- system frequency (50 MHz)  
		clk				=> clk_in,		-- '0' - negative reset       
		
		test_mode		=> test_mode,	-- select mode: test message or timer
		
		load_ena		=> load_ena,	-- load new data
		load_dat		=> load_dat,  	-- new data;
		load_addr		=> load_addr, 	-- new address;
		
		disp_data		=> disp_data, 	-- data to display
		disp_ena		=> disp_ena,	-- enable for data
		disp_init		=> disp_init,	-- ready for data
		disp_rdyt		=> disp_rdyt	-- valid pulse for data		
	);
---------------- LCD1602 CONTROLLER ----------------
x_LCD1602: rtl_lcd1602 
	generic map ( 
		TD			=> TD,	-- simulation time;
		DIV_SCL		=> 5000	-- clock division for SCL: clk50m/DIV_SCL
		)
	port map(
		-- global ports
		clk50m			=> clk_in,  	-- system frequency (50 MHz)                
		rstn			=> reset_v(2),	-- '0' - negative reset
		-- main interface
		start			=> disp_start,	-- start                              		
                                                                                                        		
		data_ena		=> disp_ena, 	-- data enable	(S)                     		
		data_int		=> disp_data, 	-- data Tx                              		
		data_sel		=> disp_com, 	-- select: '0' - data, '1' - command    		
		data_rw			=> '0',			-- 	WRITE ONLY;
		
		lcd_ready		=> disp_rdy,	-- ready for data                       		
		lcd_init		=> disp_init,	-- lcd initialization complete          		
		-- lcd1602 interface                                                                            		
		lcd_dt			=> disp_dt,		-- lcd data	                            		
		lcd_en			=> disp_en,		-- lcd clock enable                     		
		lcd_rw			=> disp_rw,		-- lcd r/w:	write - '0', read - '1'	    		
		lcd_rs			=> disp_rs		-- lcd set: command - '0', data - '1'			
	);
---------------- DS1302 CONTROLLER ----------------
x_DS1302: rtl_ds1302 
	generic map ( 
		TD			=> TD,		-- simulation time;
		DIV_SCL		=> DIV_SCL	-- clock division for SCL: clk50m/DIV_SCL
		)
	port map(
		-- global ports
		clk50m			=> clk_in,  	-- system frequency (50 MHz)                
		rstn			=> reset_v(3),  -- '0' - negative reset
		-- main interface
		enable			=> time_enable,	-- i2c start	(S)
		addr_i			=> time_addr,	-- address Tx: 7 bit - always '1', 0 bit - R/W ('0' - write, '1' - read)
		data_i			=> time_data_i,	-- data Tx
		data_o			=> time_data_o,	-- data Rx               
		data_v			=> time_data_v,	-- valid Rx 
		
		ready			=> time_rdy,	-- ready                                
		-- serial interface
		--ds_data		=> T_DT,--ds_data,	-- serial data
		ds_data_i		=> ds_data_i,	-- serial data input
		ds_data_o		=> ds_data_o,	-- serial data output
		ds_data_t		=> ds_data_t,	-- serial data enable		
		
		ds_clk			=> T_CK,		-- serial clock
		ds_ena			=> T_CE			-- clock enable for i2c		
	); 						   		
---------------- MINESWEEPER GAME ----------------	
x_MAIN_BLOCK : rtl_game_int
	port map(
		clk			=> clk_dv,		-- 25 MHz freq;  
		reset		=> reset_v(4),  -- GLOBAL RESET
		
		ps2_clk		=> ps2_clock,  -- PS/2 CLOCK         
		ps2_data	=> ps2_din,	   -- PS/2 SERIAL DATA   
								                         
		h_vga		=> H,		   -- HORIZONTAL         
		v_vga		=> V,		   -- VERTICAL	          
		rgb			=> RGB		   -- (R-G-B)
		
		--leds		=> LEDS		   -- LEDs
	);
---------------- HEART XY 8X8 ----------------	
pr_lcd_sw: process(clk_in, reset_v(5)) is
begin
	if (reset_v(5) = '0') then
		buff_dt		<= x"00";
		buff_en		<= '0';  
		buff_rw		<= '0';	 
		buff_rs		<= '0';
	elsif rising_edge(clk_in) then
		if switch_lcd = '1' then
			buff_dt		<= disp_dt;
			buff_en		<= disp_en;
			buff_rw		<= disp_rw;
			buff_rs		<= disp_rs;
		else
			x_rev: for ii in 0 to 7 loop
				buff_dt(ii)	<= led_hearty(7-ii);
			end loop;
			buff_rs		<= led_heartx(0);
			buff_rw		<= led_heartx(1);
			buff_en		<= led_heartx(2);
			buff_xx		<= led_heartx(7 downto 3);
		end if;			
	end if;
end process;	

ds_data_tn <= ds_data_t;

---------------- I/O BUFFERS ----------------
TST(0) <= ds_data_o;
TST(1) <= ds_data_tn;
TST(2) <= ds_data_i;

xDSIO: iobuf port map(i => ds_data_o,  o => ds_data_i, io => T_DT, t => ds_data_tn);

xPS2C: ibuf port map(i => ps2_clk,  o => ps2_clock);
xPS2D: ibuf port map(i => ps2_data, o => ps2_din);	

xRESET: ibuf port map(i => RESET, o => rst);
xPWM: 	ibuf port map(i => PWM,   o => pwm_ena);
xSTART: ibuf port map(i => START, o => disp_start);
xRESTART: ibuf port map(i => RESTART, o => rstart);

xBELL:	obuf port map(i => '1', o => BELL);

xVGA_v:	obuf port map(i => v, o => VGA_VSYNC);
xVGA_h:	obuf port map(i => h, o => VGA_HSYNC);	
	
xVGA_R:	obuf port map(i => RGB(2), o => VGA_R);
xVGA_G:	obuf port map(i => RGB(1), o => VGA_G);
xVGA_B:	obuf port map(i => RGB(0), o => VGA_B);

xLCD_EN: obuf port map(i => buff_en, o => LCD_EN);
xLCD_RW: obuf port map(i => buff_rw, o => LCD_RW);
xLCD_RS: obuf port map(i => buff_rs, o => LCD_RS);

xLCD_DT: for ii in 0 to 7 generate
	xLCD_DATA: obuf port map(i => buff_dt(ii), o => LCD_DT(ii));	
end generate;

xLCD_SW: ibuf port map(i => LCD, o => switch_lcd);
xLCD_TST: ibuf port map(i => TEST_LCD, o => test_mode);

xBUTS: for ii in 1 to 5 generate
	xswitch: ibuf port map(i => KB(ii), o => button(ii));
end generate;

-- LEDS: 
xLED_XY: for ii in 3 to 7 generate
	ledx: obuf port map(i => buff_xx(ii), o => LED_X(ii));
--	ledy: obuf port map(i => led_hearty(ii), o => LED_Y(ii));
end generate;

---------------- DEBOUNCE ----------------
xCTRL_8x8 : ctrl_leds
	port map (
		-- System signals:
		clk			=> clk0,
		clk_dv 		=> clk_dv,
		reset 		=> reset_v(6),
		pwm_ena		=> pwm_ena,
		-- Buttons:		
		cbut		=> button,
		-- Leds vectors:
		led_x 		=> led_heartx,
		led_y		=> led_hearty
	);

---------------- DCM CLOCK ----------------
xCLKFB:	bufg port map(i => clk0, o => clk_fb);
xCLKIN:	ibufg port map(i => clk,o => clk_in);

sys_reset <= (rstz and locked) after td when rising_edge(clk_in);	

xFD_RST: ctrl_fanout 
	generic map(
		FD_WIDTH => 7)	
	port map( 
		clk 		=> clk_in, 
		data_in 	=> sys_reset,
		data_out 	=> reset_v
	);
--xgen_rst: for ii in 0 to 7 generate
--reset_v(ii) <= sys_reset after td when rising_edge(clk_in);
--end generate;

xSRL_RESET: srlc16
	generic map (
		init => x"0000"
	)
	port map(
		Q15		=> rstz,
		A0		=> '1',
		A1		=> '1',
		A2		=> '1',
		A3		=> '1',
		CLK		=> clk_in,
		D		=> rst -- '1',
	);	

rst_dcm <= not rst;	
---------------- CLOCK GENERATOR - DCM ----------------
xDCM_CLK_VGA : dcm
generic map(
		--DCM_AUTOCALIBRATION 	=> FALSE,	-- DCM ADV
		CLKDV_DIVIDE 			=> 2.0,		-- clk divide for CLKIN: Fdv = Fclkin / CLK_DIV
		CLKFX_DIVIDE 			=> 2,		-- clk divide for CLKFX and CLKFX180 : Ffx = (Fclkin * MULTIPLY) / CLKFX_DIV
		CLKFX_MULTIPLY 			=> 2,		-- clk multiply for CLKFX and CLKFX180 : Ffx = (Fclkin * MULTIPLY) / CLKFX_DIV
		CLKIN_DIVIDE_BY_2 		=> FALSE,	-- divide clk / 2 before DCM block
		CLKIN_PERIOD 			=> 20.0,	-- clk period in ns (for DRC)
		CLKOUT_PHASE_SHIFT 		=> "NONE",	-- phase shift mode: NONE, FIXED, VARIABLE		
		CLK_FEEDBACK 			=> "1X",	-- freq on the feedback clock: 1x, 2x, None
		DESKEW_ADJUST 			=> "SYSTEM_SYNCHRONOUS",	-- clk delay alignment
		DFS_FREQUENCY_MODE 		=> "LOW",	-- freq mode CLKFX and CLKFX180: LOW, HIGH
		DLL_FREQUENCY_MODE 		=> "LOW",	-- freq mode CLKIN: LOW, HIGH
		DUTY_CYCLE_CORRECTION 	=> TRUE,	-- 50% duty-cycle correction for the CLK0, CLK90, CLK180 and CLK270: TRUE, FALSE
		PHASE_SHIFT			 	=> 0		-- phase shift (with CLKOUT_PHASE_SHIFT): -255 to 255 
	)
	port map(
		clk0 		=> clk0,
--		clk180 		=> clk180,
--		clk270 		=> clk270,
--		clk2x 		=> clk2x,
--		clk2x180 	=> clk2x180,
--		clk90 		=> clk90,
		clkdv 		=> clk_dv,
--		clkfx 		=> clkfx,
--		clkfx180 	=> clkfx180,
		locked 		=> locked,
--		status 		=> status,
--		psdone 		=> psdone,	

		clkfb 		=> clk_fb,
		clkin 		=> clk_in,
--		dssen 		=> dssen,
--		psclk 		=> psclk,
		psen 		=> '0',
		psincdec 	=> '0',
		rst 		=> rst_dcm
	);

end top_xc3s500e_ex;