-------------------------------------------------------------------------------
--
-- Author: D. M. Calhoun
-- Description: VGA raster controller for DE10-Standard with integrated sprite
-- 				 selector and Avalon memory-mapped IO
-- Adapted from DE2 controller written by Stephen A. Edwards
--
-------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
ENTITY de2_vga_raster IS
 
	PORT (
		reset : IN std_logic;
		clk : IN std_logic; -- Should be 25.125 MHz
		VGA_CLK, -- Clock
		VGA_HS, -- H_SYNC
		VGA_VS, -- V_SYNC
		VGA_BLANK, -- BLANK
		VGA_SYNC : OUT std_logic; -- SYNC
		VGA_R, -- Red[9:0]
		VGA_G, -- Green[9:0]
		VGA_B : OUT std_logic_vector(9 DOWNTO 0); -- Blue[9:0]
		chipselect : IN std_logic;
		write : IN std_logic;
		read : IN std_logic;
		address : IN unsigned(4 DOWNTO 0);
		readdata : OUT unsigned(15 DOWNTO 0);
		writedata : IN unsigned(15 DOWNTO 0);
		byteenable : IN unsigned(1 DOWNTO 0);
		irq : OUT std_logic
	);
END de2_vga_raster;
ARCHITECTURE rtl OF de2_vga_raster IS
 
	-- Video parameters
	CONSTANT HTOTAL : INTEGER := 800;
	CONSTANT HSYNC : INTEGER := 96;
	CONSTANT HBACK_PORCH : INTEGER := 48;
	CONSTANT HACTIVE : INTEGER := 640;
	CONSTANT HFRONT_PORCH : INTEGER := 16;
 
	CONSTANT VTOTAL : INTEGER := 525;
	CONSTANT VSYNC : INTEGER := 2;
	CONSTANT VBACK_PORCH : INTEGER := 33;
	CONSTANT VACTIVE : INTEGER := 480;
	CONSTANT VFRONT_PORCH : INTEGER := 10;
	-- Signals for the video controller
	SIGNAL Hcount : unsigned(9 DOWNTO 0); -- Horizontal position (0-800)
	SIGNAL Vcount : unsigned(9 DOWNTO 0); -- Vertical position (0-524)
	SIGNAL EndOfLine, EndOfField : std_logic;
 
	SIGNAL 
	RGB, RGB_G, RGB_B, RGB_r, RGB_G_r, RGB_B_r, RGB_bg, RGB_G_bg, RGB_B_bg : 
	std_logic_vector (9 DOWNTO 0);
 
	SIGNAL background_x, background_y : INTEGER;--back ground;
	--signal score_x,score_y: integer;
 
	SIGNAL vga_hblank, vga_hsync, 
	vga_vblank, vga_vsync : std_logic; -- Sync. signals
	SIGNAL l1, l2, l3, r1, r2, r3 : INTEGER := 2;--l1,l2,l3:left pad lose score; r1,r2,r3: right pad 
	lose score;
	SIGNAL rectangle_h_ball, rectangle_v_ball, rectangle_h_ball1, rectangle_v_ball1, rectangle_h_ball2, rectangle_v_ball2, rectangle_h_paddle, rectangle_v_paddle, 
			 rectangle_ball, rectangle_ball1, rectangle_ball2, rectangle_paddle, 
			 rectangle_h_paddle_2, rectangle_v_paddle_2, rectangle_paddle_2 : std_logic; -- rectangle area
			 
	SIGNAL clk25 : std_logic := '0';
	SIGNAL RECTANGLE_HSTART : unsigned(15 DOWNTO 0) := x"0100";
	SIGNAL RECTANGLE_VSTART : unsigned(15 DOWNTO 0) := x"0000";
	SIGNAL RECTANGLE_HSTART_ball1 : unsigned(15 DOWNTO 0) := x"0010";
	SIGNAL RECTANGLE_VSTART_ball1 : unsigned(15 DOWNTO 0) := x"0000";
	SIGNAL RECTANGLE_HSTART_ball2 : unsigned(15 DOWNTO 0) := x"000F";
	SIGNAL RECTANGLE_VSTART_ball2 : unsigned(15 DOWNTO 0) := x"0000";
	SIGNAL RECTANGLE_HSTART_paddle : unsigned(15 DOWNTO 0) := x"0000";
	SIGNAL RECTANGLE_VSTART_paddle : unsigned(15 DOWNTO 0) := x"0000";
	SIGNAL RECTANGLE_HSTART_paddle_2 : unsigned(15 DOWNTO 0) := x"016B";
	SIGNAL RECTANGLE_VSTART_paddle_2 : unsigned(15 DOWNTO 0) := x"00a0";
	SIGNAL num : INTEGER; 
	SIGNAL flag : std_logic := '0'; 
	SIGNAL bg_flag : std_logic := '0'; 
	TYPE ram_type IS ARRAY(0 TO 15, 0 TO 15) OF std_logic_vector(9 DOWNTO 0);
	SIGNAL ball_r : ram_type := (
		("0000000000", "0000000000,” … "0000000000")
	);
	SIGNAL ball_g : ram_type := (
		("0000000000", "0000000000”, … "0000000000")
	); 
	SIGNAL ball_b : ram_type := (
		("0000000000", "0000000000", …, "0000000000")
	);
	SIGNAL ball1_r : ram_type := (
		("0000000000", "0000000000", …, "0000000000")
	);
	SIGNAL ball1_g : ram_type := (
		("0000000000", "0000000000", …, "0000000000")
	);
	SIGNAL ball1_b : ram_type := (
		("0000000000", "0000000000", …, "0000000000")
	);
	SIGNAL ball2_r : ram_type := (
		("0000000000", "0000000000", …, "0000000000")
	);
	SIGNAL ball2_g : ram_type := (
		("0000000000", "0000000000", …, "0000000000")
	);
	SIGNAL ball2_b : ram_type := (
		("0000000000", "0000000000", …, "0000000000")
	);
	TYPE rom_type IS ARRAY (0 TO 119, 0 TO 20) OF std_logic_vector (9 DOWNTO 0);
	CONSTANT pad_r : rom_type := 
	(
	("0000000000", "0000000000", …
		);
		TYPE flag1 IS ARRAY(INTEGER RANGE 0 TO 14, INTEGER RANGE 0 TO 19) OF INTEGER;
		SIGNAL background : flag1 := (
			(0, 0, 0, 0, 0, 0, l1, l2, l3, 0, 0, r3, r2, r1, 0, 0, 0, 0, 0, 0), --l3,l2,l1:left pad score; r3,r2,r1:right 
			pad score;
			(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0), (0, 0, 0, 0, 0, 1, 1, 1, 0, 0, 0, 1, 1, 1, 0, 0, 0, 0, 0, 0), 
			(0, 0, 0, 0, 1, 0, 0, 0, 1, 0, 1, 0, 0, 0, 1, 0, 0, 0, 0, 0), (0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0), 
			(0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0), (0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0), 
			(0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0), (0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0), 
			(0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0), (0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0), 
			(0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0), (0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0), 
			(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0), (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0) 
	);
BEGIN

	PROCESS (clk)
	BEGIN
		IF rising_edge(clk) THEN
			clk25 <= NOT clk25;
		END IF;
	END PROCESS;
	-- Horizontal and vertical counters
	-- new plug in
	one : PROCESS (clk)
	BEGIN
		IF rising_edge(clk) THEN 
			IF chipselect = '1' THEN 
				IF read = '1' THEN 
					CASE address(3 DOWNTO 0) IS
						WHEN "0000" => readdata <= 
							RECTANGLE_HSTART; 
						WHEN "0001" => readdata <= 
							RECTANGLE_VSTART;
						WHEN "0010" => readdata <= 
							RECTANGLE_HSTART_paddle;
						WHEN "0011" => readdata <= 
							RECTANGLE_VSTART_paddle;
						WHEN "0100" => readdata <= 
							RECTANGLE_HSTART_paddle_2;
						WHEN "0101" => readdata <= 
							RECTANGLE_VSTART_paddle_2;
							-- when "0110" => readdata <= 
							to_unsigned(l3);
							-- when "0111" => readdata <= 
							to_unsigned(l2); 
							-- when "1000" => readdata <= 
							to_unsigned(l1);
							-- when "1001" => readdata <= 
							to_unsigned(r3); 
							-- when "1010" => readdata <= 
							to_unsigned(r2); 
							-- when "1011" => readdata <= 
							to_unsigned(r1); 
						WHEN OTHERS => readdata <= 
							X"0000";
					END CASE;
				ELSIF write = '1' THEN
 
					CASE address(3 DOWNTO 0) IS
						WHEN "0000" => 
							RECTANGLE_HSTART <= writedata; 
						WHEN "0001" => 
							RECTANGLE_VSTART <= writedata;
						WHEN "0010" => 
							RECTANGLE_HSTART_paddle <= writedata;
						WHEN "0011" => 
							RECTANGLE_VSTART_paddle <= writedata;
						WHEN "0100" => 
							RECTANGLE_HSTART_paddle_2 <= writedata;
						WHEN "0101" => 
							RECTANGLE_VSTART_paddle_2 <= writedata; 
						WHEN "0110" => l1 <= 
							to_integer(writedata);
						WHEN "0111" => l2 <= 
							to_integer(writedata); 
						WHEN "1000" => l3 <= 
							to_integer(writedata);
						WHEN "1001" => r1 <= 
							to_integer(writedata);
						WHEN "1010" => r2 <= 
							to_integer(writedata);
						WHEN "1011" => r3 <= 
							to_integer(writedata);
						WHEN "1100" => 
							RECTANGLE_HSTART_ball1 <= writedata; 
						WHEN "1101" => 
							RECTANGLE_VSTART_ball1 <= writedata;
						WHEN "1110" => 
							RECTANGLE_HSTART_ball2 <= writedata; 
						WHEN "1111" => 
							RECTANGLE_VSTART_ball2 <= writedata;
						WHEN OTHERS => 
							RECTANGLE_HSTART <= writedata;
					END CASE;
				END IF; 
			END IF;
		END IF;
	END PROCESS one;
	HCounter : PROCESS (clk25)
	BEGIN
		IF rising_edge(clk25) THEN 
			IF reset = '1' THEN
				Hcount <= (OTHERS => '0');
			ELSIF EndOfLine = '1' THEN
				Hcount <= (OTHERS => '0');
			ELSE
				Hcount <= Hcount + 1;
			END IF; 
		END IF;
	END PROCESS HCounter;
	EndOfLine <= '1' WHEN Hcount = HTOTAL - 1 ELSE '0';
 
	VCounter : PROCESS (clk25)
	BEGIN
		IF rising_edge(clk25) THEN 
			IF reset = '1' THEN
				irq <= '0';
				Vcount <= (OTHERS => '0');
			ELSIF EndOfLine = '1' THEN
 
				IF EndOfField = '1' THEN
					Vcount <= (OTHERS => '0');
					flag <= '1';
					irq <= '1';
					-- elsif write = '1' and chipselect = '1' then
					-- irq <= '0';
					-- Vcount <= Vcount + 1;
					-- flag <= '0';
				ELSE
					Vcount <= Vcount + 1;
					flag <= '0';
					irq <= '0';
				END IF;
			ELSE
				IF write = '1' AND chipselect = '1' THEN
					irq <= '0';
				END IF;
			END IF;
		END IF;
	END PROCESS VCounter;
	EndOfField <= '1' WHEN Vcount = VTOTAL - 1 ELSE '0';
	-- State machines to generate HSYNC, VSYNC, HBLANK, and VBLANK
	HSyncGen : PROCESS (clk25)
	BEGIN
		IF rising_edge(clk25) THEN 
			IF reset = '1' OR EndOfLine = '1' THEN
				vga_hsync <= '1';
			ELSIF Hcount = HSYNC - 1 THEN
				vga_hsync <= '0';
			END IF;
		END IF;
	END PROCESS HSyncGen;
 
	HBlankGen : PROCESS (clk25)
	BEGIN
		IF rising_edge(clk25) THEN
			IF reset = '1' THEN
				vga_hblank <= '1';
			ELSIF Hcount = HSYNC + HBACK_PORCH THEN
				vga_hblank <= '0';
			ELSIF Hcount = HSYNC + HBACK_PORCH + HACTIVE THEN
				vga_hblank <= '1';
			END IF; 
		END IF;
	END PROCESS HBlankGen;
	VSyncGen : PROCESS (clk25)
	BEGIN
		IF rising_edge(clk25) THEN
			IF reset = '1' THEN
				vga_vsync <= '1';
			ELSIF EndOfLine = '1' THEN
				IF EndOfField = '1' THEN
					vga_vsync <= '1';
				ELSIF Vcount = VSYNC - 1 THEN
					vga_vsync <= '0';
				END IF;
			END IF; 
		END IF;
	END PROCESS VSyncGen;
	VBlankGen : PROCESS (clk25)
	BEGIN
		IF rising_edge(clk25) THEN 
			IF reset = '1' THEN
				vga_vblank <= '1';
			ELSIF EndOfLine = '1' THEN
				IF Vcount = VSYNC + VBACK_PORCH - 1 THEN
					vga_vblank <= '0';
				ELSIF Vcount = VSYNC + VBACK_PORCH + VACTIVE - 1 THEN
					vga_vblank <= '1';
				END IF;
			END IF;
		END IF;
	END PROCESS VBlankGen;
	
	-- back ground generator
	background_x <= to_integer(Hcount - HSYNC - HBACK_PORCH - 1);
	background_y <= to_integer(Vcount - VSYNC - VBACK_PORCH);
	
	-- Rectangle generator
	RectangleHGenball : PROCESS (clk25)
	BEGIN
		IF rising_edge(clk25) THEN 
			IF reset = '1' OR Hcount = HSYNC + HBACK_PORCH + RECTANGLE_HSTART THEN
			 rectangle_h_ball <= '1';
			 ELSIF Hcount = HSYNC + HBACK_PORCH + RECTANGLE_HSTART + 16 THEN
			rectangle_h_ball <= '0';
			END IF; 
		END IF; 
	END PROCESS RectangleHGenball;
	
	RectangleHGenball1 : PROCESS (clk25)
	BEGIN
		IF rising_edge(clk25) THEN 
 
			IF reset = '1' OR Hcount = HSYNC + HBACK_PORCH + 
			 RECTANGLE_HSTART_ball1 THEN
				rectangle_h_ball1 <= '1';
			ELSIF Hcount = HSYNC + HBACK_PORCH + RECTANGLE_HSTART_ball1 + 16 
				THEN
				rectangle_h_ball1 <= '0';
			END IF; 
			END IF; 
		END PROCESS RectangleHGenball1;
		
	RectangleHGenball2 : PROCESS (clk25)
	BEGIN
		IF rising_edge(clk25) THEN 

			IF reset = '1' OR Hcount = HSYNC + HBACK_PORCH + 
			 RECTANGLE_HSTART_ball2 THEN
				rectangle_h_ball2 <= '1';
			ELSIF Hcount = HSYNC + HBACK_PORCH + RECTANGLE_HSTART_ball2 + 16 
				THEN
				rectangle_h_ball2 <= '0';
			END IF; 
			END IF; 
		END PROCESS RectangleHGenball2;
		
	RectangleHGenl : PROCESS (clk25)
	BEGIN
		IF rising_edge(clk25) THEN 
			IF reset = '1' OR Hcount = HSYNC + HBACK_PORCH + 
			 RECTANGLE_HSTART_paddle THEN
				rectangle_h_paddle <= '1';
			ELSIF Hcount = HSYNC + HBACK_PORCH + RECTANGLE_HSTART_paddle + 21 
				THEN
				rectangle_h_paddle <= '0';
			END IF; 
			END IF;
		END PROCESS RectangleHGenl;
		
	RectangleHGenr : PROCESS (clk25)
	BEGIN
		IF rising_edge(clk25) THEN 
			IF reset = '1' OR Hcount = HSYNC + HBACK_PORCH + 
			 RECTANGLE_HSTART_paddle_2 THEN
				rectangle_h_paddle_2 <= '1';
			ELSIF Hcount = HSYNC + HBACK_PORCH + RECTANGLE_HSTART_paddle_2 + 21 
				THEN
				rectangle_h_paddle_2 <= '0';
			END IF; 
			END IF;
		END PROCESS RectangleHGenr;
		
	RectangleVGenball : PROCESS (clk25)--rectangle of the ball
	BEGIN
		IF rising_edge(clk25) THEN
			IF reset = '1' THEN 
				rectangle_v_ball <= '0';
			ELSIF EndOfLine = '1' THEN 
				IF Vcount = VSYNC + VBACK_PORCH - 1 + RECTANGLE_VSTART THEN
					rectangle_v_ball <= '1';
				ELSIF Vcount = VSYNC + VBACK_PORCH - 1 + RECTANGLE_VSTART + 16 THEN
					rectangle_v_ball <= '0';
				ELSIF Vcount < VSYNC + VBACK_PORCH - 1 + RECTANGLE_VSTART OR Vcount > VSYNC + VBACK_PORCH - 1 + RECTANGLE_VSTART + 16 THEN
					rectangle_v_ball <= '0';
				END IF;
			END IF; 
		END IF;
	END PROCESS RectangleVGenball;
	
	RectangleVGenball1 : PROCESS (clk25)--rectangle of the ball1
	BEGIN
		IF rising_edge(clk25) THEN
			IF reset = '1' THEN 
				rectangle_v_ball1 <= '0';
			ELSIF EndOfLine = '1' THEN 
				IF Vcount = VSYNC + VBACK_PORCH - 1 + RECTANGLE_VSTART_ball1 THEN
					rectangle_v_ball1 <= '1';
				ELSIF Vcount = VSYNC + VBACK_PORCH - 1 + RECTANGLE_VSTART_ball1 + 16 THEN
					rectangle_v_ball1 <= '0';
				ELSIF Vcount < VSYNC + VBACK_PORCH - 1 + RECTANGLE_VSTART_ball1 OR Vcount > VSYNC + VBACK_PORCH - 1 + RECTANGLE_VSTART_ball1 + 16 THEN
					rectangle_v_ball1 <= '0';
				END IF;
			END IF; 
		END IF;
	END PROCESS RectangleVGenball1;
					RectangleVGenball2 : PROCESS (clk25)--rectangle of the ball2
					BEGIN
						IF rising_edge(clk25) THEN
							IF reset = '1' THEN 
								rectangle_v_ball2 <= '0';
							ELSIF EndOfLine = '1' THEN 
								IF Vcount = VSYNC + VBACK_PORCH - 1 + RECTANGLE_VSTART_ball2 THEN
									rectangle_v_ball2 <= '1';
								ELSIF Vcount = VSYNC + VBACK_PORCH - 1 + RECTANGLE_VSTART_ball2 + 
									16 THEN
									rectangle_v_ball2 <= '0';
								ELSIF Vcount < VSYNC + VBACK_PORCH - 1 + RECTANGLE_VSTART_ball2 
									OR Vcount > VSYNC + VBACK_PORCH - 1 + RECTANGLE_VSTART_ball2 + 16 THEN
									rectangle_v_ball2 <= '0';
								END IF;
							END IF; 
						END IF;
					END PROCESS RectangleVGenball2;
					RectangleVGenl : PROCESS (clk25)--rectangle of the left paddle
					BEGIN
						IF rising_edge(clk25) THEN
							IF reset = '1' THEN 
								rectangle_v_paddle <= '0';
							ELSIF EndOfLine = '1' THEN
								IF Vcount = VSYNC + VBACK_PORCH - 1 + RECTANGLE_VSTART_paddle THEN
									rectangle_v_paddle <= '1';
								ELSIF Vcount = VSYNC + VBACK_PORCH - 1 + RECTANGLE_VSTART_paddle + 
									120 THEN
									rectangle_v_paddle <= '0';
								ELSIF Vcount < VSYNC + VBACK_PORCH - 1 + RECTANGLE_VSTART_paddle OR 
									Vcount > VSYNC + VBACK_PORCH - 1 + RECTANGLE_VSTART_paddle + 120 THEN
									rectangle_v_paddle <= '0';
								END IF;
							END IF; 
						END IF;
					END PROCESS RectangleVGenl;
					RectangleVGenr : PROCESS (clk25)--rectangle of the right paddle
					BEGIN
						IF rising_edge(clk25) THEN
							IF reset = '1' THEN 
								rectangle_v_paddle_2 <= '0';
							ELSIF EndOfLine = '1' THEN
								IF Vcount = VSYNC + VBACK_PORCH - 1 + RECTANGLE_VSTART_paddle_2 
								 THEN
								 rectangle_v_paddle_2 <= '1';
								 ELSIF Vcount = VSYNC + VBACK_PORCH - 1 + RECTANGLE_VSTART_paddle_2 
									  + 120 THEN
										rectangle_v_paddle_2 <= '0';
									ELSIF Vcount < VSYNC + VBACK_PORCH - 1 + RECTANGLE_VSTART_paddle_2 OR 
										Vcount > VSYNC + VBACK_PORCH - 1 + RECTANGLE_VSTART_paddle_2 + 120 THEN
										rectangle_v_paddle_2 <= '0';
									END IF;
								END IF; 
							END IF;
						END PROCESS RectangleVGenr;
						rectangle_ball <= rectangle_h_ball AND rectangle_v_ball;--ball area
						rectangle_ball1 <= rectangle_h_ball1 AND rectangle_v_ball1;--ball_1 area
						rectangle_ball2 <= rectangle_h_ball2 AND rectangle_v_ball2;--ball_2 area
						rectangle_paddle <= rectangle_h_paddle AND rectangle_v_paddle;--left paddle 
						area
						rectangle_paddle_2 <= rectangle_h_paddle_2 AND rectangle_v_paddle_2;-- right 
						paddle area
						-- Registered video signals going to the video DAC
						backgroundgen : PROCESS (clk25)
						BEGIN
							IF rising_edge(clk25) THEN
								IF background_x >= 0 AND background_x <= 640 AND background_y >= 0 AND 
								 background_y <= 480 THEN
									num <= background(background_y/32, (background_x MOD 
										640)/32);
										CASE num IS
											WHEN 1 => RGB_bg <= background_r(background_y 
												MOD 32, background_x MOD 32);
												RGB_G_bg <= 
													background_g(background_y MOD 32, background_x MOD 32);
													RGB_B_bg <= 
														background_b(background_y MOD 32, background_x MOD 32);
														bg_flag <= '1';
											WHEN 2 => RGB_bg <= score_r(background_y MOD 
												32, background_x MOD 32);
												RGB_G_bg <= score_g(background_y 
													MOD 32, background_x MOD 32);
													RGB_B_bg <= score_b(background_y 
														MOD 32, background_x MOD 32);
														bg_flag <= '1';
 
											WHEN OTHERS => RGB_bg <= "1111111111";
											RGB_G_bg <= "1111111111";
											RGB_B_bg <= "1111111111";
											bg_flag <= '0';
									END CASE;
								ELSE 
									RGB_bg <= "0000000000";
									RGB_G_bg <= "0000000000";
									RGB_B_bg <= "0000000000";
									bg_flag <= '0';
								END IF;
								END IF;
							END PROCESS backgroundgen;
							
VideoOut : PROCESS (clk25, reset)
BEGIN
	IF reset = '1' THEN
		VGA_R <= "1111111111";
		VGA_G <= "1111111111";
		VGA_B <= "1111111111";
	ELSIF clk25'EVENT AND clk25 = '1' THEN
		-- ball
		IF rectangle_ball = '1' AND 
		 ball_r(to_integer (Vcount - (VSYNC + VBACK_PORCH - 1 + RECTANGLE_VSTART + 1)), to_integer(Hcount - (HSYNC + HBACK_PORCH + RECTANGLE_HSTART) - 1)) >= "0000000010" THEN
				VGA_R <= ball_r(to_integer (Vcount - (VSYNC + VBACK_PORCH - 1 + RECTANGLE_VSTART + 1)), to_integer(Hcount - (HSYNC + HBACK_PORCH + RECTANGLE_HSTART) - 1));
				VGA_G <= ball_g(to_integer (Vcount - (VSYNC + VBACK_PORCH - 1 + 
					RECTANGLE_VSTART + 1)), to_integer(Hcount - (HSYNC + HBACK_PORCH + 
					RECTANGLE_HSTART) - 1));
					VGA_B <= ball_b(to_integer (Vcount - (VSYNC + VBACK_PORCH - 1 + 
						RECTANGLE_VSTART + 1)), to_integer(Hcount - (HSYNC + HBACK_PORCH + 
						RECTANGLE_HSTART) - 1));
						--end of ball
						--ball1
		ELSIF rectangle_ball1 = '1' AND ball1_r(to_integer (Vcount - (VSYNC + VBACK_PORCH - 1 + RECTANGLE_VSTART_ball1 + 1)), to_integer(Hcount - (HSYNC + HBACK_PORCH + RECTANGLE_HSTART_ball1) - 1)) /= "0000000000" THEN
				VGA_R <= ball1_r(to_integer (Vcount - (VSYNC + VBACK_PORCH - 1 + RECTANGLE_VSTART_ball1 + 1)), to_integer(Hcount - (HSYNC + HBACK_PORCH + RECTANGLE_HSTART_ball1) - 1));
				VGA_G <= ball1_g(to_integer (Vcount - (VSYNC + VBACK_PORCH - 1 + 
					RECTANGLE_VSTART_ball1 + 1)), to_integer(Hcount - (HSYNC + HBACK_PORCH + 
					RECTANGLE_HSTART_ball1) - 1));
					VGA_B <= ball1_b(to_integer (Vcount - (VSYNC + VBACK_PORCH - 1 + 
						RECTANGLE_VSTART_ball1 + 1)), to_integer(Hcount - (HSYNC + HBACK_PORCH + 
						RECTANGLE_HSTART_ball1) - 1));
						--end of ball1
						--ball2
		ELSIF rectangle_ball2 = '1' AND 
			ball2_r(to_integer (Vcount - (VSYNC + VBACK_PORCH - 1 + 
			RECTANGLE_VSTART_ball2 + 1)), to_integer(Hcount - (HSYNC + HBACK_PORCH + 
			RECTANGLE_HSTART_ball2) - 1)) /= "0000000000" THEN
			-- ball_g(to_integer (Vcount -(VSYNC + VBACK_PORCH - 1 + 
			RECTANGLE_VSTART + 1)), to_integer(Hcount - (HSYNC + HBACK_PORCH + 
			RECTANGLE_HSTART) - 1)) /= X"00" AND
				-- ball_b(to_integer (Vcount -(VSYNC + VBACK_PORCH - 1 + 
				RECTANGLE_VSTART + 1)), to_integer(Hcount - (HSYNC + HBACK_PORCH + 
				RECTANGLE_HSTART) - 1)) /= X"00" THEN
				VGA_R <= ball2_r(to_integer (Vcount - (VSYNC + VBACK_PORCH - 1 + 
				RECTANGLE_VSTART_ball2 + 1)), to_integer(Hcount - (HSYNC + HBACK_PORCH + 
				RECTANGLE_HSTART_ball2) - 1));
				VGA_G <= ball2_g(to_integer (Vcount - (VSYNC + VBACK_PORCH - 1 + 
					RECTANGLE_VSTART_ball2 + 1)), to_integer(Hcount - (HSYNC + HBACK_PORCH + 
					RECTANGLE_HSTART_ball2) - 1));
					VGA_B <= ball2_b(to_integer (Vcount - (VSYNC + VBACK_PORCH - 1 + 
						RECTANGLE_VSTART_ball2 + 1)), to_integer(Hcount - (HSYNC + HBACK_PORCH + 
						RECTANGLE_HSTART_ball2) - 1));
						--end of ball2
						-- left paddle
		ELSIF rectangle_paddle = '1' THEN
			-- VGA_R <= rgb;
			-- VGA_G <= rgb_g;
			-- VGA_B <= rgb_b;
			VGA_R <= pad_r(to_integer(Vcount - (VSYNC + VBACK_PORCH - 1 + 
				RECTANGLE_VSTART_paddle + 1)), to_integer(Hcount - (HSYNC + HBACK_PORCH + 
				RECTANGLE_HSTART_paddle) - 1));
				VGA_G <= pad_g(to_integer(Vcount - (VSYNC + VBACK_PORCH - 1 + 
					RECTANGLE_VSTART_paddle + 1)), to_integer(Hcount - (HSYNC + HBACK_PORCH + 
					RECTANGLE_HSTART_paddle) - 1));
					VGA_B <= pad_b(to_integer(Vcount - (VSYNC + VBACK_PORCH - 1 + 
						RECTANGLE_VSTART_paddle + 1)), to_integer(Hcount - (HSYNC + HBACK_PORCH + 
						RECTANGLE_HSTART_paddle) - 1));
						--end of left paddle
						--right paddle
		ELSIF rectangle_paddle_2 = '1' THEN
			-- VGA_R <= rgb_r;
			-- VGA_G <= rgb_g_r;
			-- VGA_B <= rgb_b_r;
			VGA_R <= pad_r(to_integer(Vcount - (VSYNC + VBACK_PORCH - 1 + 
				RECTANGLE_VSTART_paddle_2 + 1)), to_integer(Hcount - (HSYNC + HBACK_PORCH + 
				RECTANGLE_HSTART_paddle_2) - 1));
				VGA_G <= pad_g(to_integer(Vcount - (VSYNC + VBACK_PORCH - 1 + 
					RECTANGLE_VSTART_paddle_2 + 1)), to_integer(Hcount - (HSYNC + HBACK_PORCH + 
					RECTANGLE_HSTART_paddle_2) - 1));
					VGA_B <= pad_b(to_integer(Vcount - (VSYNC + VBACK_PORCH - 1 + 
						RECTANGLE_VSTART_paddle_2 + 1)), to_integer(Hcount - (HSYNC + HBACK_PORCH + 
						RECTANGLE_HSTART_paddle_2) - 1));
						----end of right paddle
						-- back ground
		ELSIF bg_flag = '1' THEN
			VGA_R <= RGB_bg;
			VGA_G <= RGB_G_bg;
			VGA_B <= RGB_B_bg; 
			-- end of back ground 
		ELSIF vga_hblank = '0' AND vga_vblank = '0' THEN 
			VGA_R <= "0000000000";
			VGA_G <= "0000000000";
			VGA_B <= "0000000000";
		ELSE
			VGA_R <= "0000000000";
			VGA_G <= "0000000000";
			VGA_B <= "0000000000"; 
		END IF; 
		END IF;
	END PROCESS VideoOut;
	VGA_clk <= clk25;
	VGA_SYNC <= '0'; 
	VGA_HS <= NOT vga_hsync;
	VGA_VS <= NOT vga_vsync;
	VGA_BLANK <= NOT (vga_hsync OR vga_vsync);
END rtl;