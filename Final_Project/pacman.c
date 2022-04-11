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
#define VGA_RDY_POS 2
#define VGA_RDX_POS 4
#define VGA_WRY_POS 6
#define VGA_WRX_POS 8
#define VGA_SPRITES 10

// radius of circle
#define RADIUS 15
// HTOTAL - HFRONT_PORCH - HACTIVE
#define LEFT_EDGE 144
// HTOTAL - HFRONT_PORCH
#define RIGHT_EDGE 774
// VTOTAL - VFRONT_PORCH - VACTIVE
#define TOP_EDGE 35
// VTOTAL - VFRONT_PORCH
#define BOTTOM_EDGE 515


void *base;
uint16_t *blank;
uint16_t *ready;
uint16_t *readx;
uint16_t *writey;
uint16_t *writex;
uint16_t *sprite_select;
uint32_t *key;
int fd;

void handler(int signo){
	// *hex0=0;
	// *hex1=0;
	// *hex2=0;
	// *hex3=0;
	// *hex4=0;
	// *hex5=0;
	*blank=0;
	munmap(base, REG_SPAN);
	close(fd);
	exit(0);
}

int main(){
	int i = 0;
	unsigned int is_blank = 0;
	unsigned int x = 435;
	unsigned int y = 435;
	unsigned int calcx = 435;
	unsigned int calcy = 435;
	unsigned int vx = 1; //"positive direction"
	unsigned int vy = 1; //"positive direction"
	unsigned int sprite_cycle = 1;
	unsigned int scnt = 0;
	const int sprite_timer = 500;
	
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
	ready=(uint16_t*)(base+DE10_VGA_RASTER_0_BASE+VGA_RDY_POS);
	readx=(uint16_t*)(base+DE10_VGA_RASTER_0_BASE+VGA_RDX_POS);
	writey=(uint16_t*)(base+DE10_VGA_RASTER_0_BASE+VGA_WRY_POS);
	writex=(uint16_t*)(base+DE10_VGA_RASTER_0_BASE+VGA_WRX_POS);
	sprite_select=(uint16_t*)(base+DE10_VGA_RASTER_0_BASE+VGA_SPRITES);
	key=(uint32_t*)(base+KEY_BASE);
	
	signal(SIGINT, handler); //handles crtl+c
	*writex = x;
	*writey = y;
	*sprite_select = 4;
	*key = 0x0;
	for(;;){
		usleep(5000);
		
		/*//update sprite selection
		*sprite_select = sprite_cycle;
		sprite_cycle = sprite_cycle + 1;
		printf("Which sprite: %u\n", (sprite_cycle));*/
		
		while(!is_blank){
			is_blank = *blank;
			x = *readx;
			y = *ready;
			if((y < (TOP_EDGE+RADIUS)) | (y > (BOTTOM_EDGE-RADIUS))){
				y = TOP_EDGE+RADIUS;
			}
			if((x < (LEFT_EDGE+RADIUS)) | (x > (RIGHT_EDGE-RADIUS))){
				x = LEFT_EDGE+RADIUS;
			}			
			printf("Not blanked\n");
		}
		
		//detail and handle boundary conditions
		if((y < (TOP_EDGE+RADIUS)) | (y > (BOTTOM_EDGE-RADIUS))){
			vy=-vy;
		}
		if((x < (LEFT_EDGE+RADIUS)) | (x > (RIGHT_EDGE-RADIUS))){
			vx=-vx;
		}
		//update x and y position
		
		x = x + vx;
		y = y + vy;

		usleep(100);
		while (*key == 1)
		{
		*writex = x;
		usleep(100);
		*writey = y;
		}
		/*
		*writex = LEFT_EDGE;
		*writey = TOP_EDGE;
		*/
		// this will change the sprite based off of the which_spr with/select condition written in vhdl (484)
		if (scnt >= sprite_timer){
			scnt = 0;
			if (sprite_cycle == 1){
				sprite_cycle = 2;
			}else if (sprite_cycle == 2){
				sprite_cycle = 3;
			}else if (sprite_cycle == 3){
				sprite_cycle = 4;
			}else if (sprite_cycle == 4){
				sprite_cycle = 5;
			}else if (sprite_cycle == 5){
				sprite_cycle = 6; 
			}else if (sprite_cycle == 6){
				sprite_cycle = 7;
			}else if (sprite_cycle == 7){
				sprite_cycle = 8;
			}else if (sprite_cycle == 8){
				sprite_cycle = 9;
			}else if (sprite_cycle == 9){
				sprite_cycle = 10;
			}else if (sprite_cycle == 10){
				sprite_cycle = 11; 
			}else if (sprite_cycle == 11){
				sprite_cycle = 12;
			}else if (sprite_cycle == 12){
				sprite_cycle = 13; //no actual sprite ROM at this address. should get default ROM reading behavior (black)
			}else{
				sprite_cycle = 1;
			}			
			
		}
		scnt++; 
		*sprite_select = sprite_cycle;
		
	}
}