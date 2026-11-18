#include <stdio.h>
#include <limits.h>
_Static_assert(CHAR_BIT == 8 && sizeof(int) == 4,
               "This exercise requires 8-bit bytes and 32-bit int.");

static unsigned set_mode(unsigned reg, unsigned mode)
{
    /* TODO: replace only bits 1:0; reg is 0..255, mode is 0..3. */
	
    reg&=(~3U);
    reg|=mode;
    
    return reg;  /* Replace this placeholder. */
}

int main(void)
{
    unsigned char x = 0x95;
    int a = 2, b = 4;
    printf("not_full=%08X not_byte=%02X\n", (unsigned)~0x41,
           (unsigned)(unsigned char)~0x41);
    printf("shift_full=%X shift_byte=%02X\n", (unsigned)(x << 3),
           (unsigned)(unsigned char)(x << 3));
    printf("bit_and=%d logical_and=%d\n", a & b, a && b);
    const unsigned cases[][2] = {{0xB5, 2}, {0xAA, 1}, {0xF0, 3},{0x3C,0}};
    for (size_t i = 0; i < sizeof(cases) / sizeof(cases[0]); ++i) {
        unsigned reg = cases[i][0], mode = cases[i][1];
        unsigned out = set_mode(reg, mode);
        printf("%02X mode=%u -> %02X preserved=%d\n", reg, mode,
               out, (reg & ~3U) == (out & ~3U));
    }
    return 0;
}
