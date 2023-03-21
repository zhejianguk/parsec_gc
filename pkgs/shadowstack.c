#include <stdio.h>
#include <linux/prctl.h>
#include <sys/prctl.h>
#include <stdlib.h>

// Compile with: clang-8 -fsanitize=shadow-call-stack shadowstack.c -o shadowstack
int arch_prctl(int code, unsigned long *addr);

void *shadow;

void __attribute__ ((constructor)) __attribute__((no_sanitize("shadow-call-stack"))) setupgs()
{
    void *shadow = malloc(16384*4);
    
    if (!shadow) {
        // Handle memory allocation failure.
    }

    asm volatile ("mov x18, %0" : : "r"(shadow));
}


void __attribute__ ((destructor)) __attribute__((no_sanitize("shadow-call-stack"))) un_setupgs()
{
    free(shadow);
}

