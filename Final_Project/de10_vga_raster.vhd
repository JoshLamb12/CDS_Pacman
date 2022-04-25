-------------------------------------------------------------------------------
--
-- Author: D. M. Calhoun
-- Description: VGA raster controller for DE10-Standard with integrated sprite
-- selector and Avalon memory-mapped IO
-- Adapted from DE2 controller written by Stephen A. Edwards
--Note: revised by CDS team 8 as of 4/15/22
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
entity de10_vga_raster is
	port
	(
		reset       : in std_logic;
		clk         : in std_logic; -- Should be 50.0MHz
		-- Read from memory to access position
		read        : in std_logic;
		write       : in std_logic;
		chipselect  : in std_logic;
		address     : in std_logic_vector(4 downto 0);
		readdata    : out std_logic_vector(15 downto 0);
		writedata   : in std_logic_vector(15 downto 0);
		-- VGA connectivity
		VGA_CLK, -- Clock
		VGA_HS, -- H_SYNC, horizontal
		VGA_VS, -- V_SYNC, vertical
		VGA_BLANK, -- BLANK
		VGA_SYNC    : out std_logic := '0'; -- SYNC
		VGA_R, -- Red[7:0]
		VGA_G, -- Green[7:0]
		VGA_B       : out std_logic_vector(7 downto 0) -- Blue[7:0]
	);
end de10_vga_raster;
architecture rtl of de10_vga_raster is
	component red1_vga8_25x25 is
		port
		(
			clk, en  : in std_logic;
			addr     : in unsigned(9 downto 0);
			data     : out unsigned(27 downto 0)
		);
	end component;
	component red2_vga8_25x25 is
		port
		(
			clk, en  : in std_logic;
			addr     : in unsigned(9 downto 0);
			data     : out unsigned(27 downto 0)
		);
	end component;
	component cyan1_vga8_25x25 is
		port
		(
			clk, en  : in std_logic;
			addr     : in unsigned(9 downto 0);
			data     : out unsigned(27 downto 0)
		);
	end component;
	component cyan2_vga8_25x25 is
		port
		(
			clk, en  : in std_logic;
			addr     : in unsigned(9 downto 0);
			data     : out unsigned(27 downto 0)
		);
	end component;
	component orange1_vga8_25x25 is
		port
		(
			clk, en  : in std_logic;
			addr     : in unsigned(9 downto 0);
			data     : out unsigned(27 downto 0)
		);
	end component;
	component orange2_vga8_25x25 is
		port
		(
			clk, en  : in std_logic;
			addr     : in unsigned(9 downto 0);
			data     : out unsigned(27 downto 0)
		);
	end component;
	component pink1_vga8_25x25 is
		port
		(
			clk, en  : in std_logic;
			addr     : in unsigned(9 downto 0);
			data     : out unsigned(27 downto 0)
		);
	end component;
	component pink2_vga8_25x25 is
		port
		(
			clk, en  : in std_logic;
			addr     : in unsigned(9 downto 0);
			data     : out unsigned(27 downto 0)
		);
	end component;
	component scared1_vga8_25x25 is
		port
		(
			clk, en  : in std_logic;
			addr     : in unsigned(9 downto 0);
			data     : out unsigned(27 downto 0)
		);
	end component;
	component scared2_vga8_25x25 is
		port
		(
			clk, en  : in std_logic;
			addr     : in unsigned(9 downto 0);
			data     : out unsigned(27 downto 0)
		);
	end component;
	component pacmanopen_vga8_25x25 is
		port
		(
			clk, en  : in std_logic;
			addr     : in unsigned(9 downto 0);
			data     : out unsigned(27 downto 0)
		);
	end component;
	component pacmanclosed_vga8_25x25 is
		port
		(
			clk, en  : in std_logic;
			addr     : in unsigned(9 downto 0);
			data     : out unsigned(27 downto 0)
		);
	end component;
	component pac_up_vga8_25x25 is
		port
		(
			clk, en  : in std_logic;
			addr     : in unsigned(9 downto 0);
			data     : out unsigned(27 downto 0)
		);
	end component;
	component pac_down_vga8_25x25 is
		port
		(
			clk, en  : in std_logic;
			addr     : in unsigned(9 downto 0);
			data     : out unsigned(27 downto 0)
		);
	end component;
	component pac_left_vga8_25x25 is
		port
		(
			clk, en  : in std_logic;
			addr     : in unsigned(9 downto 0);
			data     : out unsigned(27 downto 0)
		);
	end component;

	component map_vga8_640x480 is
		port
		(
			clk, en  : in std_logic;
			addr     : in unsigned(18 downto 0);
			data     : out unsigned(27 downto 0)
		);
	end component;
	
	-- Video parameters
	constant HTOTAL : integer := 800;
	constant HSYNC : integer := 96;
	constant HBACK_PORCH : integer := 48;
	constant HACTIVE : integer := 640; --horizontal active space
	constant HFRONT_PORCH : integer := 16;
	constant VTOTAL : integer := 525;
	constant VSYNC : integer := 2;
	constant VBACK_PORCH : integer := 33;
	constant VACTIVE : integer := 480; --vertical active space
	constant VFRONT_PORCH : integer := 10;
	
	-- Signals for the video controller
	signal Hcount : unsigned(9 downto 0); -- Horizontal position (0-800)
	signal Vcount : unsigned(9 downto 0); -- Vertical position (0-524)
	signal EndOfLine, EndOfField : std_logic;
	signal vga_hblank, vga_hsync, vga_vblank, vga_vsync : std_logic := '0'; -- Sync. signals
	
	signal sprite_x, sprite_y : unsigned (9 downto 0) := "0011110000"; -- 240
	signal red_ghost_sprite_x, red_ghost_sprite_y : unsigned (9 downto 0) := "0011110000";
	signal cyan_ghost_sprite_x, cyan_ghost_sprite_y : unsigned (9 downto 0) := "0011110000";
	signal orange_ghost_sprite_x, orange_ghost_sprite_y : unsigned (9 downto 0) := "0011110000";
	signal pink_ghost_sprite_x, pink_ghost_sprite_y : unsigned (9 downto 0) := "0011110000";
	signal scared_ghost_sprite_x, scared_ghost_sprite_y : unsigned (9 downto 0) := "0011110000";
	signal pacman_sprite_x, pacman_sprite_y : unsigned (9 downto 0) := "0011110000";

	signal map_sprite_x : unsigned (9 downto 0) := "0011110000";--"1010000000";
	signal map_sprite_y : unsigned (9 downto 0) := "0011110000";--"0111100000";

	signal area_x, area_y, spr_area, spr_load : std_logic := '0'; -- flags to control whether or not it's time to display our sprite
	signal red_area, cyan_area, orange_area, pink_area, pacman_area, scared_area, map_area : std_logic := '0'; --sprite area checks
	signal red_x, red_y, cyan_x, cyan_y, orange_x, orange_y, pink_x, pink_y, pacman_x, pacman_y, scared_x, scared_y : std_logic := '0'; --25x25 sprite (x,y) checks
	signal map_x, map_y : std_logic := '0'; --map (x,y) checks
	signal red_load, cyan_load, orange_load, pink_load, pacman_load, scared_load : std_logic := '0'; --load sprite signal, use to show sprites on video out
	signal show_map : std_logic := '1'; --load map signal
	
	-- Sprite data interface
	signal spr_address, red_address, cyan_address, orange_address, pink_address, pacman_address, scared_address : unsigned (9 downto 0) := (others => '0');
	signal map_sprite_address : unsigned (18 downto 0) := (others => '0');
	signal which_spr : unsigned(15 downto 0) := "0000000000000001";
	signal which_red_spr, which_cyan_spr, which_orange_spr, which_pink_spr, which_pacman_spr, which_scared_spr : unsigned(15 downto 0) := "0000000000000001";
	
	
	signal red1_data, red2_data, orange1_data, orange2_data, cyan1_data, cyan2_data, pink1_data, pink2_data, scared1_data, scared2_data, pacmanopen_data, 
			 pacman_left_data, pacman_up_data, pacman_down_data, pacmanclosed_data, spr_data_cyan, spr_data_red, spr_data_orange, spr_data_pink, 
			 spr_data_pacman : unsigned(27 downto 0) := (others => '0'); --sprite RGB data (28 bits)		 
	signal map_sprite_data : unsigned(27 downto 0) := (others => '0'); --map RGB data (28 bits)
	
	constant sprlen_x, sprlen_y : integer := 25; -- length and width of sprite(s)
	constant maplen_x : integer := 640; --length x width of map overlay sprite
	constant maplen_y : integer := 480; --y length of map overlay
	
	signal mult_result, red_result, cyan_result, orange_result, pink_result, pacman_result, scared_result, map_result : unsigned (19 downto 0) := (others => '0');
	
	-- need to clock at about 25 MHz for NTSC VGA
	signal clk_25 : std_logic := '0';
begin
	-- Instantiate connections to various sprite memories
	mapoverlay_inst : map_vga8_640x480
	port map
	(
		clk   => clk_25,
		en    => show_map,
		addr  => map_sprite_address,
		data  => map_sprite_data
	);
	redghost1_inst : red1_vga8_25x25
	port map
	(
		clk   => clk_25,
		en    => red_area,
		addr  => red_address,
		data  => red1_data
	);
	redghost2_inst : red2_vga8_25x25
	port map
	(
		clk   => clk_25,
		en    => red_area,
		addr  => red_address,
		data  => red2_data
	);
	cyan1_inst : cyan1_vga8_25x25
	port map
	(
		clk   => clk_25,
		en    => cyan_area,
		addr  => cyan_address,
		data  => cyan1_data
	);

	cyan2_inst : cyan2_vga8_25x25
	port map
	(
		clk   => clk_25,
		en    => cyan_area,
		addr  => cyan_address,
		data  => cyan2_data
	);
	orange1_inst : orange1_vga8_25x25
	port map
	(
		clk   => clk_25,
		en    => orange_area,
		addr  => orange_address,
		data  => orange1_data
	);
	orange2_inst : orange2_vga8_25x25
	port map
	(
		clk   => clk_25,
		en    => orange_area,
		addr  => orange_address,
		data  => orange2_data
	);
	pink1_inst : pink1_vga8_25x25
	port map
	(
		clk   => clk_25,
		en    => pink_area,
		addr  => pink_address,
		data  => pink1_data
	);
	pink2_inst : pink2_vga8_25x25
	port map
	(
		clk   => clk_25,
		en    => pink_area,
		addr  => pink_address,
		data  => pink2_data
	);
	scared1_inst : scared1_vga8_25x25
	port map
	(
		clk   => clk_25,
		en    => scared_area,
		addr  => scared_address,
		data  => scared1_data
	);
	scared2_inst : scared2_vga8_25x25
	port map
	(
		clk   => clk_25,
		en    => scared_area,
		addr  => scared_address,
		data  => scared2_data
	);
	pacman_open_inst : pacmanopen_vga8_25x25
	port map
	(
		clk   => clk_25,
		en    => pacman_area,
		addr  => pacman_address,
		data  => pacmanopen_data
	);
	pacman_closed_inst : pacmanclosed_vga8_25x25
	port map
	(
		clk   => clk_25,
		en    => pacman_area,
		addr  => pacman_address,
		data  => pacmanclosed_data
	);
	pacman_up_inst : pac_up_vga8_25x25
	port map
	(
		clk   => clk_25,
		en    => pacman_area,
		addr  => pacman_address,
		data  => pacman_up_data
	);
	pacman_left_inst : pac_left_vga8_25x25
	port map
	(
		clk   => clk_25,
		en    => pacman_area,
		addr  => pacman_address,
		data  => pacman_left_data
	);

	pacman_down_inst : pac_down_vga8_25x25
	port map
	(
		clk   => clk_25,
		en    => pacman_area,
		addr  => pacman_address,
		data  => pacman_down_data
	);
	----------------------------------------------------------------------------------
	-- set up 25 MHz clock
	process (clk)
	begin
		if rising_edge(clk) then
			clk_25 <= not clk_25;
		end if;
	end process;
	--variable sprite_y, sprite_x : unsigned(9 downto 0);
	-- Write current location of sprite center
	Location_Write : process (clk_25)
	begin
		if rising_edge(clk_25) then
			if reset = '1' then
				readdata <= (others => '0');
				-- sprite_y <= "0011110000"; -- 240
				-- sprite_x <= "1000011100"; --540
				red_ghost_sprite_x <= "0011110000";
				red_ghost_sprite_y <= "1000011100";
				cyan_ghost_sprite_x <= "0011110000";
				cyan_ghost_sprite_y <= "1000011100";
				map_sprite_x <= "0011110000";--"0011110000";
				map_sprite_y <= "1000011100";--"1000011100";
			elsif chipselect = '1' then
				if read = '1' then
					if address = "00000" then
						readdata <= "000000000000000" & (vga_vsync or vga_hsync);
						--red ghost
					elsif address = "00001" then
						readdata <= "000000" & std_logic_vector(red_ghost_sprite_y); --read red y, 1 (2)
					elsif address = "00010" then
						readdata <= "000000" & std_logic_vector(red_ghost_sprite_x); --read red x, 2 (4)
						--cyan ghost
					elsif address <= "00011" then
						readdata <= "000000" & std_logic_vector(cyan_ghost_sprite_y); -- read cyan y, 3 (6)
					elsif address <= "00100" then
						readdata <= "000000" & std_logic_vector(cyan_ghost_sprite_x); -- read cyan x, 4 (8)
						-- orange ghost
					elsif address <= "00101" then
						readdata <= "000000" & std_logic_vector(orange_ghost_sprite_y); -- read orange y, 5 (10)
					elsif address <= "00110" then
						readdata <= "000000" & std_logic_vector(orange_ghost_sprite_x); -- read orange x, 6 (12)
						--pink ghost
					elsif address <= "00111" then
						readdata <= "000000" & std_logic_vector(pink_ghost_sprite_y); -- read pink y, 7 (14)
					elsif address <= "001000" then
						readdata <= "000000" & std_logic_vector(pink_ghost_sprite_x); -- read pink x, 8 (16)
						--pacman sprite
					elsif address <= "01001" then
						readdata <= "000000" & std_logic_vector(pacman_sprite_y); -- read pacman y, 9 (18)
					elsif address <= "01010" then
						readdata <= "000000" & std_logic_vector(pacman_sprite_x); -- read pacman x, 10 (20)
						--frightened/scared ghost
					elsif address <= "01011" then
						readdata <= "000000" & std_logic_vector(scared_ghost_sprite_y); -- read scared y, 11 (22)
					elsif address <= "01100" then
						readdata <= "000000" & std_logic_vector(scared_ghost_sprite_x); -- read scared x, 12 (24)
						--map background (Read only)
					elsif address = "01101" then --13, read map x (26)
						readdata <= "000000" & std_logic_vector(map_sprite_y);
					elsif address = "01110" then --14, read map y (28)
						readdata <= "000000" & std_logic_vector(map_sprite_x);
					else
						readdata <= "0000000000001010";
					end if;
				end if;
				if write = '1' then
					--red ghost
					if address = "01111" then
						red_ghost_sprite_y <= unsigned(writedata(9 downto 0)); --y, 15 (30)
						red_ghost_sprite_x <= red_ghost_sprite_x;
						which_red_spr <= which_red_spr;
					elsif address = "10000" then
						red_ghost_sprite_y <= red_ghost_sprite_y;
						red_ghost_sprite_x <= unsigned(writedata(9 downto 0)); --x, 16 (32)
						which_red_spr <= which_red_spr;
					elsif address = "10001" then
						red_ghost_sprite_y <= red_ghost_sprite_y;
						red_ghost_sprite_x <= red_ghost_sprite_x;
						which_red_spr <= (unsigned(writedata(15 downto 0))); --select animation, 17 (34)
						--cyan ghost
					elsif address = "10010" then
						cyan_ghost_sprite_y <= unsigned(writedata(9 downto 0)); --y, 18 (36)
						cyan_ghost_sprite_x <= cyan_ghost_sprite_x;
						which_cyan_spr <= which_cyan_spr;
					elsif address = "10011" then
						cyan_ghost_sprite_y <= cyan_ghost_sprite_y;
						cyan_ghost_sprite_x <= unsigned(writedata(9 downto 0)); --x, 19 (38)
						which_cyan_spr <= which_cyan_spr;
					elsif address = "10100" then
						cyan_ghost_sprite_y <= cyan_ghost_sprite_y;
						cyan_ghost_sprite_x <= cyan_ghost_sprite_x;
						which_cyan_spr <= (unsigned(writedata(15 downto 0))); --select animation, 20 (40)
						--orange ghost
					elsif address = "10101" then
						orange_ghost_sprite_y <= unsigned(writedata(9 downto 0)); --y, 21 (42)
						orange_ghost_sprite_x <= cyan_ghost_sprite_x;
						which_orange_spr <= which_orange_spr;
					elsif address = "10110" then
						orange_ghost_sprite_y <= orange_ghost_sprite_y;
						orange_ghost_sprite_x <= unsigned(writedata(9 downto 0)); --x, 22 (44)
						which_orange_spr <= which_orange_spr;
					elsif address = "10111" then
						orange_ghost_sprite_y <= orange_ghost_sprite_y;
						orange_ghost_sprite_x <= orange_ghost_sprite_x;
						which_orange_spr <= (unsigned(writedata(15 downto 0))); --select animation, 23 (46)
						--pink ghost
					elsif address = "11000" then
						pink_ghost_sprite_y <= unsigned(writedata(9 downto 0)); --y, 24 (48)
						pink_ghost_sprite_x <= pink_ghost_sprite_x;
						which_pink_spr <= which_pink_spr;
					elsif address = "11001" then
						pink_ghost_sprite_y <= pink_ghost_sprite_y;
						pink_ghost_sprite_x <= unsigned(writedata(9 downto 0)); --x, 25 (50)
						which_pink_spr <= which_pink_spr;
					elsif address = "11010" then
						pink_ghost_sprite_y <= pink_ghost_sprite_y;
						pink_ghost_sprite_x <= pink_ghost_sprite_x;
						which_pink_spr <= (unsigned(writedata(15 downto 0))); --select animation, 26 (52)
						--pacman sprite
					elsif address = "11011" then
						pacman_sprite_y <= unsigned(writedata(9 downto 0)); --y, 27 (54)
						pacman_sprite_x <= pacman_sprite_x;
						which_pacman_spr <= which_pacman_spr;
					elsif address = "11100" then
						pacman_sprite_y <= pacman_sprite_y;
						pacman_sprite_x <= unsigned(writedata(9 downto 0)); --x, 28 (56)
						which_pacman_spr <= which_pacman_spr;
					elsif address = "11101" then
						pacman_sprite_y <= pacman_sprite_y;
						pacman_sprite_x <= pacman_sprite_x;
						which_pacman_spr <= (unsigned(writedata(15 downto 0))); --select animation, 29 (58)
					else
						sprite_y <= sprite_y;
						sprite_x <= sprite_x;
						which_spr <= which_spr;
					end if;
				end if;
			end if;
		end if;
	end process Location_Write;
	----------------------------------------------------------------------------------
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
	
	VCounter : process (clk_25)
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
			elsif EndOfLine = '1' then
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
	---------------------------------------------------------------------------------------------------------------------------------
	-- Sprite generator
	Red_X_Check : process (clk_25)
	begin
		if rising_edge(clk_25) then
			if reset = '1' or (Hcount >= (red_ghost_sprite_x) and Hcount < (red_ghost_sprite_x + sprlen_x)) then
				red_X <= '1';
			else
				red_x <= '0';
			end if;
		end if;
	end process Red_X_Check;
	
	Red_Y_Check : process (clk_25)
	begin
		if rising_edge(clk_25) then
			if reset = '1' then
				red_y <= '0'; -- changed from '1'
			elsif EndOfLine = '1' then
				if Vcount >= (red_ghost_sprite_y) and Vcount < (red_ghost_sprite_y + sprlen_y) then
					red_y <= '1';
				else
					red_y <= '0';
				end if;
			end if;
		end if;
	end process Red_Y_Check;
	red_area <= red_x and red_y;
	---------------------------------------------------------------------------------------------------------------------------------
	Cyan_X_Check : process (clk_25)
	begin
		if rising_edge(clk_25) then
			if reset = '1' or (Hcount >= (cyan_ghost_sprite_x) and Hcount < (cyan_ghost_sprite_x + sprlen_x)) then
				cyan_X <= '1';
			else
				cyan_x <= '0';
			end if;
		end if;
	end process Cyan_X_Check;
	
	Cyan_Y_Check : process (clk_25)
	begin
		if rising_edge(clk_25) then
			if reset = '1' then
				cyan_y <= '0'; -- changed from '1'
			elsif EndOfLine = '1' then
				if Vcount >= (cyan_ghost_sprite_y) and Vcount < (cyan_ghost_sprite_y + sprlen_y) then
					cyan_y <= '1';
				else
					cyan_y <= '0';
				end if;
			end if;
		end if;
	end process Cyan_Y_Check;
	cyan_area <= cyan_x and cyan_y;
	---------------------------------------------------------------------------------------------------------------------------------
	Orange_X_Check : process (clk_25)
	begin
		if rising_edge(clk_25) then
			if reset = '1' or (Hcount >= (orange_ghost_sprite_x) and Hcount < (orange_ghost_sprite_x + sprlen_x)) then
				orange_x <= '1';
			else
				orange_x <= '0';
			end if;
		end if;
	end process Orange_X_Check;
	
	Orange_Y_Check : process (clk_25)
	begin
		if rising_edge(clk_25) then
			if reset = '1' then
				orange_y <= '0'; -- changed from '1'
			elsif EndOfLine = '1' then
				if Vcount >= (orange_ghost_sprite_y) and Vcount < (orange_ghost_sprite_y + sprlen_y) then
					orange_y <= '1';
				else
					orange_y <= '0';
				end if;
			end if;
		end if;
	end process Orange_Y_Check;
	orange_area <= orange_x and orange_y;
	---------------------------------------------------------------------------------------------------------------------------------
	Pink_X_Check : process (clk_25)
	begin
		if rising_edge(clk_25) then
			if reset = '1' or (Hcount >= (pink_ghost_sprite_x) and Hcount < (pink_ghost_sprite_x + sprlen_x)) then
				pink_x <= '1';
			else
				pink_x <= '0';
			end if;
		end if;
	end process Pink_X_Check;
	
	Pink_Y_Check : process (clk_25)
	begin
		if rising_edge(clk_25) then
			if reset = '1' then
				pink_y <= '0'; -- changed from '1'
			elsif EndOfLine = '1' then
				if Vcount >= (pink_ghost_sprite_y) and Vcount < (pink_ghost_sprite_y + sprlen_y) then
					pink_y <= '1';
				else
					pink_y <= '0';
				end if;
			end if;
		end if;
	end process Pink_Y_Check;
	pink_area <= pink_x and pink_y;
	---------------------------------------------------------------------------------------------------------------------------------
	Pacman_X_Check : process (clk_25)
	begin
		if rising_edge(clk_25) then
			if reset = '1' or (Hcount >= (pacman_sprite_x) and Hcount < (pacman_sprite_x + sprlen_x)) then
				pacman_x <= '1';
			else
				pacman_x <= '0';
			end if;
		end if;
	end process Pacman_X_Check;
	
	Pacman_Y_Check : process (clk_25)
	begin
		if rising_edge(clk_25) then
			if reset = '1' then
				pacman_y <= '0'; -- changed from '1'
			elsif EndOfLine = '1' then
				if Vcount >= (pacman_sprite_y) and Vcount < (pacman_sprite_y + sprlen_y) then
					pacman_y <= '1';
				else
					pacman_y <= '0';
				end if;
			end if;
		end if;
	end process Pacman_Y_Check;
	pacman_area <= pacman_x and pacman_y;
	---------------------------------------------------------------------------------------------------------------------------------
	Red_Sprite_Load_Process : process (clk_25)
	begin
		if reset = '1' then
			red_load <= '0';
		else
			if rising_edge(clk_25) then
				if red_area = '1' then
					red_load <= '1';
				else
					red_load <= '0';
				end if;
			end if;
		end if;
	end process Red_Sprite_Load_Process;
	---------------------------------------------------------------------------------------------------------------------------------
	Cyan_Sprite_Load_Process : process (clk_25)
	begin
		if reset = '1' then
			cyan_load <= '0';
		else
			if rising_edge(clk_25) then
				if cyan_area = '1' then
					cyan_load <= '1';
				else
					cyan_load <= '0';
				end if;
			end if;
		end if;
	end process Cyan_Sprite_Load_Process;
	---------------------------------------------------------------------------------------------------------------------------------
	Orange_Sprite_Load_Process : process (clk_25)
	begin
		if reset = '1' then
			orange_load <= '0';
		else
			if rising_edge(clk_25) then
				if orange_area = '1' then
					orange_load <= '1';
				else
					orange_load <= '0';
				end if;
			end if;
		end if;
	end process Orange_Sprite_Load_Process;
	---------------------------------------------------------------------------------------------------------------------------------
	Pink_Sprite_Load_Process : process (clk_25)
	begin
		if reset = '1' then
			pink_load <= '0';
		else
			if rising_edge(clk_25) then
				if pink_area = '1' then
					pink_load <= '1';
				else
					pink_load <= '0';
				end if;
			end if;
		end if;
	end process Pink_Sprite_Load_Process;
	---------------------------------------------------------------------------------------------------------------------------------
	Pacman_Sprite_Load_Process : process (clk_25)
	begin
		if reset = '1' then
			pacman_load <= '0';
		else
			if rising_edge(clk_25) then
				if pacman_area = '1' then
					pacman_load <= '1';
				else
					pacman_load <= '0';
				end if;
			end if;
		end if;
	end process Pacman_Sprite_Load_Process;
	
	--map_result <= (Vcount-1)+(Hcount-1)); -- minus 1 in horiz and vert deals with off-by-one behavior in valid area check;
	map_result <= (Vcount - map_sprite_Y - 1) * maplen_y + (Hcount - map_sprite_x - 1);
	map_sprite_address <= map_result(18 downto 0);
	--red
	red_result <= (Vcount - red_ghost_sprite_y - 1) * sprlen_y + (Hcount - red_ghost_sprite_x - 1); -- minus 1 in horiz and vert deals with off-by-one behavior in valid area check;
	red_address <= red_result(9 downto 0);
	--cyan
	cyan_result <= (Vcount - cyan_ghost_sprite_y - 1) * sprlen_y + (Hcount - cyan_ghost_sprite_x - 1);
	cyan_address <= cyan_result(9 downto 0);
	--orange
	orange_result <= (Vcount - red_ghost_sprite_y - 1) * sprlen_y + (Hcount - red_ghost_sprite_x - 1); -- minus 1 in horiz and vert deals with off-by-one behavior in valid area check;
	orange_address <= orange_result(9 downto 0);
	--pink
	pink_result <= (Vcount - cyan_ghost_sprite_y - 1) * sprlen_y + (Hcount - cyan_ghost_sprite_x - 1);
	pink_address <= pink_result(9 downto 0);
	--pacman
	pacman_result <= (Vcount - cyan_ghost_sprite_y - 1) * sprlen_y + (Hcount - cyan_ghost_sprite_x - 1);
	pacman_address <= pacman_result(9 downto 0);
	
	-- comb logic to select sprite ROM data; alternate between ghost roms to create 'animation'
	with which_red_spr(1 downto 0) select
	spr_data_red <= red1_data when "01",
	                red2_data when "10",
	                (others => '0') when others;
					
	with which_cyan_spr(1 downto 0) select
	spr_data_cyan <= cyan1_data when "01",
	                 cyan2_data when "10",
	                 (others => '0') when others;

	with which_orange_spr(1 downto 0) select
	spr_data_orange <= orange1_data when "01",
	                   orange2_data when "10",
	                   (others => '0') when others;

	with which_pink_spr(1 downto 0) select
	spr_data_pink <= pink1_data when "01",
	                 pink2_data when "10",
	                 (others => '0') when others;

	with which_pacman_spr(2 downto 0) select
	spr_data_pacman <= pacmanopen_data when "001", --1 is open (right)
	                   pacmanclosed_data when "010", --2 is closed
	                   pacman_left_data when "011", -- 3 is left
	                   pacman_up_data when "100", -- 4 is up
	                   pacman_down_data when "101", --5 is down
	                   (others => '0') when others;



	-- Registered video signals going to the video DAC
	VideoOut : process (clk_25, reset)
	begin
		if reset = '1' then
			VGA_R <= "00000000";
			VGA_G <= "00000000";
			VGA_B <= "00000000";
		elsif clk_25'EVENT and clk_25 = '1' then --when rising edge of the 25MHz clock
			if red_load = '1' and spr_data_red(24) = '0' then --show red ghost
				VGA_R <= std_logic_vector(spr_data_red(23 downto 16));
				VGA_G <= std_logic_vector(spr_data_red(15 downto 8));
				VGA_B <= std_logic_vector(spr_data_red(7 downto 0));
			elsif cyan_load = '1' and spr_data_cyan(24) = '0' then -- show cyan ghost
				VGA_R <= std_logic_vector(spr_data_cyan(23 downto 16));
				VGA_G <= std_logic_vector(spr_data_cyan(15 downto 8));
				VGA_B <= std_logic_vector(spr_data_cyan(7 downto 0));
			elsif orange_load = '1' and spr_data_orange(24) = '0' then -- show orange ghost
				VGA_R <= std_logic_vector(spr_data_orange(23 downto 16));
				VGA_G <= std_logic_vector(spr_data_orange(15 downto 8));
				VGA_B <= std_logic_vector(spr_data_orange(7 downto 0));
			elsif pink_load = '1' and spr_data_pink(24) = '0' then -- show pink ghost
				VGA_R <= std_logic_vector(spr_data_pink(23 downto 16));
				VGA_G <= std_logic_vector(spr_data_pink(15 downto 8));
				VGA_B <= std_logic_vector(spr_data_pink(7 downto 0));
			elsif pacman_load = '1' and spr_data_pacman(24) = '0' then -- show pacman
				VGA_R <= std_logic_vector(spr_data_pacman(23 downto 16));
				VGA_G <= std_logic_vector(spr_data_pacman(15 downto 8));
				VGA_B <= std_logic_vector(spr_data_pacman(7 downto 0));
			-- elsif show_map = '1' and map_sprite_data(24) = '0' then
			-- VGA_R <= std_logic_vector(map_sprite_data(23 downto 16));
			-- VGA_G <= std_logic_vector(map_sprite_data(15 downto 8));
			-- VGA_B <= std_logic_vector(map_sprite_data(7 downto 0));
			elsif vga_hblank = '0' and vga_vblank = '0' then-- showmap
				VGA_R <= std_logic_vector(map_sprite_data(23 downto 16));
				VGA_G <= std_logic_vector(map_sprite_data(15 downto 8));
				VGA_B <= std_logic_vector(map_sprite_data(7 downto 0));
			else --default to showing black
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