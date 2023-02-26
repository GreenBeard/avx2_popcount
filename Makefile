bin/avx2_popcount: build/main.o build/popcount.o
	mkdir -p bin
	gcc $^ -o $@

build/popcount.o: src/popcount.S
	mkdir -p build
	nasm -g -f elf64 -w+all $< -o $@

build/main.o: src/main.c
	mkdir -p build
	gcc -g -std=c99 -D_POSIX_C_SOURCE=200112L -Wall -pedantic -O3 -c $< -o $@

clean:
	rm -rf build bin

.SUFFIXES:
