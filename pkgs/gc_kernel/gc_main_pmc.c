#define _GNU_SOURCE             /* See feature_test_macros(7) */
#include <stdio.h>
#include <stdlib.h>
#include <pthread.h>
#include <unistd.h>
#include <sys/syscall.h>
#define gettid() syscall(SYS_gettid)
#include "libraries/spin_lock.h"
#include "libraries/ght.h"
#include "libraries/ghe.h"
#include "libraries/gc_main.h"


int uart_lock;


/* Apply the constructor attribute to myStartupFun() so that it
    is executed before main() */
void gcStartup (void) __attribute__ ((constructor));
  
  
/* Apply the destructor attribute to myCleanupFun() so that it
   is executed after main() */
void gcCleanup (void) __attribute__ ((destructor));
  
  
/* implementation of myStartupFun */
void gcStartup (void)
{
    printf ("[Boom-C%x]: startup code before main()\n");

    if (gc_pthread_setaffinity(BOOM_ID) != 0){
		lock_acquire(&uart_lock);
		printf ("[Boom-C%x]: pthread_setaffinity failed.", BOOM_ID);
		lock_release(&uart_lock);
	}
}
  
/* implementation of myCleanupFun */
void gcCleanup (void)
{
    printf ("[Boom-C%x]: cleanup code after main()\n");
}
  