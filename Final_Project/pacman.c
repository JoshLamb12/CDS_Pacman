#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <fcntl.h>
#include <signal.h>
#include <sys/mman.h>
#include "hps_0.h"
#include <time.h>
#include "control_array_header.h"    //control_array (y,x) y is 0 to 479 long, x is 0 to 639. 0 is background, else boundary pixel (blue (1) or pink(2))

#define one_second 1000000

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
#define RADIUS 13
// HTOTAL - HFRONT_PORCH - HACTIVE
#define LEFT_EDGE 144
// HTOTAL - HFRONT_PORCH
#define RIGHT_EDGE 770
// VTOTAL - VFRONT_PORCH - VACTIVE
#define TOP_EDGE 30
// VTOTAL - VFRONT_PORCH
#define BOTTOM_EDGE 495
//map boundaries
#define LEFT_WALL 230+100

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
uint32_t *sw0;

int fd;
int p[4] = {4,4,4,4};
int pacman_position;
int runLoop = 0;


void handler(int signo) {
    *key0 = 0x0; //up
    *key1 = 0x0; //down
    *key2 = 0x0; //right
    *key3 = 0x0; //left
    *blank=0;
    munmap(base, REG_SPAN);
    close(fd);
    exit(0);
}

int main() {
    int i = 0;
    int ghost_time = 0;
    unsigned int is_blank = 0;

    unsigned int x_red = 390+35;
    unsigned int y_red = 176+144;

    unsigned int x_cyan = 267+35;
    unsigned int y_cyan = 176+144;

    unsigned int x_orange = 325+35;
    unsigned int y_orange = 176+144;

    unsigned int x_pink = 325+35;
    unsigned int y_pink = 227 + 144;

    unsigned int x_pacman = 300;
    unsigned int y_pacman = 400;

    unsigned int sprite_cycle = 1;
    unsigned int sprite_cycle_select = 1;
    unsigned int sprite_cycle_red = 1;
    unsigned int sprite_cycle_cyan = 2;
    unsigned int sprite_cycle_pacman = 1;
    unsigned int scnt = 0; //for ghost animation switch
    unsigned int pacplus = 0; //for pacman animation switch

    const int sprite_timer = 40; //smaller value will make animation on ghost and pacman go faster

    int edgeDir;
    int whichLoop;
    int loopFlag = 0;

    //control_array (y,x) y is 0 to 479 long, x is 0 to 639. 0 is background, else boundary pixel (blue (1) or pink(2))
	

    fd=open("/dev/mem", O_RDWR|O_SYNC);
    if(fd<0) {
        printf("Can't open memory\n");
        return -1;
    }
    base=mmap(NULL, REG_SPAN, PROT_READ|PROT_WRITE, MAP_SHARED, fd, REG_BASE);
    if(base==MAP_FAILED) {
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
    sw0=(uint32_t*)(base+SW0_BASE);

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
    *sprite_select_pink = 1;

    *writex_pacman = x_pacman;
    *writey_pacman = y_pacman;
    *sprite_select_pacman = 1;

    *key0 = 0x1; //up
    *key1 = 0x1; //down
    *key2 = 0x1; //right
    *key3 = 0x1; //left
    *sw0 = 0x1; //for scared ghost testing
    
    usleep(one_second); //wait 3 seconds upon starting program

    for(;;) {
        usleep(5000);
        while(!is_blank) {
            is_blank = *blank;

            if((y_red < (TOP_EDGE+RADIUS)) | (y_red > (BOTTOM_EDGE-RADIUS))) {
                y_red = TOP_EDGE+RADIUS;
            }
            if((x_red < (LEFT_EDGE+RADIUS)) | (x_red > (RIGHT_EDGE-RADIUS))) {
                x_red = LEFT_EDGE+RADIUS;
            }

            if((y_cyan < (TOP_EDGE+RADIUS)) | (y_cyan > (BOTTOM_EDGE-RADIUS))) {
                y_cyan = TOP_EDGE+RADIUS;
            }
            if((x_cyan < (LEFT_EDGE+RADIUS)) | (x_cyan > (RIGHT_EDGE-RADIUS))) {
                x_cyan = LEFT_EDGE+RADIUS;
            }

            if((y_orange < (TOP_EDGE+RADIUS)) | (y_orange > (BOTTOM_EDGE-RADIUS))) {
                y_orange = TOP_EDGE+RADIUS;
            }
            if((x_orange < (LEFT_EDGE+RADIUS)) | (x_orange > (RIGHT_EDGE-RADIUS))) {
                x_orange = LEFT_EDGE+RADIUS;
            }
            if((y_pink < (TOP_EDGE+RADIUS)) | (y_pink > (BOTTOM_EDGE-RADIUS))) {
                y_pink = TOP_EDGE+RADIUS;
            }
            if((x_pink < (LEFT_EDGE+RADIUS)) | (x_pink > (RIGHT_EDGE-RADIUS))) {
                x_pink = LEFT_EDGE+RADIUS;
            }

            if((y_pacman < (TOP_EDGE+RADIUS)) | (y_pacman > (BOTTOM_EDGE-RADIUS))) {
                y_pacman = TOP_EDGE+RADIUS;
            }
            if((x_pacman < (LEFT_EDGE+RADIUS)) | (x_pacman > (RIGHT_EDGE-RADIUS))) {
                x_pacman = LEFT_EDGE+RADIUS;
            }
            printf("Not blanked\n");
        }

        p[0] = randomfunc(0);
        p[1] = randomfunc(1);
        p[2] = randomfunc(2);
        p[3] = randomfunc(3);

        //red ghost movement (old)
        // if(p[0] == 1){
        // 	if(y_red >= (TOP_EDGE+RADIUS)){
        // 		y_red = y_red - 1;
        // 		usleep(100);
        // 		*writey_red = y_red;
        // 	}
        // 	else{
        // 		p[0] = 2;
        // 	}
        // }

        // if(p[0] == 2){
        // 	if(y_red <= (BOTTOM_EDGE-RADIUS)){
        //     	y_red = y_red + 1;
        // 		usleep(100);
        // 		*writey_red = y_red;
        // 	}
        // 	else {
        // 		p[0] = 1;
        // 	}
        // }


        // if(p[0] == 3){
        // 	if(x_red != (RIGHT_EDGE-RADIUS)){
        // 		x_red = x_red + 1;
        // 		usleep(100);
        // 		*writex_red = x_red;
        // 		}
        // 	else {
        // 		p[0] = 4;
        // 	}
        // }



        // if(p[0] == 4){
        // 	if(x_red != (LEFT_EDGE+RADIUS)) {
        //    	 	x_red = x_red - 1;
        // 		usleep(100);
        // 		*writex_red = x_red;
        // 	}
        // 	else {
        // 		p[0] = 3;
        // 	}
        // }


		//red ghost movement (new)
        if(y_red < (TOP_EDGE+RADIUS)) {
            edgeDir = 2;
            runLoop = 1;
            usleep(100);
        }
        if(y_red > (BOTTOM_EDGE-RADIUS)) {
            edgeDir = 1;
            runLoop = 1;
            usleep(100);
        }
        if(x_red > (RIGHT_EDGE-RADIUS)) {
            edgeDir = 4;
            runLoop = 1;
            usleep(100);
        }
        if(x_red < (LEFT_EDGE+RADIUS)) {
            edgeDir = 3;
            runLoop = 1;
            usleep(100);
        }

        if(runLoop == 0 || loopFlag == 0) {
            whichLoop = p[0];
            usleep(100);
        }
        else {
            whichLoop = edgeDir;
            loopFlag++;
            runLoop = 0;
            usleep(100);
        }

        if (loopFlag >= 50)  {
            loopFlag = 0;
            usleep(100);
        }

        switch(whichLoop) {

        case 1:
            y_red = y_red - 1;
            usleep(100);
            *writey_red = y_red;
            break;
        case 2:
            y_red = y_red + 1;
            usleep(100);
            *writey_red = y_red;
            break;
        case 3:
            x_red = x_red + 1;
            usleep(100);
            *writex_red = x_red;
            break;
        case 4:
            x_red = x_red - 1;
            usleep(100);
            *writex_red = x_red;
            break;
        default:
            y_red = y_red - 1;
            usleep(100);
            *writey_red = y_red;

        }


        //cyan ghost movement
        if(p[1] == 1) {
            if(y_cyan >= (TOP_EDGE+RADIUS)) {
                y_cyan = y_cyan - 1;
                usleep(100);
                *writey_cyan = y_cyan;
            }
            else {
                p[1] = 2;
            }
        }
        if(p[1] == 2) {
            if(y_cyan <= (BOTTOM_EDGE-RADIUS)) {
                y_cyan = y_cyan + 1;
                usleep(100);
                *writey_cyan = y_cyan;
            }
            else {
                p[1] = 1;
            }
        }
        if(p[1] == 3) {
            if(x_cyan != (RIGHT_EDGE-RADIUS)) {
                x_cyan = x_cyan + 1;
                usleep(100);
                *writex_cyan = x_cyan;
            }
            else {
                p[1] = 4;
            }
        }
        if(p[1] == 4) {
            if(x_cyan != (LEFT_EDGE+RADIUS)) {
                x_cyan = x_cyan - 1;
                usleep(100);
                *writex_cyan = x_cyan;
            }
            else {
                p[1] = 3;
            }
        }

		//orange ghost movement
        if(p[2] == 1) {
            if(y_orange >= (TOP_EDGE+RADIUS)) {
                y_orange = y_orange - 1;
                usleep(100);
                *writey_orange = y_orange;
            }
            else {
                p[2] = 2;
            }
        }
        if(p[2] == 2) {
            if(y_orange <= (BOTTOM_EDGE-RADIUS)) {
                y_orange = y_orange + 1;
                usleep(100);
                *writey_orange = y_orange;
            }
            else {
                p[2] = 1;
            }
        }
        if(p[2] == 3) {
            if(x_orange != (RIGHT_EDGE-RADIUS)) {
                x_orange = x_orange + 1;
                usleep(100);
                *writex_orange = x_orange;
            }
            else {
                p[2] = 4;
            }
        }
        if(p[2] == 4) {
            if(x_orange != (LEFT_EDGE+RADIUS)) {
                x_orange = x_orange - 1;
                usleep(100);
                *writex_orange = x_orange;
            }
            else {
                p[2] = 3;
            }
        }

        //pink ghost movement
        if(p[3] == 1) {
            if (control_array[y_pink-RADIUS][x_pink] == 0){
                y_pink = y_pink - 1;
                usleep(100);
                *writey_pink = y_pink;
            }
            else {
                p[3] = 2;
            }
        }
        if(p[3] == 2) {
              if (control_array[y_pink+RADIUS][x_pink] == 0){
                y_pink = y_pink + 1;
                usleep(100);
                *writey_pink = y_pink;
            }
            else {
                p[3] = 1;
            }
        }
        if(p[3] == 3) {
            //if(x_pink != (RIGHT_EDGE-RADIUS)) {
            if (control_array[y_pink][x_pink+RADIUS] == 0){
                x_pink = x_pink + 1;
                usleep(100);
                *writex_pink = x_pink;
            }
            else {
                p[3] = 4;
            }
        }
        if(p[3] == 4) {
             if (control_array[y_pink][x_pink-RADIUS] == 0){
                x_pink = x_pink - 1;
                usleep(100);
                *writex_pink = x_pink;
            }
            else {
                p[3] = 3;
            }
        }

        //pacman movement from user input
        if(*key0 == 0) { //up
            if (pacplus >= sprite_timer) {
                pacplus = 0;
                if (sprite_cycle_pacman == 5) {
                    sprite_cycle_pacman = 2;
                }
                else {
                    sprite_cycle_pacman = 5;
                }
            }
            pacplus++;
            *sprite_select_pacman = sprite_cycle_pacman;

            if(control_array[y_pacman+35][x_pacman+144] == 0) {
                y_pacman = y_pacman +1;
                usleep(100);
                *writey_pacman = y_pacman;
            }
            else {
                y_pacman = y_pacman;
                usleep(100);
                *writey_pacman = y_pacman;
            }
            // usleep(100);
            // *writey_pacman = y_pacman+1;

        }

        if(*key1 == 0 ) { //down

            if (pacplus >= sprite_timer) {
                pacplus = 0;
                if (sprite_cycle_pacman == 4) {
                    sprite_cycle_pacman = 2;
                }
                else {
                    sprite_cycle_pacman = 4;
                }
            }
            pacplus++;
            *sprite_select_pacman = sprite_cycle_pacman;

            if(control_array[y_pacman+35][x_pacman+144] == 0) {
                y_pacman = y_pacman - 1;
                usleep(100);
                *writey_pacman = y_pacman - 1;
            }
            else {
                y_pacman = y_pacman;
                usleep(100);
                *writey_pacman = y_pacman;
            }

            //y_pacman= y_pacman - 1;
            // usleep(100);
            // *writey_pacman = y_pacman - 1;

        }
        if(*key2 == 0) {//right

            if (pacplus >= sprite_timer) {
                pacplus = 0;
                if (sprite_cycle_pacman == 1) {
                    sprite_cycle_pacman = 2;
                }
                else {
                    sprite_cycle_pacman = 1;
                }
            }
            pacplus++;
            *sprite_select_pacman = sprite_cycle_pacman;
            if(control_array[y_pacman+35][x_pacman+144] == 0) {
                x_pacman = x_pacman + 1;
                usleep(100);
                *writex_pacman = x_pacman;

            }
            else {
                x_pacman = x_pacman;
                *writex_pacman = x_pacman;
            }
            // x_pacman = x_pacman + 1;
            // usleep(100);
            // *writex_pacman = x_pacman;
        }
        if(*key3 == 0) { //left

            if (pacplus >= sprite_timer) {
                pacplus = 0;
                if (sprite_cycle_pacman == 3) {
                    sprite_cycle_pacman = 2;
                }
                else {
                    sprite_cycle_pacman = 3;
                }
            }
            pacplus++;
            *sprite_select_pacman = sprite_cycle_pacman;

            if(control_array[y_pacman+35][x_pacman+144] == 0) {
                x_pacman = x_pacman - 1;
                usleep(100);
                *writex_pacman = x_pacman;

            }
            else {
                x_pacman = x_pacman ;
                usleep(100);
                *writex_pacman = x_pacman;
            }

            // x_pacman = x_pacman - 1;
            // usleep(100);
            // *writex_pacman = x_pacman;
        }

        // this will change the sprite based off of the which_spr
        // with/select condition written in vhdl (815)
        if (scnt >= sprite_timer) {
            scnt = 0;
            if (sprite_cycle == 1) {
                sprite_cycle = 2;
            }
            else {
                sprite_cycle = 1;
                //sprite_cycle_pacman = 2; //closed pacman
            }
        }
        scnt++;
        *sprite_select_red = sprite_cycle;
        *sprite_select_cyan = sprite_cycle;
        *sprite_select_orange = sprite_cycle;
        *sprite_select_pink = sprite_cycle;
        //*sprite_select_pacman = sprite_cycle_pacman;


    }
}


int randomfunc (int g) {

    time_t t;
    int n[ 4 ];
    int i,j;
    srand((unsigned) time(&t));
    for ( i = 0; i < 4; i++ ) {
        n[ i ] = ((rand() % 4) + 1);
    }
    /* Uncomment if want to see numbers */
    // for (j = 0; j < 4; j++ ) {
    //  printf("Element[%d] = %d\n", j, n[j] );
    return n[g];
}
