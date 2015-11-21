--------------------------------------------------------------------------------
--
-- Title       : ctrl_game_block.vhd
-- Design      : Example
-- Author      : Kapitanov
-- Company     : InSys
-- 
-- Version     : 1.0
--------------------------------------------------------------------------------
--
-- Description : Main game block for minesweeper
--
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

use work.ctrl_types_pkg.key_data;
use work.ctrl_types_pkg.data8x8;
use work.ctrl_types_pkg.data3x8;
use work.ctrl_types_pkg.array8x8;

use work.ctrl_comp_pkg.all;

entity ctrl_game_block is
	generic(
		constant yend		: std_logic_vector(4 downto 0); --! Y end area
		constant ystart		: std_logic_vector(4 downto 0); --! Y start area
																 
		constant xend		: std_logic_vector(6 downto 0); --! X end area  
		constant xstart		: std_logic_vector(6 downto 0)  --! X start area
	);		
	port(
		-- system signals:
		clk			:  in 	std_logic;						--! clock
		reset		:  in	std_logic;						--! system reset
		-- keyboard: 										  
		push_keys	:  in	key_data;						--! ps/2 keys
		-- vga XoY coordinates:								  
		display		:  in	std_logic;						--! display enable
		x_char		:  in	std_logic_vector(9 downto 0); 	--! X line: 0:79
		y_char		:  in	std_logic_vector(8 downto 0); 	--! Y line: 0:29
		-- out color scheme:
		rgb			:  out	std_logic_vector(2 downto 0);	--! RGB data
		leds		:  out	std_logic_vector(8 downto 1)	--! 8 LEDs
		);
end ctrl_game_block;

architecture ctrl_game_block of ctrl_game_block is

function conv8x8to64 (data_in : array8x8) return std_logic_vector is
variable vector64	: std_logic_vector(63 downto 0);
begin 
	x_loop8: for jj in 0 to 7 loop
		y_loop8 :for ii in 0 to 7 loop
			vector64(ii+jj*8) := data_in(jj)(ii);
		end loop;
	end loop;
	return vector64; 
end conv8x8to64;	

component ctrl_8x16_rom is
	port(
		clk		:	in std_logic;					 	-- clock           
		addr	:	in std_logic_vector(10 downto 0);	-- ROM address 2^11
		data	:	out std_logic_vector(7 downto 0) 	-- ROM data 1 byte 
	);
end component;

type game_fsm is (WAIT_START, PLAY, CHECK, GAME_OVER, RST);
signal game_status : game_fsm; 

signal addr_rnd : std_logic_vector(4 downto 0):="00000";

signal show_field, show_bad_msg, display_text: std_logic;

signal x_in				: std_logic_vector(6 downto 0);
signal y_in				: std_logic_vector(4 downto 0);

signal x_inz			: std_logic_vector(6 downto 0);
signal x_inzz			: std_logic_vector(6 downto 0);
signal y_inz			: std_logic_vector(4 downto 0);
signal y_inzz			: std_logic_vector(4 downto 0);

signal cnt_yy			: std_logic_vector(2 downto 0);
signal cnt_xx			: std_logic_vector(2 downto 0);

signal comp_yy			: std_logic_vector(6 downto 0);
signal comp_xx			: std_logic_vector(4 downto 0);

signal rgb1				: std_logic_vector(2 downto 0):="000";
signal rgb2				: std_logic_vector(2 downto 0):="000";
signal rgb3				: std_logic_vector(2 downto 0):="000";
signal rgb4				: std_logic_vector(2 downto 0):="000";
signal rgb5				: std_logic_vector(2 downto 0):="000";

signal kw, ks, ka, kd	: std_logic;
signal kenter			: std_logic;
signal kspace			: std_logic;
signal ky, kn			: std_logic;
signal kesc				: std_logic;

signal data_box			: std_logic_vector(7 downto 0);

signal cnt_mines		: std_logic_vector(6 downto 0);

signal show_disp		: array8x8;
signal show_dispz		: std_logic_vector(63 downto 0);

signal win, lose, game	: std_logic; 
signal cntg				: std_logic;

signal cnt_flash		: std_logic_vector(23 downto 0);

begin 
---------------- SUMMARY RGB ON DISPLAY ----------------
rgb <= rgb1 or rgb2 or rgb3 or rgb4 or rgb5;
---------------- KEYBOARD ----------------	
kw 	<= push_keys.WSAD(3) after 1 ns when rising_edge(clk);
ks 	<= push_keys.WSAD(2) after 1 ns when rising_edge(clk);
ka 	<= push_keys.WSAD(0) after 1 ns when rising_edge(clk);
kd 	<= push_keys.WSAD(1) after 1 ns when rising_edge(clk);
ky 	<= push_keys.ky after 1 ns when rising_edge(clk);
kn 	<= push_keys.kn after 1 ns when rising_edge(clk);
kspace 	<= push_keys.Space after 1 ns when rising_edge(clk);
kenter 	<= push_keys.Enter after 1 ns when rising_edge(clk);
kesc 	<= push_keys.Esc after 1 ns when rising_edge(clk);
---------------- LEDS ON DISPLAY ----------------
leds(1) <= kenter;
leds(2) <= kw or ks or ka or kd;
leds(3) <= ky or kn;
leds(4) <= show_field; 
leds(5) <= display;
leds(6) <= cnt_flash(23); 
---------------- MOVING COUNTERS ----------------
pr_start: process(reset, clk) is
begin
	if reset = '0' then
		cnt_xx <= "000";
		cnt_yy <= "000";
	elsif rising_edge(clk) then	
		case game_status is
			when PLAY =>
				if kw = '1' then
					cnt_yy <= cnt_yy - 1;
				elsif ks = '1' then
					cnt_yy <= cnt_yy + 1;
				else
					null;
				end if;
				if ka = '1' then
					cnt_xx <= cnt_xx + 1;
				elsif kd = '1' then
					cnt_xx <= cnt_xx - 1;
				else
					null;
				end if;	
			when RST | GAME_OVER | WAIT_START =>
				cnt_xx <= "000";
				cnt_yy <= "000";
			when others =>
				null; 
		end case;		
	end if;
end process;		
comp_yy <= "0000" & cnt_yy;	
comp_xx <= "00" & cnt_xx;	
---------------- XoY COORDINATES ----------------
x_in <= x_char(9 downto 3);
y_in <= y_char(8 downto 4);		

x_inz <= x_in after 1 ns when rising_edge(clk);
y_inz <= y_in after 1 ns when rising_edge(clk);
x_inzz <= x_inz after 1 ns when rising_edge(clk);
y_inzz <= y_inz after 1 ns when rising_edge(clk);
---------------- GLOABAL FSM ----------------
pr_game_status: process(clk, reset) is
begin
	if reset = '0' then
		game_status 	<= WAIT_START;
		show_field 		<= '0';
		show_bad_msg	<= '0';
		addr_rnd 		<= (others => '0');	
		display_text	<= '0';
		win				<= '0';
		lose			<= '0';
		game 			<= '0';
		cntg			<= '0';
		cnt_flash		<= (others => '0');
	elsif rising_edge(clk) then
		case game_status is
			when WAIT_START =>
				display_text	<= '1';
				show_bad_msg 	<= '0';
				win		<= '0';
				game 	<= '0';
				lose	<= '0';
				cntg	<= '0';
				addr_rnd <= addr_rnd + '1'; -- UNCOMMENT LATER!!
				if kspace = '1' then
					game_status <= PLAY;
					show_field 		<= '1';
				end if;
			when PLAY =>
				cntg <= '1';
				if kesc = '1' then
					game_status <= WAIT_START;
				else
					if cnt_mines = "111000" then
						show_bad_msg <= '0';
						game_status <= GAME_OVER;
					else
						if kenter = '1' then
							game_status <= CHECK;
						else
							null;
						end if;
					end if;
				end if;
			when CHECK =>
				if (x_inzz = (xstart + comp_xx)) and (y_inzz = (ystart + comp_yy)) then
					if data_box = x"0F" then
						show_bad_msg <= '1';
						game_status <= GAME_OVER; 
					else
						game_status <= PLAY;
					end if;
				end if;	
			when GAME_OVER =>
				cnt_flash <= cnt_flash + '1';
				if show_bad_msg = '1' then
					win <= '0';
					lose <= '1';
				else
					win <= '1';
					lose <= '0';
				end if;
				game <= '1';
				if ky = '1' then
					game_status <= WAIT_START;
				elsif kn = '1' then
					game_status <= RST;
				else 
					null;					
				end if;	
			when RST =>
				cntg 			<= '0';
				game 			<= '0';
				win				<= '0';
				lose			<= '0';
				show_field 		<= '0';
				display_text 	<= '0';
				show_bad_msg	<= '0';	
				cnt_flash 		<= (others => '0');
				addr_rnd 		<= (others => '0');	
			when others => null;
		end case;
	end if;	  
end process;  

pr_display8x8: process(clk, reset) is
begin
	if reset = '0' then
		show_disp 	<= (others=>(others=>'0'));
		cnt_mines	<= (others => '0');	
		show_dispz	<= (others => '0');
	elsif rising_edge(clk) then
		case game_status is
			when PLAY =>
				if kenter = '1' then
					show_disp(conv_integer(cnt_xx))(conv_integer(cnt_yy)) <= '1';
				else
					null;
				end if;
--				x_loop: for ii in 0 to 62 loop
--					show_dispz(ii+1) <= show_dispz(ii);
--				end loop;
--				show_dispz(0) <= '0';
				show_dispz(63 downto 0) <= show_dispz(62 downto 0) & '0';
				if show_dispz(63) = '1' then
					cnt_mines <= cnt_mines + '1';
				else
					null;
				end if;				
			when CHECK =>	
				show_dispz <= conv8x8to64(show_disp);
				cnt_mines <= (others => '0');
			when RST | GAME_OVER | WAIT_START =>
				show_dispz <= (others => '0');
				show_disp <= (others=>(others=>'0'));
				cnt_mines <= (others => '0');
			when others =>
				null; 
		end case;
	end if;
end process;  
---------------- COMPONENTS MAPPING ----------------
x_check: cl_check
	generic map(
		yend		=>	yend,
		ystart		=>	ystart,
		xend		=>	xend,
		xstart		=>	xstart
		)
	port map(
		clk			=> clk,
		reset		=> reset,
		cnt_yy		=> cnt_yy,
		cnt_xx		=> cnt_xx,		
		display		=> show_field,
		x_char		=> x_char,
		y_char		=> y_char,
		rgb			=> rgb1
	);

x_mines: cl_mines
	generic map(
		yend		=>	yend,
		ystart		=>	ystart,
		xend		=>	xend,
		xstart		=>	xstart
		)
	port map(
		clk			=> clk,
		reset		=> reset,
		addr_rnd	=> addr_rnd,
		show_disp	=> show_disp,
		display		=> show_field,
		x_char		=> x_char,
		y_char		=> y_char,
		data_out	=> data_box,
		rgb			=> rgb2
	);

x_square: cl_square
	generic map(
		yend		=>	yend,
		ystart		=>	ystart,
		xend		=>	xend,
		xstart		=>	xstart
		)
	port map(
		clk			=> clk,
		reset		=> reset,
		show_disp	=> show_disp,
		display		=> show_field,
		x_char		=> x_char,
		y_char		=> y_char,
		rgb			=> rgb3
	);

x_borders: cl_borders
	generic map(
		yend		=>	yend,
		ystart		=>	ystart,
		xend		=>	xend,
		xstart		=>	xstart
		)
	port map(
		clk			=> clk,
		reset		=> reset,
		display		=> show_field,
		x_char		=> x_char,
		y_char		=> y_char,
		rgb			=> rgb4
	);	
	
x_text: cl_text
	generic map(
		yend		=>	yend,
		ystart		=>	ystart,
		xend		=>	xend,
		xstart		=>	xstart
		)
	port map(
		clk			=> clk,
		reset		=> reset,
		addr_rnd	=> addr_rnd,		
		display		=> display_text,
		cntgames	=> cntg,
		win			=> win,
		lose		=> lose,
		game		=> game,
		flash		=> cnt_flash(23 downto 21),
		x_char		=> x_char,
		y_char		=> y_char,
		rgb			=> rgb5
	);	  
	
end ctrl_game_block;