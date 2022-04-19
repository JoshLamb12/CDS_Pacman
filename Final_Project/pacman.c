#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <fcntl.h>
#include <signal.h>
#include <sys/mman.h>
#include "hps_0.h"

#define REG_BASE 0xff200000 //LW H2F Bride Base Address
#define REG_SPAN 0x00200000 //LW H2F Bridge Span

#define VGA_BLANK 0

#define VGA_RDY_POS_map 22
#define VGA_RDX_POS_map 24

#define VGA_RDY_POS_red 2
#define VGA_RDX_POS_red 4
#define VGA_WRY_POS_red 10
#define VGA_WRX_POS_red 12

#define VGA_RDY_POS_cyan 6
#define VGA_RDX_POS_cyan 8
#define VGA_WRY_POS_cyan 16
#define VGA_WRX_POS_cyan 18

#define VGA_SPRITES_red 14
#define VGA_SPRITES_cyan 20

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

uint16_t *sprite_select;
uint16_t *sprite_select_red;
uint16_t *sprite_select_cyan;

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
	unsigned int is_blank = 0;
	unsigned int x_red = 435;
	unsigned int y_red = 100;
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

	unsigned int sprite_cycle = 1;
	unsigned int sprite_cycle_select = 1;
	unsigned int sprite_cycle_red = 1;
	unsigned int sprite_cycle_cyan = 2;
	unsigned int scnt = 0;
	const int sprite_timer = 25;
	
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

	sprite_select_red=(uint16_t*)(base+DE10_VGA_RASTER_0_BASE+VGA_SPRITES_red);
	sprite_select_cyan=(uint16_t*)(base+DE10_VGA_RASTER_0_BASE+VGA_SPRITES_cyan);


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

	*key0 = 0x1; //up
	*key1 = 0x1; //down
	*key2 = 0x1; //right
	*key3 = 0x1; //left

	
	for(;;){
		usleep(5000);
	
			// printf("%d", sprite_cycle);
			// printf("\n");
			// usleep(1000);
		
		while(!is_blank){
			is_blank = *blank;
			// x_red = *readx_red;
			// y_red = *ready_red;

			// x_cyan = *readx_cyan;
			// y_cyan = *ready_cyan;

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

		//update x and y position 
	



		if(*key0 == 0){
		y_red = y_red + 1;

		usleep(100);
		*writey_red = y_red;}

		if(*key1 == 0){
		y_red = y_red - 1;

		usleep(100);
		*writey_red = y_red;}

		if(*key2 == 0){
		x_red = x_red + 1;

		usleep(100);
		*writex_red = x_red;}

		if(*key3 == 0){
		x_red = x_red - 1;

		usleep(100);
		*writex_red = x_red;}





		// if(*key2 == 0){
		// x_cyan = x_cyan + 1;
		// y_cyan = y_cyan + 1;
		// *writex_cyan = x_cyan;
		// usleep(100);
		// *writey_cyan = y_cyan;
		// }

		// if(*key3 == 0){
		// x_cyan = x_cyan - 1;
		// y_cyan = y_cyan - 1;
		// *writex_cyan = x_cyan;
		// usleep(100);
		// *writey_cyan = y_cyan;
		// }

		// this will change the sprite based off of the which_spr 
		// with/select condition written in vhdl (583)
			if (scnt >= sprite_timer){
				scnt = 0;
				if (sprite_cycle == 1){
					sprite_cycle = 2;
				}else{
					sprite_cycle = 1;
				}			
			}
				scnt++;
				*sprite_select_red = sprite_cycle;
				*sprite_select_cyan = sprite_cycle;
		
	}
	
}