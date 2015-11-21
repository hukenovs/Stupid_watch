--------------------------------------------------------------------------------
--
-- Title       : ctrl_types_pkg.vhd
-- Design      : Example
-- Author      : Kapitanov
-- Company     : InSys
-- 
-- Version     : 1.0
--------------------------------------------------------------------------------
--
-- Description : Main types and components
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

package ctrl_types_pkg is
	
	type data8x8		is array (7 downto 0) of std_logic_vector(7 downto 0);
	type data3x8		is array (7 downto 0) of std_logic_vector(2 downto 0);

	type array8x1		is array (7 downto 0) of std_logic;
	type array8x8		is array (7 downto 0) of array8x1;
	
	type key_data is record
		WSAD		: std_logic_vector(3 downto 0); 	
		ENTER		: std_logic;	
		SPACE		: std_logic;
		ESC			: std_logic;
		kY			: std_logic;
		kN			: std_logic;	
	end record;	
	
	component ctrl_key_decoder is
		port(
			-- system signals	
			clk		:  in 	std_logic;		-- System clock
			-- keyboard in: 
			ps2_clk	:  in 	std_logic;		-- PS/2 CLK
			ps2_data:  in	std_logic;		-- PS/2 DATA		
			-- keyboard out: 
			keys_out	:  out	key_data;	-- Key data
			new_key		:  out	std_logic	-- Detect new key
		);
	end component;
	
	component vga_ctrl640x480 is
		port(
			clk		:  in   std_logic;							-- Pixel clk - DCM should generate 25 MHz freq;  
			reset	:  in   std_logic;  						-- Asycnchronous reset
			h_sync	:  out  std_logic;  						-- Horiztonal sync pulse
			v_sync	:  out  std_logic;  						-- Vertical sync pulse
			disp	:  out  std_logic;							-- Display enable '1'
			x_out	:  out	std_logic_vector(9 downto 0);		-- x axis
			y_out	:  out  std_logic_vector(8 downto 0)		-- y axis
		);
	end component;	
	
	component ctrl_game_block is
		generic(
			constant yend	: std_logic_vector(4 downto 0);  	-- Y end area
			constant ystart	: std_logic_vector(4 downto 0);  	-- Y start area
																 
			constant xend	: std_logic_vector(6 downto 0); 	-- X end area  
			constant xstart	: std_logic_vector(6 downto 0)  	-- X start area
		);			
		port(
			-- system signals:
			clk			:  in 	std_logic;					 	-- clock          
			reset		:  in	std_logic;					 	-- system reset   
			-- keyboard: 									 	                  
			push_keys	:  in	key_data;					 	-- ps/2 keys      
			-- vga XoY coordinates:							 	                  
			display		:  in	std_logic;					 	-- display enable 
			x_char		:  in	std_logic_vector(9 downto 0);	-- X line: 0:79   
			y_char		:  in	std_logic_vector(8 downto 0);	-- Y line: 0:29   
			-- out color scheme:							 	                  
			rgb			:  out	std_logic_vector(2 downto 0);	-- RGB data       
			leds		:  out	std_logic_vector(8 downto 1) 	-- 8 LEDs         
		);
	end component;
		
	component rtl_game_int is
		port(
			-- system signals
			reset		:  in	std_logic;							-- System reset
			clk			:  in   std_logic;							-- Pixel CLK ~25 MHz;  
			-- ps/2 signals
			ps2_clk		:  in	std_logic;							-- PS/2 CLOCK
			ps2_data	:  in	std_logic;							-- PS/2 SERIAL DATA
			-- vga output signals
			h_vga		:  out	std_logic;							-- Horizontal
			v_vga		:  out	std_logic;							-- Vertical	
			rgb			:  out	std_logic_vector(2 downto 0); 		-- RBG
			-- test leds signals
			leds		:  out	std_logic_vector(8 downto 1)		-- LEDs
		);
	end component;	
	
	component rtl_ds1302 is
		generic ( 
			TD				: in time;								-- simulation time;
			DIV_SCL			: in integer							-- Clock division for SCL: clk50m/DIV_SCL
			);                                                        
		port(                                                         
			-- global ports                                           
			clk50m			: in     std_logic;  					-- System frequency (50 MHz)                
			rstn			: in     std_logic;	 					-- '0' - negative reset
			-- main interface                                         
			enable			: in     std_logic;						-- I2c start	(S)
			addr_i			: in	 std_logic_vector(7 downto 0);	-- Address Tx: 7 bit - always '1', 0 bit - R/W ('0' - write, '1' - read)
			data_i			: in	 std_logic_vector(7 downto 0);	-- Data Tx
			data_o			: out	 std_logic_vector(7 downto 0);	-- Data Rx               
			data_v			: out	 std_logic;						-- Valid Rx              
			                                                          
			ready			: out	 std_logic;						-- Ready                                
			-- serial interface                                       
			--ds_data			: inout	 std_logic;						-- serial data	
			ds_data_i		: in	 std_logic;						-- Serial data input
			ds_data_o		: out	 std_logic;						-- Serial data output
			ds_data_t		: out	 std_logic;						-- Serial data enable		
			ds_clk			: out	 std_logic;						-- Serial clock
			ds_ena			: out	 std_logic						-- Clock enable for i2c		
			);                                                        
	end component;                                                    
	
	component rtl_lcd1602 is
		generic ( 
			TD				: in time;								-- Simulation time;
			DIV_SCL			: in integer							-- Clock division for SCL: clk50m/DIV_SCL
			);                                                         
		port(                                                          
			-- global ports                                            
			clk50m			: in     std_logic;  					-- System frequency (50 MHz)                
			rstn			: in     std_logic;	 					-- '0' - negative reset
			-- main interface                                          
			start			: in	 std_logic;						-- Start
	                                                                   
			data_ena		: in     std_logic;						-- Data enable	(S)
			data_int		: in	 std_logic_vector(7 downto 0);	-- Data Tx           
			data_sel		: in	 std_logic;						-- Select: '0' - data, '1' - command
			data_rw			: in	 std_logic;						-- Data write: write - '0', read - '1'	
			                                                           
			lcd_ready		: out	 std_logic;						-- Ready for data                                
			lcd_init		: out	 std_logic;						-- Lcd initialization complete
			-- lcd1602 interface                                       
			lcd_dt			: out	 std_logic_vector(7 downto 0);	-- Lcd data	
			lcd_en			: out	 std_logic;						-- Lcd clock enable
			lcd_rw			: out	 std_logic;						-- Lcd r/w:	write - '0', read - '1'	
			lcd_rs			: out	 std_logic						-- Lcd set: command - '0', data - '1'					
			);  
	end component;
	
	component cl_lcd_data is
		generic ( 
			TD				: in time								-- Simulation time;
			);                                                         
		port(                                                          
			reset			: in  std_logic;						-- System reset
			clk				: in  std_logic;						-- Clock 50 MHz
			
			test_mode		: in  std_logic;						-- select mode: test message or timer message
			
			load_ena		: in  std_logic;						-- Load new data
			load_dat		: in  std_logic_vector(7 downto 0); 	-- New data;
			load_addr		: in  std_logic_vector(4 downto 0); 	-- New address;
			                                                           
			disp_data		: out std_logic_vector(7 downto 0); 	-- Data to display
			disp_ena		: out std_logic;						-- Enable for data
			disp_init		: in  std_logic;						-- Ready for data
			disp_rdyt		: in  std_logic							-- Valid pulse for data		
			);
	end component;
	
	component ctrl_leds is											 	       													                                           
		port(													                 
			-- system signals:									                 
			clk			:  in 	std_logic;							-- Clock        
			clk_dv		:  in	std_logic;							-- Clock/2
			reset		:  in	std_logic;							-- System reset 
			                                                    	
			pwm_ena		:  in	std_logic;							-- Enable PWM
			-- buttons:								            	
			cbut		:  in	std_logic_vector(5 downto 1);		-- Buttons
			-- leds vectors:                                    	
			led_x		:  out	std_logic_vector(7 downto 0);		-- LED X
			led_y		:  out	std_logic_vector(7 downto 0)		-- LED y
			);
	end component;
	
	component cl_timer_data is
		generic	( 
			TIME_SECS	: in integer range 0 to 59:=12;			-- Seconds
			TIME_MINS	: in integer range 0 to 59:=35;			-- Minutes
			TIME_HRS	: in integer range 0 to 23:=17;			-- Hours
			TIME_DTS	: in integer range 0 to 30:=13;			-- Dates
			TIME_MTHS	: in integer range 0 to 11:=07;			-- Months
			TIME_DAYS	: in integer range 0 to 59:=17;			-- Days
			TIME_YRS	: in integer range 0 to 99:=86;			-- Years
			TD			: in time								-- simulation time
		);
		port(
			---- Global signals ----
			reset		:  in   std_logic;  					-- asycnchronous reset
			clk			:  in   std_logic;						-- clock 50 MHz
			restart		:  in	std_logic;						-- restart timer
			---- DS1302 signals ----
			addr		:  out	std_logic_vector(7 downto 0);	-- address for timer
			data_o		:  out  std_logic_vector(7 downto 0);	-- input data (to timer)
			data_i		:  in	std_logic_vector(7 downto 0);	-- output data (from timer)
			data_v 		:  in	std_logic;						-- valid data (from timer)
			ready		:  in	std_logic;						-- timer is ready for data
			enable		:  out	std_logic;						-- timer enable
			---- LCD1602 signals ----
			load_ena 	:  out	std_logic;						-- enable writing to LCD RAM                   
			load_dat 	:  out	std_logic_vector(7 downto 0);	-- data to LCD RAM
			load_addr	:  out	std_logic_vector(4 downto 0)	-- address to LCD RAM	
		);
	end component;	
	
	component ctrl_fanout is 
		generic(
			FD_WIDTH 	: in integer 	-- data width
		);
		port(			  
			clk			: in std_logic; -- clock		
			data_in		: in std_logic;	-- input
			data_out	: out std_logic_vector(FD_WIDTH-1 downto 0) -- output
		 ); 
	end component;  	

end ctrl_types_pkg;