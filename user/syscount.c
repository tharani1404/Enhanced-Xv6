
#include "kernel/types.h"
#include "kernel/stat.h"
#include "kernel/fcntl.h"
#include "user/user.h"
char *syscallname(int mask) {
    int syscall_num = -1;
    while ((mask >>= 1) != 0)
        syscall_num++;

    char *syscalls[] = {
        "fork", "exit", "wait", "pipe", "read", "kill", "exec", "fstat", "chdir",
        "dup", "getpid", "sbrk", "sleep", "uptime", "open", "write", "mknod", "unlink", 
        "link", "mkdir", "close","waitx"
    };

    if (syscall_num >= 0 && syscall_num < sizeof(syscalls) / sizeof(syscalls[0])) {
        return syscalls[syscall_num];
    }
    return "unknown";
}



int main(int argc, char *argv[]) {
    if (argc < 3) {
        printf("Usage: syscount <mask> command [args]\n");
        exit(1);
    }

    int mask = atoi(argv[1]);
    int pid = fork();

    if (pid == 0) {
        exec(argv[2], &argv[2]);
        printf("Error: exec failed\n");
        exit(1);
    } else if (pid > 0) {
        int status;
        wait(&status);
        int count = getSysCount(mask,pid);
        if (count >= 0) {
            printf("PID %d called %s %d times.\n", pid, syscallname(mask), count);
        } else {
            printf("Error: failed to get system call count\n");
        }
    } else {
        printf("Error: fork failed\n");
    }

    exit(0);
}


