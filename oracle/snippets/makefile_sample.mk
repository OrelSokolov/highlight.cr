# Сборка проекта
CC = gcc
CFLAGS = -Wall -O2 -std=c11
TARGET = app
SRC = $(wildcard src/*.c)
OBJ = $(SRC:.c=.o)
VPATH = src:lib

.PHONY: all clean dist

all: $(TARGET)

$(TARGET): $(OBJ)
	$(CC) $(CFLAGS) -o $@ $^ -lm

%.o: %.c config.h
	$(CC) $(CFLAGS) -c $< -o $@

src/%.o: private CFLAGS += -DDEBUG

clean:
	rm -f $(OBJ) $(TARGET)

dist: all
	tar czf app.tar.gz $(TARGET)

install: all
	install -m 0755 $(TARGET) /usr/local/bin

test: CFLAGS += -DTESTING
test: all
	./$(TARGET) --selftest

-include $(OBJ:.o=.d)

ifeq ($(OS), Windows_NT)
EXE = .exe
endif
