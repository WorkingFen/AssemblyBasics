CC=gcc
ASMBIN=nasm

all: asm cc link
asm:
	$(ASMBIN) -o func.o -f elf func.asm
cc:
	$(CC) -m32 -c main.c
link:
	$(CC) -m32 main.o func.o -o chanS -B/usr/lib32
clean:
	rm *.o
	rm chanS