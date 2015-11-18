# ************************************************************************* #
# Organizacion del Computador II                                            #
#                                                                           #
#   Trabajo Practico 2                                                      #
#                                                                           #
# ************************************************************************* #

all: clean makes tp2

CFLAGS=-Wall -Wextra -pedantic -O0 -ggdb -lm -std=c99
CFLAGS3=-Wall -Wextra -pedantic -O3 -ggdb -lm -std=c99

makes:
	make -C bmp
	make -C tools
	make -C filters

%.o: %.c run.h 
	gcc $(CFLAGS) -c -o $@ $<
	
tp2: run.o tp2.o runtest.o tests.o makes
	gcc $(CFLAGS) tp2.o run.o filters/*.o bmp/*.o -o tp2 -lm
	gcc $(CFLAGS) tests.o runtest.o filters/*.o bmp/*.o -o runtestO0 -lm
	gcc $(CFLAGS3) -w tests.c -c -o tests.o 
	gcc $(CFLAGS3) -w runtest.c -c -o runtest.o
	gcc $(CFLAGS3) -w filters/aux.c -c -o filters/aux.o 
	gcc $(CFLAGS3) -w filters/C_blur.c -c -o filters/C_blur.o 
	gcc $(CFLAGS3) -w filters/C_hsl.c -c -o filters/C_hsl.o 
	gcc $(CFLAGS3) -w filters/C_merge.c -c -o filters/C_merge.o 
	gcc $(CFLAGS3) tests.o runtest.o filters/*.o bmp/*.o -o runtestO3 -lm
	cp tp2 ../bin/
	cp runtestO0 ../Testing/
	cp runtestO3 ../Testing/

clean:
	make -C bmp clean
	make -C tools clean
	make -C filters clean
	rm  -f *.o tp2