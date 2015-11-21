--------------------------------------------------------------------------------
--
-- Title       : ctrl_leds.vhd
-- Design      : Example
-- Author      : Kapitanov
-- Company     : InSys
-- 
-- Version     : 1.0
--------------------------------------------------------------------------------
--
-- Description : Controller LEDs 8x8
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity ctrl_leds is											 	       													                                           
	port(													                 
		-- system signals:									                 
		clk			:  in 	std_logic;						--! clock        
		clk_dv		:  in	std_logic;						--! clock/2
		reset		:  in	std_logic;						--! system reset 
		                                                        
		pwm_ena		:  in	std_logic;						--! enable PWM
		-- buttons:								                
		cbut		:  in	std_logic_vector(5 downto 1);	--! buttons
		-- leds vectors:
		led_x		:  out	std_logic_vector(7 downto 0);	--! LED X
		led_y		:  out	std_logic_vector(7 downto 0)	--! LED y
		);
end ctrl_leds;

architecture ctrl_leds of ctrl_leds is

component ctrl_led8x8_heart is
	port (
		clk    	: in std_logic;   							-- Clock             
		rst    	: in std_logic;								-- Reset             
		rst_reg	: in std_logic;								-- Count reset       
		ch_freq	: in std_logic;								-- Change frequency  
		led_y  	: out std_logic_vector(7 downto 0); 		-- LED Y               
		led_x  	: out std_logic_vector(7 downto 0)			-- LED X             
	);  
end component;

component ctrl_pwm is
	port (
		clk         : in std_logic;   	-- Clock              
		rst         : in std_logic;	  	-- Reset              
		rst_reg		: in std_logic;	  	-- Count reset        
		zoom_reg	: in std_logic;	  	-- Switch change      
		zoom_cnt	: in std_logic;   	-- Switch counter     
		log_led     : out std_logic   	-- Pulsed LED enable     
	);  							                         
end component;

component ctrl_jazz is
	port(
		clk			:  in   std_logic;	-- Clock	    	
		button		:  in	std_logic;	-- Button in   
		reset		:  in   std_logic;	-- Reset		  		
		clrbutton	:  out	std_logic 	-- Button out  
	);
end component;

signal clbutton 	: std_logic_vector(5 downto 1);

signal log_led		: std_logic;
signal log_hearty	: std_logic_vector(7 downto 0);
signal log_heartx 	: std_logic_vector(7 downto 0);

begin

x_GEN_LEDX : for ii in 0 to 7 generate
	led_x(ii) <= log_led or log_heartx(ii) when pwm_ena = '0' else log_heartx(ii); 
end generate;
x_GEN_LEDY : for ii in 0 to 7 generate
	led_y(ii) <= (log_led or log_hearty(ii)) when pwm_ena = '0' else log_hearty(ii); 
end generate;

---------------- PULSE-WITDH MODULO ----------------
xCTRL_PWM : ctrl_pwm
	port map (
		clk 		=> clk_dv,
		rst 		=> reset,
		rst_reg		=> clbutton(1),
		zoom_reg	=> clbutton(2),
		zoom_cnt	=> clbutton(3),
		log_led 	=> log_led
	);

---------------- CTRL MATRIX 8X8 ----------------
xCTRL_LED : ctrl_led8x8_heart 
	port map (
		clk 		=> clk_dv,
		rst 		=> reset,
		rst_reg 	=> clbutton(1),
		ch_freq		=> clbutton(2),
		led_y 		=> log_hearty,
		led_x 		=> log_heartx
	);

---------------- DEBOUNCE ----------------
xDEBOUNCE: for ii in 1 to 5 generate 
	x_buttons:	ctrl_jazz
		port map (
			clk			=> clk,	
			button		=> cbut(ii),
			reset		=> reset, 		
			clrbutton	=> clbutton(ii)
		);
end generate; 

end ctrl_leds;