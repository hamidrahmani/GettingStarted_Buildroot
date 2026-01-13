# Name des Binaries
TARGET = greeting
CC = $(CROSS_COMPILE)gcc
CFLAGS = -Wall -O2

all: greeting

# Binary aus Objektdatei linken
greeting: greeting.o
	$(CC) $(CFLAGS) -o greeting greeting.o

# Objektdatei aus C-Datei kompilieren
greeting.o: greeting.c
	$(CC) $(CFLAGS) -c greeting.c -o greeting.o

# Aufräumen
clean:
	rm -f $(TARGET) *.o


