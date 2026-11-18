#include <stdio.h>
#include <limits.h>
_Static_assert(CHAR_BIT == 8 && sizeof(short) == 2 && sizeof(int) == 4,
               "This exercise requires 16-bit short and 32-bit int.");

int main(void)
{
    short s = -15213;
    int widened = s;
    unsigned short u = (unsigned short)s;
    int wide = 53191;
    unsigned short low = (unsigned short)wide;
    int minus_one = -1;
    unsigned zero = 0U;
    long long minus_one_ll = -1LL;
    printf("s=%d bits=%04X\n", (int)s, (unsigned)u);
    printf("widened=%d bits=%08X\n", widened, (unsigned)widened);
    printf("as_unsigned_short=%u\n", (unsigned)u);
    printf("wide=%d low=%u bits=%04X\n", wide, (unsigned)low,
           (unsigned)low);
    printf("int_vs_unsigned=%d\n", minus_one < zero);
    printf("long_long_vs_unsigned=%d\n", minus_one_ll < zero);
    return 0;
}
