/**
 * hgarrereyn@forallsecure.com
 * 
 * This library exposes a jmp_buf struct which acts as a "catch" target for
 * assertion errors. Additional work would need to be done to prevent memory
 * leaks.
 */

#include <stdio.h>
#include <setjmp.h>

jmp_buf env;

jmp_buf *get_jmp_buf() {
    return &env;
}

void __assert_fail(const char * assertion, const char * file, unsigned int line, const char * function) {
    // don't bail on asserts
    printf("Assert encountered: \"%s\" in %s on line %d of %s\n",
           assertion, function, line, file);
    longjmp(env, 1);
}
