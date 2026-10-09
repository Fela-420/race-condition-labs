# TOCTOU (Time-of-Check to Time-of-Use) Lab

This lab demonstrates a classic filesystem TOCTOU race condition. It shows how a privileged program can be tricked into reading a sensitive file by swapping a symlink between the permission check (access()) and the actual file open (open()).

## The Vulnerability

The vulnerable helper program is setuid-root. It performs a check-then-use pattern:

    if (access(path, R_OK) == 0) { // Check
        usleep(1000);              // Window for race
        fd = open(path, O_RDONLY); // Use
    }

- access() checks permissions using the real UID of the user (you).
- open() opens the file using the effective UID of the process (root, due to setuid).

An attacker can exploit this by continuously swapping a symlink (target) between a harmless file (safe.txt) and a root-only file (secret.txt). If the swap happens during the usleep window, access() approves the harmless file, but open() resolves the symlink to the sensitive file, successfully reading it as root.

## Prerequisites

- A Linux environment (Kali Linux, Ubuntu, etc.)
- gcc installed
- sudo privileges (to set the setuid bit and change file ownership)
- strace (optional, for verification)

## Setup Instructions

Clone the repository and navigate to the lab directory:

    git clone https://github.com/Fela-420/race-condition-labs.git
    cd race-condition-labs/toctou-lab

Compile the binaries and set up the required files:

    # 1. Compile the helper and attacker
    make

    # 2. Create the target files
    echo "SAFE_DATA" > safe.txt
    echo "SECRET_DATA" > secret.txt

    # 3. Make secret.txt readable ONLY by root
    sudo chown root:root secret.txt
    sudo chmod 600 secret.txt

    # 4. Make the helper setuid-root
    sudo chown root:root helper
    sudo chmod u+s helper

Verify the permissions:

    ls -l helper safe.txt secret.txt

You should see that helper has an s in its permissions (-rwsr-xr-x), and secret.txt is owned by root (-rw-------).

## Running the Exploit

Run the attacker. It loops 2000 times, swapping the target symlink and invoking the helper:

    ./attacker | grep SECRET

## Understanding the Output

Because this is a race condition, the output will be noisy. Here is what the different messages mean:

- **SECRET_DATA:** Success. The race hit perfectly. The helper checked safe.txt but opened secret.txt.
- **access: Permission denied:** The attacker swapped the symlink to secret.txt before the helper ran access(). Since you don't have read permission on secret.txt, access() correctly denied it.
- **access: No such file or directory:** The attacker was in the middle of unlinking and recreating the symlink when the helper called access().
- **open: No such file or directory:** The symlink was deleted right after access() succeeded, so open() failed.

If you don't see SECRET_DATA, run the command again. You can also widen the race window by changing usleep(1000); to usleep(10000); in helper.c, running make, and trying again.

## Verification with strace

To see the kernel resolving the path differently, open two terminals.

**Terminal 1 (The Swapper):**

    while true; do
        ln -sf safe.txt target
        ln -sf secret.txt target
    done

**Terminal 2 (The Tracer):**

    sudo strace -f -y -e trace=openat,access ./helper target

In the strace output, you will see the access() call succeed, followed by an openat() call that resolves target to secret.txt:

    access("target", R_OK) = 0
    openat(AT_FDCWD, "target", O_RDONLY) = 3</tmp/toctou-lab/secret.txt>

## The Fix

To fix this vulnerability, modify helper.c to prevent following symlinks on the final component. Change the open() call to include O_NOFOLLOW:

    // Vulnerable:
    int fd = open(path, O_RDONLY);

    // Fixed:
    int fd = open(path, O_RDONLY | O_NOFOLLOW);

Recompile (make), reset the setuid bit (sudo chmod u+s helper), and run the attacker again. You should no longer see SECRET_DATA. Instead, you will see open: Too many levels of symbolic links.

## Alternative Fixes

- Use openat2() with RESOLVE_NO_SYMLINKS (Linux 5.6+).
- Open the file first, then use fstat() to verify it is the expected file, rather than checking before opening.

## Cleanup

When you are done, remove the setuid binary to prevent security risks:

    sudo rm helper
