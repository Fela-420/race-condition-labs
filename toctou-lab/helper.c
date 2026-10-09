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

    // Widen the race window for demonstration.
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
