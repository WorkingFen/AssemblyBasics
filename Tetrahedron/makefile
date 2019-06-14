CC = gcc
CFLAGS = -Wall -m64
ASMBIN = nasm

all: main.o tetra.o
	$(CC) $(CFLAGS) -o tetrahedron main.o tetra.o `allegro-config --shared` -lm

tetra.o: tetra.asm
	$(ASMBIN) -f elf64 -o tetra.o tetra.asm

main.o: main.c tetra.h
	$(CC) $(CFLAGS) -c -o main.o main.c

clean:
	rm -f *.o tetrahedron

