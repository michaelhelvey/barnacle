all: kernel.img

clean:
	rm -f *.o
	rm -f *.img
	rm -f *.macho

kernel.img: linker.ld main.o
	aarch64-elf-ld -T linker.ld -o main.macho main.o
	aarch64-elf-objcopy main.macho -O binary kernel.img

main.o: main.s
	aarch64-elf-as -D -o main.o main.s
