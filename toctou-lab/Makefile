CC      = gcc
CFLAGS  = -Wall -Wextra -O2

all: helper attacker

helper: helper.c
	$(CC) $(CFLAGS) -o $@ $<

attacker: attacker.c
	$(CC) $(CFLAGS) -o $@ $<

clean:
	rm -f helper attacker
