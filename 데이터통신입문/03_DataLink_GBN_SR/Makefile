# gcc 또는 clang (C99). Windows는 MinGW의 mingw32-make 로도 됩니다.
CC     ?= gcc
CFLAGS ?= -std=c99 -O2 -Wall -Wextra
SRC     = main.c sim.c channel.c go_back_n.c selective_repeat.c experiments.c

datalink: $(SRC) protocol.h sim.h
	$(CC) $(CFLAGS) -o $@ $(SRC)

test: datalink
	./datalink test

clean:
	rm -f datalink datalink.exe

.PHONY: test clean
