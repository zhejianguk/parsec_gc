#include <stdio.h>
#include <linux/prctl.h>
#include <sys/prctl.h>
#include <stdlib.h>

// Compile with: clang-8 -fsanitize=shadow-call-stack shadowstack.c -o shadowstack
int arch_prctl(int code, unsigned long *addr);


void __attribute__ ((constructor)) __attribute__((no_sanitize("shadow-call-stack"))) setupgs()
{
    void *shadow = malloc(5096);
    if (shadow == NULL){
        exit(0);
    }
    asm volatile ("mov x18, %0" : : "r"(shadow));
    // printf("hello");
}


int bar() {
return 42;
}
int foo() {
return bar() + 1;
}
int main(int argc, char **argv) {
printf("Hello, world %d!\n", foo());
return 0;
}