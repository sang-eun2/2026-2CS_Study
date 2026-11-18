#include <stdio.h>
#include <limits.h>
#include <string.h>
#define LAST4 1234U   /* Replace with the last 4 ID digits, no leading zeros. */
_Static_assert(CHAR_BIT == 8 && sizeof(int) == 4,
               "This exercise requires 8-bit bytes and 32-bit int.");

static void show_bytes(const char *name, const void *obj, size_t n)
{
    const unsigned char *p = obj;
    printf("%s (%zu bytes):", name, n);
    for (size_t i = 0; i < n; ++i)
        printf(" %02X", (unsigned int)p[i]);
    putchar('\n');
}

int main(void)
{
    int x = 15213;
    char s[] = "15213";
    unsigned int personal = 20000U + LAST4;
    printf("CHAR_BIT=%d int=%zu long=%zu ptr=%zu\n",
           CHAR_BIT, sizeof(int), sizeof(long), sizeof(void *));
    printf("sizeof(s)=%zu strlen(s)=%zu\n", sizeof(s), strlen(s));
    show_bytes("x", &x, sizeof(x));
    show_bytes("s", s, sizeof(s));
    printf("personal=%u hex=%X\n", personal, personal);
    show_bytes("personal", &personal, sizeof(personal));
    return 0;
}
