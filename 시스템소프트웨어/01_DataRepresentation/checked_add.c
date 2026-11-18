#include <stdio.h>
#include <limits.h>

static int add_checked(int a, int b, int *out)
{
    /* TODO: success -> store a+b, return 1.
       Overflow -> leave *out unchanged, return 0.
       Do not evaluate a+b before checking. */
    if(b>=0&&a>INT_MAX-b) return 0;
    else if(b<0&&a<INT_MIN-b) return 0;
    *out=a+b;
    return 1;  /* Replace this placeholder. */
}

int main(void)
{
    const int cases[][2] = {
        {12, 30}, {INT_MAX, 0}, {INT_MAX, 1},
        {INT_MIN, -1}, {-1, 1}, {INT_MIN, INT_MAX},
	{100,0},{-100,-200}
    };
    for (size_t i = 0; i < sizeof(cases) / sizeof(cases[0]); ++i) {
        int out = 12345;
        int ok = add_checked(cases[i][0], cases[i][1], &out);
        printf("case%zu: a=%d b=%d ok=%d out=%d\n", i + 1,
               cases[i][0], cases[i][1], ok, out);
    }
    return 0;
}
