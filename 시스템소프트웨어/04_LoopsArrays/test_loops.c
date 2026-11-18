#include <limits.h>
#include <signal.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>
/* 사용법: ./loops        모든 검사
 *         ./loops max    max2만
 *         ./loops jtm    jump_to_middle_loop_sum만
 *         ./loops gdo    guarded_do_loop_sum만
 *         ./loops pos    sum_positive만
 *         ./loops dot    dot_product만
 * assert 대신 직접 검사함: -DNDEBUG로 빌드해도 검사가 사라지지 않음. */
extern int max2(int, int);
extern int jump_to_middle_loop_sum(const int *, int);
extern int guarded_do_loop_sum(const int *, int);
extern int sum_positive(const int *, int);
extern int dot_product(const int *, const int *, int);
/* test_helpers.asm: 인자 레지스터의 상위 32비트에 hi를 채워 호출 */
typedef int (*sum_fn)(const int *, int);
typedef int (*dot_fn)(const int *, const int *, int);
typedef int (*max_fn)(int, int);
extern int call_sum_hi(sum_fn f, const int *arr, int n, unsigned hi);
extern int call_dot_hi(dot_fn f, const int *a, const int *b, int n, unsigned hi);
extern int call_max2_hi(max_fn f, int a, int b, unsigned hi);
/* FAIL 줄의 got = 내 함수의 결과, want = 기대 결과 */
static int failures = 0, checks = 0;
/* 실행 중인 검사 이름: 함수가 멈추면(ud2, 잘못된 메모리 읽기) 어느 검사였는지 알려 줌 */
static const char *volatile current = "";
static void on_crash(int sig) {
    const char *kind = sig == SIGILL ? "Illegal instruction (ud2: 미완성 함수?)"
                                     : "Segmentation fault (잘못된 주소를 읽음)";
    const char *msg[] = {"CRASH ", current, ": ", kind, "\n"};
    for (int i = 0; i < 5; ++i)
        if (write(STDOUT_FILENO, msg[i], strlen(msg[i])) < 0) break;
    _exit(128 + sig);
}
#define CHECK(what, expr, want) do { current = (what); check((what), (expr), (want)); } while (0)
static void check(const char *what, int got, int want) {
    ++checks;
    if (got != want) {
        ++failures;
        printf("FAIL %s: got %d (0x%08x), want %d (0x%08x)\n",
               what, got, (unsigned)got, want, (unsigned)want);
    }
}
/* n번째 칸 뒤에 큰 값을 두어, i <= n처럼 한 칸 더 읽으면 결과가 틀리게 함 */
#define GUARD 1000000
static int ref_sum(const int *a, int n) {
    long long s = 0;
    for (int i = 0; i < n; ++i) s += a[i];
    return (int)s;
}
static int ref_sum_pos(const int *a, int n) {
    long long s = 0;
    for (int i = 0; i < n; ++i)
        if (a[i] > 0) s += a[i];
    return (int)s;
}
static int ref_dot(const int *a, const int *b, int n) {
    long long s = 0;
    for (int i = 0; i < n; ++i) s += (long long)a[i] * b[i];
    return (int)s;
}
/* 준비 실습: 반복 없이 비교 한 번과 조건부 점프 한 번 */
static void test_max2(void) {
    char what[96];
    static const struct { int a, b, want; } cases[] = {
        {7, 3, 7}, {3, 7, 7}, {7, 7, 7},          /* 같을 때도 7 */
        {-5, -9, -5}, {-9, -5, -5},               /* 둘 다 음수 */
        {0, -1, 0}, {-1, 0, 0},
        {INT_MIN, INT_MAX, INT_MAX}, {INT_MAX, INT_MIN, INT_MAX},
        {-2000000000, 2000000000, 2000000000},    /* unsigned로 비교하면 틀림 */
    };
    for (unsigned k = 0; k < sizeof cases / sizeof cases[0]; ++k) {
        snprintf(what, sizeof what, "max2(%d, %d)", cases[k].a, cases[k].b);
        CHECK(what, max2(cases[k].a, cases[k].b), cases[k].want);
    }
    /* a와 b는 int(32비트): rdi/rsi 상위 32비트에 다른 값이 있어도 edi/esi만 보아야 함 */
    CHECK("max2(-5, 3) with garbage in upper rdi/rsi",
          call_max2_hi(max2, -5, 3, 0xFACE0000u), 3);
}
static void test_sum(const char *name, sum_fn f) {
    char what[96];
    static const int vals[] = {1, 2, 3, 4, 5, -5, 2, -1, 4, 7};
    int buf[16];
    for (int n = 1; n <= 10; ++n) {      /* 길이 1~10, 끝 뒤에 GUARD */
        memcpy(buf, vals, n * sizeof(int));
        buf[n] = GUARD;
        snprintf(what, sizeof what, "%s(vals, %d)", name, n);
        CHECK(what, f(buf, n), ref_sum(vals, n));
    }
    /* 큰 값: 16비트 레지스터로 더하면 틀림. 합은 int 범위 안 */
    int big[] = {2000000000, -1999999999, 0x01000000, -70000, 147483647, GUARD};
    snprintf(what, sizeof what, "%s(big, 5)", name);
    CHECK(what, f(big, 5), ref_sum(big, 5));
    int neg[] = {-100000, -200000, -300000, GUARD};
    snprintf(what, sizeof what, "%s(neg, 3)", name);
    CHECK(what, f(neg, 3), -600000);
    /* n <= 0이면 배열을 읽지 않고 0 (NULL을 읽으면 Segmentation fault) */
    static const int ns[] = {0, -1, -5, INT_MIN};
    for (int k = 0; k < 4; ++k) {
        snprintf(what, sizeof what, "%s(NULL, %d)", name, ns[k]);
        CHECK(what, f(NULL, ns[k]), 0);
    }
    /* n은 int(32비트): rsi 상위 32비트에 다른 값이 있어도 esi만 보아야 함 */
    memcpy(buf, vals, 3 * sizeof(int)); buf[3] = GUARD;
    snprintf(what, sizeof what, "%s(vals, 3) with garbage in upper rsi", name);
    CHECK(what, call_sum_hi(f, buf, 3, 0xDEAD0000u), 6);
    /* rsi = 0x00000000FFFFFFFF: 64비트로 보면 큰 양수, esi로 보면 -1 */
    snprintf(what, sizeof what, "%s(NULL, -1) with upper rsi = 0", name);
    CHECK(what, call_sum_hi(f, NULL, -1, 0u), 0);
}
/* 반복 조건과 반복 안의 if가 섞이지 않았는지 봄 */
static void test_sum_pos(void) {
    char what[96];
    static const int vals[] = {1, -2, 3, 4, -5, -5, 2, -1, 4, 7};
    int buf[16];
    for (int n = 1; n <= 10; ++n) {      /* 길이 1~10, 끝 뒤에 GUARD */
        memcpy(buf, vals, n * sizeof(int));
        buf[n] = GUARD;
        snprintf(what, sizeof what, "sum_positive(vals, %d)", n);
        CHECK(what, sum_positive(buf, n), ref_sum_pos(vals, n));
    }
    /* 큰 양수와 큰 음수를 섞음. 양수만 더하면 int 범위 안(합 = INT_MAX) */
    int big[] = {2000000000, -1999999999, 100000000, -70000, 47483647, GUARD};
    CHECK("sum_positive(big, 5)", sum_positive(big, 5), ref_sum_pos(big, 5));
    /* 모두 음수: 한 번도 더하지 않고 0 */
    int neg[] = {-100000, -200000, -300000, GUARD};
    CHECK("sum_positive(neg, 3)", sum_positive(neg, 3), 0);
    /* 0이 섞여도 합이 맞는가. 0을 더해도 합은 그대로라, 이 검사로 jl/jle를 가릴 수는 없음 */
    int zeros[] = {0, 5, 0, 0, 7, GUARD};
    CHECK("sum_positive(zeros, 5)", sum_positive(zeros, 5), 12);
    /* n <= 0이면 배열을 읽지 않고 0 */
    static const int ns[] = {0, -1, -5, INT_MIN};
    for (int k = 0; k < 4; ++k) {
        snprintf(what, sizeof what, "sum_positive(NULL, %d)", ns[k]);
        CHECK(what, sum_positive(NULL, ns[k]), 0);
    }
    memcpy(buf, vals, 3 * sizeof(int)); buf[3] = GUARD;
    CHECK("sum_positive(vals, 3) with garbage in upper rsi",
          call_sum_hi(sum_positive, buf, 3, 0xDEAD0000u), 4);
    CHECK("sum_positive(NULL, -1) with upper rsi = 0",
          call_sum_hi(sum_positive, NULL, -1, 0u), 0);
}
static void test_dot(void) {
    char what[96];
    static const int a[] = {1, 2, 3, 4, 5, -5, 2, -1};
    static const int b[] = {6, 7, 8, 9, 10, 3, -4, 6};
    int x[12], y[12];
    for (int n = 1; n <= 8; ++n) {
        memcpy(x, a, n * sizeof(int)); x[n] = GUARD;
        memcpy(y, b, n * sizeof(int)); y[n] = GUARD;
        snprintf(what, sizeof what, "dot_product(a, b, %d)", n);
        CHECK(what, dot_product(x, y, n), ref_dot(a, b, n));
    }
    /* 곱이 16비트를 넘는 값, 음수 곱 */
    int p[] = {46340, -30000, 1000, GUARD}, q[] = {46340, 30000, -1000, GUARD};
    CHECK("dot_product(p, q, 3)", dot_product(p, q, 3), ref_dot(p, q, 3));
    /* 두 배열을 바꿔 쓰면 틀리도록 길이가 같은 서로 다른 배열 */
    int r[] = {3, 0, 0, GUARD}, s[] = {0, 5, 7, GUARD};
    CHECK("dot_product(r, s, 3)", dot_product(r, s, 3), 0);
    static const int ns[] = {0, -1, INT_MIN};
    for (int k = 0; k < 3; ++k) {
        snprintf(what, sizeof what, "dot_product(NULL, NULL, %d)", ns[k]);
        CHECK(what, dot_product(NULL, NULL, ns[k]), 0);
    }
    memcpy(x, a, 2 * sizeof(int)); x[2] = GUARD;
    memcpy(y, b, 2 * sizeof(int)); y[2] = GUARD;
    CHECK("dot_product(a, b, 2) with garbage in upper rdx",
          call_dot_hi(dot_product, x, y, 2, 0xBEEF0000u), 20);
}
int main(int argc, char **argv) {
    setvbuf(stdout, NULL, _IONBF, 0);
    signal(SIGSEGV, on_crash);
    signal(SIGILL, on_crash);  /* 중간에 멈춰도 앞의 FAIL 줄이 보이게 */
    _Static_assert(sizeof(int) == 4, "This lab uses 32-bit int");
    const char *part = argc > 1 ? argv[1] : "all";
    int all = !strcmp(part, "all");
    int mx  = all || !strcmp(part, "max");
    int jtm = all || !strcmp(part, "jtm");
    int gdo = all || !strcmp(part, "gdo");
    int pos = all || !strcmp(part, "pos");
    int dot = all || !strcmp(part, "dot");
    if (!mx && !jtm && !gdo && !pos && !dot) {
        printf("usage: %s [max|jtm|gdo|pos|dot]\n", argv[0]);
        return 2;
    }
    if (mx)  test_max2();
    if (jtm) test_sum("jump_to_middle_loop_sum", jump_to_middle_loop_sum);
    if (gdo) test_sum("guarded_do_loop_sum", guarded_do_loop_sum);
    if (pos) test_sum_pos();
    if (dot) test_dot();
    if (failures) {
        printf("%d of %d check(s) failed\n", failures, checks);
        return 1;
    }
    printf("PASS %s (%d checks)\n", part, checks);
    return 0;
}
