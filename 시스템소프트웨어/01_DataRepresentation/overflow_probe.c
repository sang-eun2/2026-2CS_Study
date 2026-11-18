#include <stdio.h>
#include <limits.h>

int main(void)
{
    volatile int x = INT_MAX;
    printf("%d\n", x + 1);  /* Deliberate UB: run only with UBSan. */
    return 0;
}
