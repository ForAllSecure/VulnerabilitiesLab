// $CC envfuzz.c -o envfuzz.so -shared -fPIC -ldl -g

#define _GNU_SOURCE
#include <dlfcn.h>
#include <stdio.h>
#include <string.h>

#include <fcntl.h>
#include <unistd.h>

#include <stdlib.h>
#include <poll.h>

#define BLOCK_SIZE 64
#define EXPANSION_FACTOR 256
#define FUZZ_TAG "fuzzme"

extern void *malloc(size_t size);
extern void *calloc(size_t count, size_t size);
extern void qsort(void *base, size_t nel, size_t width, int (*compar)(const void *, const void *));

static int (*main_orig)(int, char **, char **);
static char *(*getenv_orig)(const char *);
static int (*read_orig)(int, void *, size_t);
static int (*system_orig)(const char *);
static FILE *(*popen_orig)(const char *, const char *);


char **fuzz_envp = NULL;
int fuzz_fd = -1;


// LD_PRELOAD'd getenv function (checks for fuzzed envvars first)
char *getenv(const char *name) {
    char **tracer;
    int namelen = strlen(name);

    for (tracer = fuzz_envp; *tracer != NULL; tracer++) {
        if (strncmp(name, *tracer, namelen) == 0) return (*tracer) + namelen + 1;
    }

    return getenv_orig(name);
}


// LD_PRELOAD'd read function (replaces stdin with fuzzed fd)
ssize_t read(int fd, void *buf, size_t sz) {
    if (fd == 0) fd = fuzz_fd;
    return read_orig(fd, buf, sz);
}


// gets length of envvar name
int name_len(char *env) {
    return strchr(env, '=') - env;
}


// compares two strings in qsort compatible way
int cmp(const void *a, const void *b) {
    const char **ia = (const char **) a;
    const char **ib = (const char **) b;
    return strcmp(*ia, *ib);
}

void clean_fs() {
    remove("/getfuzzed");
}

void check_injection() {
    printf("checking if /getfuzzed exists\n");
    if (access("/getfuzzed", F_OK) == 0) {
        printf("command injection detected\n");
        abort();
    }
}


int system(const char *cmd) {
    int ret = system_orig(cmd);
    check_injection();
    return ret;
}


FILE *popen(const char *cmd, const char *mode) {
    printf("popen:\n%s\n", cmd);

    FILE *ret = popen_orig(cmd, mode);

    if (ret != NULL) {
        int fd = fileno(ret);
        struct pollfd fds = {.fd = fd, .events = POLLIN};
        int status = poll(&fds, 1, 1000); // wait up to one second for data
        if (status == 0) {
            printf("timed out checking popen\n");
        }
    }

    check_injection();
    
    return ret;
}


// reads in envp for fuzzed envvars and loads with fuzzed data from fuzz_fd
int load_fuzz_envp(char **envp) {
    char **tracer, **fuzz_tracer;
    char *var, *buf;
    int count, size, i, envp_len;

    envp_len = 0;
    count = 0;
    size = 0;
    for (tracer = envp; *tracer != NULL; tracer++) {
        envp_len++;
        var = strchr(*tracer, '=') + 1;
        if (strcmp(var, FUZZ_TAG) == 0) {
            count++;
            size += name_len(*tracer) + 1 + BLOCK_SIZE * EXPANSION_FACTOR + 1; // name=fuzz\0
        }
    }

    // ensure that envp is arranged the same everytime
    qsort(envp, envp_len, sizeof(*envp), cmp);

    fuzz_envp = calloc(count + 1, sizeof(*fuzz_envp));
    if (fuzz_envp == NULL) return -1;

    buf = calloc(size, 1);
    if (size != 0 && buf == NULL) return -1;

    fuzz_tracer = fuzz_envp;
    for (tracer = envp; *tracer != NULL; tracer++) {
        var = strchr(*tracer, '=') + 1;
        if (strcmp(var, FUZZ_TAG) == 0) {
            *fuzz_tracer = buf;
            strncpy(buf, *tracer, name_len(*tracer));
            strcat(buf, "=");
            read(fuzz_fd, &buf[strlen(buf)], BLOCK_SIZE);
            
            fuzz_tracer++;
            buf += name_len(*tracer) + 1 + BLOCK_SIZE * EXPANSION_FACTOR + 1;
        }
    }
}


// Our fake main() that gets called by __libc_start_main()
int main_hook(int argc, char **argv, char **envp)
{
    int ret;
    char **fuzz_envp;

    if (argc < 2) {
        printf("must provide fuzzed file as last argument!\n");
        return 1;
    }

    fuzz_fd = open(argv[argc - 1], O_RDONLY);
    if (fuzz_fd < 0) {
        printf("failed to open fuzz file\n");
        return 1;
    }

    if (load_fuzz_envp(envp) < 0) {
        printf("failed to load fuzz envp!\n");
        return 1;
    }

    clean_fs();

    argc -= 1;
    argv[argc] = NULL;

    // pass in 0xdeadbeaf to ensure program is not touching envp directly
    ret = main_orig(argc, argv, (char **) 0xdeadbeaf);

    return ret;
}


int __libc_start_main(
    int (*main)(int, char **, char **),
    int argc,
    char **argv,
    int (*init)(int, char **, char **),
    void (*fini)(void),
    void (*rtld_fini)(void),
    void *stack_end)
{
    // save the real function addresses
    main_orig = main;

    // grab original hooked functions
    getenv_orig = (typeof(getenv_orig)) dlsym(RTLD_NEXT, "getenv");
    read_orig = (typeof(read_orig)) dlsym(RTLD_NEXT, "read");
    system_orig = (typeof(system_orig)) dlsym(RTLD_NEXT, "system");
    popen_orig = (typeof(popen_orig)) dlsym(RTLD_NEXT, "popen");

    unsetenv("LD_PRELOAD");

    // Find the real __libc_start_main()...
    typeof(&__libc_start_main) orig = (typeof(&__libc_start_main)) dlsym(RTLD_NEXT, "__libc_start_main");

    // ... and call it with our custom main function
    return orig(main_hook, argc, argv, init, fini, rtld_fini, stack_end);
}
