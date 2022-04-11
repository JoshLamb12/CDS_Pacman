all:
	arm-linux-gnueabihf-gcc -Dsoc_cv_av -O2 -o pacman pacman.c
	arm-linux-gnueabihf-strip -s pacman
	
clean:
	rm -rf pacman