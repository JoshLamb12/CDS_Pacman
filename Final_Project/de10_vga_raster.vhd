-------------------------------------------------------------------------------
--
-- Author: D. M. Calhoun
-- Description: VGA raster controller for DE10-Standard with integrated sprite
-- 				 selector and Avalon memory-mapped IO
-- Adapted from DE2 controller written by Stephen A. Edwards
--
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity de10_vga_raster is
  
  port (
    reset : in std_logic;
    clk   : in std_logic;                    -- Should be 50.0MHz

	-- Read from memory to access position
	read			:	in std_logic;
	write		: 	in std_logic;
	chipselect	:	in std_logic;
	address		: 	in std_logic_vector(3 downto 0);
	readdata	:	out std_logic_vector(15 downto 0);
	writedata	:	in std_logic_vector(15 downto 0);
	
	-- VGA connectivity
    VGA_CLK,                         -- Clock
    VGA_HS,                          -- H_SYNC, horizontal
    VGA_VS,                          -- V_SYNC, vertical
    VGA_BLANK,                       -- BLANK
    VGA_SYNC : out std_logic := '0';        -- SYNC
    VGA_R,                           -- Red[7:0]
    VGA_G,                           -- Green[7:0]
    VGA_B : out std_logic_vector(7 downto 0) -- Blue[7:0]
    );

end de10_vga_raster;

architecture rtl of de10_vga_raster is
	
	component red1_vga8_25x25 is
	port (
		clk, en : in std_logic;
		addr : in unsigned(9 downto 0);
		data : out unsigned(27 downto 0));
	end component;
	
	component red2_vga8_25x25 is
	port (
		clk, en : in std_logic;
		addr : in unsigned(9 downto 0);
		data : out unsigned(27 downto 0));
	end component;
	
	component cyan1_vga8_25x25 is
	port (
		clk, en : in std_logic;
		addr : in unsigned(9 downto 0);
		data : out unsigned(27 downto 0));
	end component;
	
	component cyan2_vga8_25x25 is
	port (
		clk, en : in std_logic;
		addr : in unsigned(9 downto 0);
		data : out unsigned(27 downto 0));
	end component;

	component orange1_vga8_25x25 is
	port (
		clk, en : in std_logic;
		addr : in unsigned(9 downto 0);
		data : out unsigned(27 downto 0));
	end component;
	
	component orange2_vga8_25x25 is
	port (
		clk, en : in std_logic;
		addr : in unsigned(9 downto 0);
		data : out unsigned(27 downto 0));
	end component;
	
	component pink1_vga8_25x25 is
	port (
		clk, en : in std_logic;
		addr : in unsigned(9 downto 0);
		data : out unsigned(27 downto 0));
	end component;
	
	component pink2_vga8_25x25 is
	port (
		clk, en : in std_logic;
		addr : in unsigned(9 downto 0);
		data : out unsigned(27 downto 0));
	end component;
	
	component scared1_vga8_25x25 is
	port (
		clk, en : in std_logic;
		addr : in unsigned(9 downto 0);
		data : out unsigned(27 downto 0));
	end component;
	
	component scared2_vga8_25x25 is
	port (
		clk, en : in std_logic;
		addr : in unsigned(9 downto 0);
		data : out unsigned(27 downto 0));
	end component;
	
	component pacmanopen_vga8_25x25 is
	port (
		clk, en : in std_logic;
		addr : in unsigned(9 downto 0);
		data : out unsigned(27 downto 0));
	end component;
	
	component pacmanclosed_vga8_25x25 is
	port (
		clk, en : in std_logic;
		addr : in unsigned(9 downto 0);
		data : out unsigned(27 downto 0));
	end component;
	
	
	component map_vga8_435x435 is
	port (
		clk, en : in std_logic;
		addr : in unsigned(17 downto 0);
		data : out unsigned(27 downto 0));
	end component;
	
	-- Video parameters

	constant HTOTAL       : integer := 800;
	constant HSYNC        : integer := 96;
	constant HBACK_PORCH  : integer := 48;
	constant HACTIVE      : integer := 640;
	constant HFRONT_PORCH : integer := 16;

	constant VTOTAL       : integer := 525;
	constant VSYNC        : integer := 2;
	constant VBACK_PORCH  : integer := 33;
	constant VACTIVE      : integer := 480;
	constant VFRONT_PORCH : integer := 10;

	-- Signals for the video controller
	signal Hcount : unsigned(9 downto 0);-- := 200;  -- Horizontal position (0-800)
	signal Vcount : unsigned(9 downto 0);-- := 200;  -- Vertical position (0-524)
	signal EndOfLine, EndOfField : std_logic;

	signal vga_hblank, vga_hsync, vga_vblank, vga_vsync : std_logic := '0';  -- Sync. signals

	--signal rectangle_h, rectangle_v, rectangle : std_logic;  -- rectangle area
	signal sprite_x, sprite_y : unsigned (9 downto 0) := "0011110000"; -- 240

	signal sprite_addr_cnt : unsigned(9 downto 0) := (others => '0');
	--signal x_addr, y_addr : unsigned (9 downto 0) := (others => '0');
	signal area_x, area_y, spr_area, spr_load : std_logic := '0'; -- flags to control whether or not it's time to display our sprite
	signal show_map : std_logic;
	-- Sprite data interface
	signal spr_address : unsigned (9 downto 0) := (others => '0');
	signal map_sprite_address : unsigned (17 downto 0) := (others => '0');
	signal which_spr : unsigned(15 downto 0) := "0000000000000001";
	--signal spr_select : std_logic_vector(3 downto 0) := "0000";
	signal spr_data : unsigned(27 downto 0) := (others => '0');
	--signal sprite0_data, sprite1_data, sprite2_data, sprite3_data, sprite4_data, sprite5_data, sprite6_data, sprite7_data, sprite8_data,
	--		 sprite9_data, sprite10_data, sprite11_data, sprite12_data, sprite13_data: unsigned(27 downto 0) := (others => '0');
	signal red1_data, red2_data, orange1_data, orange2_data, cyan1_data, cyan2_data, pink1_data, pink2_data, scared1_data, scared2_data, pacmanopen_data, 
			pacmanclosed_data : unsigned(27 downto 0) := (others => '0');
	signal map_sprite_data : unsigned(27 downto 0);--:= (others => '0');
	constant sprlen_x, sprlen_y : integer := 25; -- length and width of sprite(s)
	constant maplen_x, maplen_y : integer := 435; --length x width of map overlay sprite
	signal mult_result : unsigned (19 downto 0) := (others => '0');
	------------------------------------------------------------------------------------------------------------------------
	signal red1_disp, cyan1_disp, orange1_disp, pink1_disp, scared1_disp, pacmanopen_disp : std_logic :='0'; --use to show sprites on video out
	------------------------------------------------------------------------------------------------------------------------
	
	--signal RGB, RGB_G, RGB_B, RGB_r, RGB_G_r, RGB_B_r, RGB_bg, RGB_G_bg, RGB_B_bg : std_logic_vector (9 downto 0);
	--signal  background_x, background_y : integer;--background;

	-- need to clock at about 25 MHz for NTSC VGA
	signal clk_25 : std_logic := '0';
begin
	
	-- Instantiate connections to various sprite memories
--	green_ball_inst : grebal_vga8_20x20 port map(
--		clk => clk_25,
--		en => spr_area,
--		addr => spr_address,
--		data => sprite0_data
--	);

	mapoverlay_inst: map_vga8_435x435 port map(
		clk => clk_25,
		en => show_map,
		addr => map_sprite_address,
		data => map_sprite_data
	
	);
	
	redghost1_inst: red1_vga8_25x25 port map(
		clk => clk_25,
		en => spr_area,
		addr => spr_address,
		data => red1_data
	
	);
	
	redghost2_inst: red2_vga8_25x25 port map(
		clk => clk_25,
		en => spr_area,
		addr => spr_address,
		data => red2_data
	
	);
	
	cyan1_inst: cyan1_vga8_25x25 port map(
		clk => clk_25,
		en => spr_area,
		addr => spr_address,
		data => cyan1_data
	
	);
	

	cyan2_inst: cyan2_vga8_25x25 port map(
		clk => clk_25,
		en => spr_area,
		addr => spr_address,
		data => cyan2_data
	);

	orange1_inst: orange1_vga8_25x25 port map(
		clk => clk_25,
		en => spr_area,
		addr => spr_address,
		data => orange1_data
	);
	
	orange2_inst: orange2_vga8_25x25 port map(
		clk => clk_25,
		en => spr_area,
		addr => spr_address,
		data => orange2_data
	);
	
	pink1_inst: pink1_vga8_25x25 port map(
		clk => clk_25,
		en => spr_area,
		addr => spr_address,
		data => pink1_data
	);
	
	pink2_inst: pink2_vga8_25x25 port map(
		clk => clk_25,
		en => spr_area,
		addr => spr_address,
		data => pink2_data
	);
	
	scared1_inst: scared1_vga8_25x25 port map(
		clk => clk_25,
		en => spr_area,
		addr => spr_address,
		data => scared1_data
	);
	
	scared2_inst: scared2_vga8_25x25 port map(
		clk => clk_25,
		en => spr_area,
		addr => spr_address,
		data => scared2_data
	);
	
	pacman_open_inst: pacmanopen_vga8_25x25 port map(
		clk => clk_25,
		en => spr_area,
		addr => spr_address,
		data => pacmanopen_data
	);
	
	pacman_closed_inst: pacmanclosed_vga8_25x25 port map(
		clk => clk_25,
		en => spr_area,
		addr => spr_address,
		data => pacmanclosed_data
	);

	
	
	-- set up 25 MHz clock
	process (clk)
	begin
		if rising_edge(clk) then
			clk_25 <= not clk_25;
		end if;
	end process;
	
	-- Write current location of sprite center
	Location_Write : process (clk_25)
	--variable sprite_y, sprite_x : unsigned(9 downto 0);
	begin
	
		if rising_edge(clk_25) then
			if reset = '1' then
				readdata <= (others => '0');
				sprite_y <= "0011110000"; -- 240
				sprite_x <= "1000011100"; --540
			
			elsif chipselect = '1' then
				if read = '1' then
					if address= "0000" then
						readdata <=  "000000000000000" & (vga_vsync or vga_hsync);
					elsif address= "0001" then
						readdata <=  "000000" & std_logic_vector(sprite_y);
					elsif address = "0010" then
						readdata <=  "000000" & std_logic_vector(sprite_x);
					else 
						readdata <= "0000000000001010";
					end if;
				end if;
				if write = '1' then
					if address = "0011" then
						sprite_y <= unsigned(writedata(9 downto 0)); --y
						sprite_x <= sprite_x;
						which_spr <= which_spr;
					elsif address = "0100" then	
						sprite_y <= sprite_y;
						sprite_x <= unsigned(writedata(9 downto 0)); --x
						which_spr <= which_spr;
					elsif address = "0101" then
						sprite_y <= sprite_y;
						sprite_x <= sprite_x;
						which_spr <= (unsigned(writedata(15 downto 0)));
					else 
						sprite_y <= sprite_y;
						sprite_x <= sprite_x;
						which_spr <= which_spr;
					end if;
				end if;
			end if;
		end if;
	end process Location_Write;

	-- Horizontal and vertical counters

	HCounter : process (clk_25)
	begin
		if rising_edge(clk_25) then      
			if reset = '1' then
			  Hcount <= (others => '0');
			elsif EndOfLine = '1' then
			  Hcount <= (others => '0');
			else
			  Hcount <= Hcount + 1;
			end if;      
		end if;
	end process HCounter;

	EndOfLine <= '1' when Hcount = HTOTAL - 1 else '0';
	  
	VCounter: process (clk_25)
	begin
		if rising_edge(clk_25) then      
			if reset = '1' then
			  Vcount <= (others => '0');
			elsif EndOfLine = '1' then
			  if EndOfField = '1' then
				 Vcount <= (others => '0');
			  else
				 Vcount <= Vcount + 1;
			  end if;
			end if;
		end if;
	end process VCounter;

	EndOfField <= '1' when Vcount = VTOTAL - 1 else '0';

	-- State machines to generate HSYNC, VSYNC, HBLANK, and VBLANK
	HSyncGen : process (clk_25)
	begin
		if rising_edge(clk_25) then     
			if reset = '1' or EndOfLine = '1' then
			  vga_hsync <= '1';
			elsif Hcount = HSYNC - 1 then
			  vga_hsync <= '0';
			end if;
		end if;
	end process HSyncGen;
	  
	HBlankGen : process (clk_25)
	begin
		if rising_edge(clk_25) then
			if reset = '1' then
				vga_hblank <= '1';
			elsif Hcount = HSYNC + HBACK_PORCH then
				vga_hblank <= '0';
			elsif Hcount = HSYNC + HBACK_PORCH + HACTIVE then
				vga_hblank <= '1';
			end if;      
		end if;
	end process HBlankGen;

	VSyncGen : process (clk_25)
	begin
		if rising_edge(clk_25) then
			if reset = '1' then
				vga_vsync <= '1';
			elsif EndOfLine ='1' then
				if EndOfField = '1' then
					vga_vsync <= '1';
				elsif Vcount = VSYNC - 1 then
					vga_vsync <= '0';
				end if;
			end if;      
		end if;
	end process VSyncGen;

	VBlankGen : process (clk_25)
	begin
		if rising_edge(clk_25) then    
			if reset = '1' then
				vga_vblank <= '1';
			elsif EndOfLine = '1' then
				if Vcount = VSYNC + VBACK_PORCH - 1 then
					vga_vblank <= '0';
				elsif Vcount = VSYNC + VBACK_PORCH + VACTIVE - 1 then
					vga_vblank <= '1';
				end if;
			end if;
		end if;
	end process VBlankGen;
	
	-- background generator
	-- background_x <= to_integer(Hcount - HSYNC - HBACK_PORCH - 1);
	-- background_y <= to_integer(Vcount - VSYNC - VBACK_PORCH);

	-- Sprite generator
	Sprite_X_Check : process(clk_25)
	begin
		if rising_edge(clk_25) then
			if reset = '1' or (Hcount >= (sprite_x) and Hcount < (sprite_x + sprlen_x)) then
				area_x <= '1';
			else
				area_x <= '0';
			end if;
		
		end if;
	end process Sprite_X_Check;
	
	Sprite_Y_Check : process(clk_25)
	begin
		if rising_edge(clk_25) then
			if reset = '1' then
				area_y <= '0'; -- changed from '1'
			elsif EndOfLine = '1' then
				if Vcount >= (sprite_y) and Vcount < (sprite_y + sprlen_y) then
					area_y <= '1';
				else
					area_y <= '0';
				end if;
				
			end if;
		
		end if;
	end process Sprite_Y_Check;

	spr_area <= area_x and area_y;
	
	Sprite_Load_Process : process (clk_25)
	begin
		if reset = '1' then
			spr_load <= '0';
		else
			if rising_edge(clk_25) then
				if spr_area = '1' then
					spr_load <= '1';
				else
					spr_load <= '0';
				end if;
			end if;
		end if;
	end process Sprite_Load_Process;
	
	mult_result <= (Vcount-sprite_y-1)*sprlen_y+(Hcount-sprite_x-1); -- minus 1 in horiz and vert deals with off-by-one behavior in valid area check; not sim as of 2/23 2AM
	spr_address <= mult_result(9 downto 0);
	show_map <= '1';
	map_sprite_address <= "101110001100101000"; --point to where sprite address
	
	
	-- comb logic to select sprite ROM data
	with which_spr(3 downto 0) select
		spr_data <= red1_data when "0001",
					red2_data when "0010",
					cyan1_data when "0011",
					cyan2_data when "0100",
					orange1_data when "0101",
					orange2_data when "0110",
					pink1_data when "0111",
					pink2_data when "1000",
					scared1_data when "1001",
					scared2_data when "1010",
					pacmanopen_data when "1011",
					pacmanclosed_data when "1100",
					--spritex_data when "1101",
					--spritex_data when "1110",
					(others => '0') when others;

	-- Registered video signals going to the video DAC
	VideoOut : process (clk_25, reset)
	-----------------------------------------------------------
--		variable sprite_array_V       : unsigned (9 downto 0);
--		variable sprite_array_H       : unsigned (9 downto 0);
--		variable sprite_0_row         : unsigned (15 downto 0);
--		variable sprite_1_row         : unsigned (15 downto 0);
--		variable sprite_2_row         : unsigned (15 downto 0);
--		variable sprite_3_row         : unsigned (15 downto 0);
--		variable sprite_4_row         : unsigned (15 downto 0);
--		variable sprite_5_row         : unsigned (15 downto 0);
--		variable sprite_6_row         : unsigned (15 downto 0);
--		variable sprite_7_row         : unsigned (15 downto 0);
--		variable sprite_8_row         : unsigned (15 downto 0);
--		variable sprite_9_row         : unsigned (15 downto 0);
	-----------------------------------------------------------	
		-- sprite_array_V  := (Vcount - (VSYNC + VBACK_PORCH)) and "0000001111";
		-- sprite_array_H  := (Hcount - (HSYNC + HBACK_PORCH)) and "0000001111";
	begin
		if reset = '1' then
				VGA_R <= "00000000";
				VGA_G <= "00000000";
				VGA_B <= "00000000";  
		elsif clk_25'event and clk_25 = '1' then --when rising edge of the 25MHz clock
			if spr_load = '1' and spr_data(24) = '0' then
				VGA_R <= std_logic_vector(spr_data(23 downto 16));
				VGA_G <= std_logic_vector(spr_data(15 downto 8));
				VGA_B <= std_logic_vector(spr_data(7 downto 0));
			elsif vga_hblank = '0' and vga_vblank = '0' then
				VGA_R <= std_logic_vector(map_sprite_data(23 downto 16));
				VGA_G <= std_logic_vector(map_sprite_data(15 downto 8));
				VGA_B <= std_logic_vector(map_sprite_data(7 downto 0));
			else --default to showing the map data
				VGA_R <= "00000000";
				VGA_G <= "00000000";
				VGA_B <= "00000000";    
			end if;
	end if; 
	end process VideoOut;


	VGA_CLK <= clk_25;
	VGA_HS <= not vga_hsync;
	VGA_VS <= not vga_vsync;
	VGA_SYNC <= '0';
	VGA_BLANK <= not (vga_hsync or vga_vsync);


end rtl;
