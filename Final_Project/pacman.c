#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <fcntl.h>
#include <signal.h>
#include <sys/mman.h>
#include "hps_0.h"
#include <time.h>

#define REG_BASE 0xff200000 //LW H2F Bride Base Address
#define REG_SPAN 0x00200000 //LW H2F Bridge Span

#define VGA_BLANK 0

#define VGA_RDY_POS_map 22
#define VGA_RDX_POS_map 24

#define VGA_RDY_POS_red 2
#define VGA_RDX_POS_red 4
#define VGA_WRY_POS_red 30
#define VGA_WRX_POS_red 32

#define VGA_RDY_POS_cyan 6
#define VGA_RDX_POS_cyan 8
#define VGA_WRY_POS_cyan 36
#define VGA_WRX_POS_cyan 38

#define VGA_RDY_POS_orange 10
#define VGA_RDX_POS_orange 12
#define VGA_WRY_POS_orange 42
#define VGA_WRX_POS_orange 44

#define VGA_RDY_POS_pink 14
#define VGA_RDX_POS_pink 16
#define VGA_WRY_POS_pink 48
#define VGA_WRX_POS_pink 50

#define VGA_RDY_POS_pacman 18
#define VGA_RDX_POS_pacman 20
#define VGA_WRY_POS_pacman 54
#define VGA_WRX_POS_pacman 56

//sprite select
#define VGA_SPRITES_red 34
#define VGA_SPRITES_cyan 40
#define VGA_SPRITES_orange 46
#define VGA_SPRITES_pink 52
#define VGA_SPRITES_pacman 58

// radius of circle
#define RADIUS 15
// HTOTAL - HFRONT_PORCH - HACTIVE
#define LEFT_EDGE 144
// HTOTAL - HFRONT_PORCH
#define RIGHT_EDGE 774
// VTOTAL - VFRONT_PORCH - VACTIVE
#define TOP_EDGE 30
// VTOTAL - VFRONT_PORCH
#define BOTTOM_EDGE 515


void *base;
uint16_t *blank;
uint16_t *ready_red;
uint16_t *readx_red;
uint16_t *writey_red;
uint16_t *writex_red;

uint16_t *ready_cyan;
uint16_t *readx_cyan;
uint16_t *writey_cyan;
uint16_t *writex_cyan;

uint16_t *ready_orange;
uint16_t *readx_orange;
uint16_t *writey_orange;
uint16_t *writex_orange;

uint16_t *ready_pink;
uint16_t *readx_pink;
uint16_t *writey_pink;
uint16_t *writex_pink;

uint16_t *ready_pacman;
uint16_t *readx_pacman;
uint16_t *writey_pacman;
uint16_t *writex_pacman;

uint16_t *sprite_select;
uint16_t *sprite_select_red;
uint16_t *sprite_select_cyan;
uint16_t *sprite_select_pink;
uint16_t *sprite_select_orange;
uint16_t *sprite_select_pacman;

uint32_t *key0;
uint32_t *key1;
uint32_t *key2;
uint32_t *key3;

int fd;

void handler(int signo){
	*key0 = 0x0; //up
	*key1 = 0x0; //down
	*key2 = 0x0; //right
	*key3 = 0x0; //left
	*blank=0;
	munmap(base, REG_SPAN);
	close(fd);
	exit(0);
}

int main(){
	int i = 0;
	int ghost_time = 0;
	unsigned int is_blank = 0;

	unsigned int x_red = 250;
	unsigned int y_red = 250;
	unsigned int calcx_red = 435;
	unsigned int calcy_red = 435;
	unsigned int vx_red = 1; //"positive direction"
	unsigned int vy_red = 1; //"positive direction"

	unsigned int x_cyan = 435;
	unsigned int y_cyan = 435;
	unsigned int calcx_cyan = 435;
	unsigned int calcy_cyan = 435;
	unsigned int vx_cyan = 1; //"positive direction"
	unsigned int vy_cyan = 1; //"positive direction"

	unsigned int x_orange = 300;
	unsigned int y_orange = 400;
	unsigned int calcx_orange = 435;
	unsigned int calcy_orange = 435;
	unsigned int vx_orange = 1; //"positive direction"
	unsigned int vy_orange = 1; //"positive direction"

	unsigned int x_pink = 100;
	unsigned int y_pink = 435;
	unsigned int calcx_pink = 435;
	unsigned int calcy_pink = 435;
	unsigned int vx_pink = 1; //"positive direction"
	unsigned int vy_pink = 1; //"positive direction"

	unsigned int x_pacman = 435;
	unsigned int y_pacman = 435;
	unsigned int calcx_pacman = 435;
	unsigned int calcy_pacman = 435;
	unsigned int vx_pacman = 1; //"positive direction"
	unsigned int vy_pacman = 1; //"positive direction"

	unsigned int sprite_cycle = 1;
	unsigned int sprite_cycle_select = 1;
	unsigned int sprite_cycle_red = 1;
	unsigned int sprite_cycle_cyan = 2;
	unsigned int sprite_cycle_pacman = 1;
	unsigned int scnt = 0;
	unsigned int pacplus = 0;

	const int sprite_timer = 60; //smaller value will make animation go faster
	
	fd=open("/dev/mem", O_RDWR|O_SYNC);
	if(fd<0){
		printf("Can't open memory\n");
		return -1;
	}
	base=mmap(NULL, REG_SPAN, PROT_READ|PROT_WRITE, MAP_SHARED, fd, REG_BASE);
	if(base==MAP_FAILED){
		printf("Can't map to memory\n");
		close(fd);
		return -1;
	}
	
	blank=(uint16_t*)(base+DE10_VGA_RASTER_0_BASE+VGA_BLANK);

	ready_red=(uint16_t*)(base+DE10_VGA_RASTER_0_BASE+VGA_RDY_POS_red);
	readx_red=(uint16_t*)(base+DE10_VGA_RASTER_0_BASE+VGA_RDX_POS_red);
	writey_red=(uint16_t*)(base+DE10_VGA_RASTER_0_BASE+VGA_WRY_POS_red);
	writex_red=(uint16_t*)(base+DE10_VGA_RASTER_0_BASE+VGA_WRX_POS_red);

	ready_cyan=(uint16_t*)(base+DE10_VGA_RASTER_0_BASE+VGA_RDY_POS_cyan);
	readx_cyan=(uint16_t*)(base+DE10_VGA_RASTER_0_BASE+VGA_RDX_POS_cyan);
	writey_cyan=(uint16_t*)(base+DE10_VGA_RASTER_0_BASE+VGA_WRY_POS_cyan);
	writex_cyan=(uint16_t*)(base+DE10_VGA_RASTER_0_BASE+VGA_WRX_POS_cyan);

	ready_orange=(uint16_t*)(base+DE10_VGA_RASTER_0_BASE+VGA_RDY_POS_orange);
	readx_orange=(uint16_t*)(base+DE10_VGA_RASTER_0_BASE+VGA_RDX_POS_orange);
	writey_orange=(uint16_t*)(base+DE10_VGA_RASTER_0_BASE+VGA_WRY_POS_orange);
	writex_orange=(uint16_t*)(base+DE10_VGA_RASTER_0_BASE+VGA_WRX_POS_orange);

	ready_pink=(uint16_t*)(base+DE10_VGA_RASTER_0_BASE+VGA_RDY_POS_pink);
	readx_pink=(uint16_t*)(base+DE10_VGA_RASTER_0_BASE+VGA_RDX_POS_pink);
	writey_pink=(uint16_t*)(base+DE10_VGA_RASTER_0_BASE+VGA_WRY_POS_pink);
	writex_pink=(uint16_t*)(base+DE10_VGA_RASTER_0_BASE+VGA_WRX_POS_pink);

	ready_pacman=(uint16_t*)(base+DE10_VGA_RASTER_0_BASE+VGA_RDY_POS_pacman);
	readx_pacman=(uint16_t*)(base+DE10_VGA_RASTER_0_BASE+VGA_RDX_POS_pacman);
	writey_pacman=(uint16_t*)(base+DE10_VGA_RASTER_0_BASE+VGA_WRY_POS_pacman);
	writex_pacman=(uint16_t*)(base+DE10_VGA_RASTER_0_BASE+VGA_WRX_POS_pacman);

	sprite_select_red=(uint16_t*)(base+DE10_VGA_RASTER_0_BASE+VGA_SPRITES_red);
	sprite_select_cyan=(uint16_t*)(base+DE10_VGA_RASTER_0_BASE+VGA_SPRITES_cyan);
	sprite_select_orange=(uint16_t*)(base+DE10_VGA_RASTER_0_BASE+VGA_SPRITES_orange);
	sprite_select_pink=(uint16_t*)(base+DE10_VGA_RASTER_0_BASE+VGA_SPRITES_pink);
	sprite_select_pacman=(uint16_t*)(base+DE10_VGA_RASTER_0_BASE+VGA_SPRITES_pacman);

	key0=(uint32_t*)(base+KEY0_BASE);
	key1=(uint32_t*)(base+KEY1_BASE);
	key2=(uint32_t*)(base+KEY2_BASE);
	key3=(uint32_t*)(base+KEY3_BASE);

	
	signal(SIGINT, handler); //handles crtl+c
	*writex_red = x_red;
	*writey_red = y_red;
	*sprite_select_red = 1;

	*writex_cyan = x_cyan;
	*writey_cyan = y_cyan;
	*sprite_select_cyan = 1;

	*writex_orange = x_orange;
	*writey_orange = y_orange;
	*sprite_select_orange = 1;

	*writex_pink = x_pink;
	*writey_pink = y_pink;
	*sprite_select_pink= 1;

	*writex_pacman = x_pacman;
	*writey_pacman = y_pacman;
	*sprite_select_pacman= 1;

	*key0 = 0x1; //up
	*key1 = 0x1; //down
	*key2 = 0x1; //right
	*key3 = 0x1; //left
	int p = 1;
	
	for(;;){
		usleep(5000);
	
			// printf("%d", sprite_cycle);
			// printf("\n");
			// usleep(1000);

				
		while(!is_blank){
			is_blank = *blank;

			if((y_red < (TOP_EDGE+RADIUS)) | (y_red > (BOTTOM_EDGE-RADIUS))){
				y_red = TOP_EDGE+RADIUS;
			}
			if((x_red < (LEFT_EDGE+RADIUS)) | (x_red > (RIGHT_EDGE-RADIUS))){
				x_red = LEFT_EDGE+RADIUS;
			}

			if((y_cyan < (TOP_EDGE+RADIUS)) | (y_cyan > (BOTTOM_EDGE-RADIUS))){
				y_cyan = TOP_EDGE+RADIUS;
			}
			if((x_cyan < (LEFT_EDGE+RADIUS)) | (x_cyan > (RIGHT_EDGE-RADIUS))){
				x_cyan = LEFT_EDGE+RADIUS;
			}

			if((y_orange < (TOP_EDGE+RADIUS)) | (y_orange > (BOTTOM_EDGE-RADIUS))){
				y_orange = TOP_EDGE+RADIUS;
			}
			if((x_orange < (LEFT_EDGE+RADIUS)) | (x_orange > (RIGHT_EDGE-RADIUS))){
				x_orange = LEFT_EDGE+RADIUS;	
			}
			if((y_pink < (TOP_EDGE+RADIUS)) | (y_pink > (BOTTOM_EDGE-RADIUS))){
				y_pink = TOP_EDGE+RADIUS;
			}
			if((x_pink < (LEFT_EDGE+RADIUS)) | (x_pink > (RIGHT_EDGE-RADIUS))){
				x_pink = LEFT_EDGE+RADIUS;	
			}

			if((y_pacman < (TOP_EDGE+RADIUS)) | (y_pacman > (BOTTOM_EDGE-RADIUS))){
				y_pacman = TOP_EDGE+RADIUS;
			}
			if((x_pacman < (LEFT_EDGE+RADIUS)) | (x_pacman > (RIGHT_EDGE-RADIUS))){
				x_pacman = LEFT_EDGE+RADIUS;	
			}						
			printf("Not blanked\n");
		}

		//detail and handle boundary conditions
		if((y_red < (TOP_EDGE+RADIUS)) | (y_red > (BOTTOM_EDGE-RADIUS))){
			vy_red=-vy_red;
		}
		if((x_red < (LEFT_EDGE+RADIUS)) | (x_red > (RIGHT_EDGE-RADIUS))){
			vx_red=-vx_red;
		}

		if((y_cyan < (TOP_EDGE+RADIUS)) | (y_cyan > (BOTTOM_EDGE-RADIUS))){
			vy_cyan=-vy_cyan;
		}
		if((x_cyan < (LEFT_EDGE+RADIUS)) | (x_cyan > (RIGHT_EDGE-RADIUS))){
			vx_cyan=-vx_cyan;
		}

		if((y_orange < (TOP_EDGE+RADIUS)) | (y_orange > (BOTTOM_EDGE-RADIUS))){
			vy_orange=-vy_orange;
		}
		if((x_orange < (LEFT_EDGE+RADIUS)) | (x_orange > (RIGHT_EDGE-RADIUS))){
			vx_orange=-vx_orange;
		}

		if((y_pink < (TOP_EDGE+RADIUS)) | (y_pink > (BOTTOM_EDGE-RADIUS))){
			vy_pink=-vy_pink;
		}
		if((x_pink < (LEFT_EDGE+RADIUS)) | (x_pink > (RIGHT_EDGE-RADIUS))){
			vx_pink=-vx_pink;		
		}

		if((y_pacman < (TOP_EDGE+RADIUS)) | (y_pacman > (BOTTOM_EDGE-RADIUS))){
			vy_pacman=-vy_pacman;
		}
		if((x_pacman < (LEFT_EDGE+RADIUS)) | (x_pacman > (RIGHT_EDGE-RADIUS))){
			vx_pacman=-vx_pacman;		
		}
		
		//update x and y position of red ghost
		// x_red = x_red + vx_red;
		// y_red = y_red + vy_red;
		// usleep(100);
		// *writex_red = x_red;
		// usleep(100);
		// *writey_red = y_red;

	// if (ghost_time % 10 == 9) {

	// 	int p = randomfunc();
	// 	int dir_int = p;
    // }
	int p = randomfunc();
	
	if(p == 1){
		if(y_red > (TOP_EDGE+RADIUS)){
			y_red = y_red - 1;
			usleep(100);
			*writey_red = y_red;
		}
		else{
			p = 2;
		}
	}
	
    if(p == 2){
		if(y_red < (BOTTOM_EDGE-RADIUS)){
        	y_red = y_red + 1;
			usleep(100);
			*writey_red = y_red;
		}
		else {
			p = 1;
		}
	}

	
    if(p == 3){
		if(x_red != (RIGHT_EDGE-RADIUS)){
			x_red = x_red + 1;
			usleep(100);
			*writex_red = x_red;
			}
		else {
			p = 4;
		}	
	}
	if(p == 4){	
		if(x_red != (LEFT_EDGE+RADIUS)) {   
       	 	x_red = x_red - 1;
			usleep(100);
			*writex_red = x_red;
		}
		else {
			p = 3;
		}
	}
		//update x and y position of cyan ghost
		x_cyan = x_cyan + vx_cyan;
		y_cyan = y_cyan + vy_cyan;
		usleep(100);
		*writex_cyan = x_cyan; 
		usleep(100);
		*writey_cyan = y_cyan;
		//update x and y position of orange ghost
		x_orange = x_orange + vx_orange;
		y_orange = y_orange + vy_orange;
		usleep(100);
		*writex_orange = x_orange;
		usleep(100);
		*writey_orange = y_orange;
		//update x and y position of pink ghost
		x_pink = x_pink + vx_pink;
		y_pink = y_pink + vy_pink;
		usleep(100);
		*writex_pink = x_pink;
		usleep(100);
		*writey_pink = y_pink;


		//pacman movement from user input
		if(*key0 == 0){ //up
			y_pacman = y_pacman + 1;
			usleep(100);
			*writey_pacman = y_pacman;
			sprite_cycle_pacman = 5;
			*sprite_select_pacman = sprite_cycle_pacman;
		}
		if(*key1 == 0){ //down
			sprite_cycle_pacman = 4;
			*sprite_select_pacman = sprite_cycle_pacman;
			y_pacman= y_pacman - 1;
			usleep(100);
			*writey_pacman = y_pacman;-
		}
		if(*key2 == 0){//right
			sprite_cycle_pacman = 1;
			*sprite_select_pacman = sprite_cycle_pacman;
			x_pacman = x_pacman + 1;
			usleep(100);
			*writex_pacman = x_pacman; 
		}
		if(*key3 == 0){//left
			sprite_cycle_pacman = 3;
			*sprite_select_pacman = sprite_cycle_pacman;
			x_pacman = x_pacman - 1;
			usleep(100);
			*writex_pacman = x_pacman;
		}

		// this will change the sprite based off of the which_spr 
		// with/select condition written in vhdl (815)
			if (scnt >= sprite_timer){
				scnt = 0;
				if (sprite_cycle == 1){
					sprite_cycle = 2;
				}
				else{
					sprite_cycle = 1;
					sprite_cycle_pacman = 2; //closed pacman
				}			
			}
				scnt++;
				*sprite_select_red = sprite_cycle;
				*sprite_select_cyan = sprite_cycle;
				*sprite_select_orange = sprite_cycle;
				*sprite_select_pink = sprite_cycle;
				*sprite_select_pacman = sprite_cycle_pacman;
		

		
	}
}

int randomfunc () {

   time_t t;
   srand((unsigned) time(&t));
      int x = (rand() % 4) + 1;
      printf("%d\n", x);
   return x;
}
			
