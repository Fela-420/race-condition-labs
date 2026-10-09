# TOCTOU (Time-of-Check to Time-of-Use) Lab

This lab demonstrates a classic Filesystem TOCTOU (Time-of-Check to Time-of-Use) race condition. It highlights how a privileged program can be tricked into reading a sensitive file by swapping a symlink between the permission check (`access()`) and the actual file open (`open()`).

## The Vulnerability

The vulnerable helper program is setuid-root. It performs a check-then-use pattern:

```c
if (access(path, R_OK) == 0) { // Check
    usleep(1000);              // Window for race
    fd = open(path, O_RDONLY); // Use
}
