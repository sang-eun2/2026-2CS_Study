#include <cstdint>
#include <cstdio>
#include <cstring>
#include <initializer_list>
// 사용법: ./arithmetic        모든 검사
//         ./arithmetic arith  AddSubI32_a만 (bitwise.asm이 아직 TODO여도 됨)
//         ./arithmetic bit    비트 함수 네 개만
// assert 대신 직접 검사함: -DNDEBUG로 빌드해도 검사가 사라지지 않음.
extern "C" int AddSubI32_a(int, int, int, int);
extern "C" int BitwiseAnd(int, int);
extern "C" int BitwiseOr(int, int);
extern "C" int BitwiseXor(int, int);
extern "C" int BitwiseNot(int);
static int failures = 0, checks = 0;
static void check(const char *call, int got, int want) {
    ++checks;
    if (got != want) {
        ++failures;
        std::printf("FAIL %s: got 0x%08x (%d), want 0x%08x (%d)\n", call,
                    unsigned(got), got, unsigned(want), want);
    }
}
static int i32(std::uint32_t u) { return static_cast<int>(u); }
static void test_arith() {
    struct { int a, b, c, d, want; } t[] = {
        {10, 40, 9, 6, 42},                 // 기본 예
        {-3, 7, 2, -4, 13},                 // 음수 인자
        {100, 100, 0, 0, 207},              // 8비트 범위를 넘는 결과
        {40000, 30000, 1, 2, 70004},        // 16비트 범위를 넘는 결과
        {-1000, -2000, 500, 500, -3993},    // 음수 결과
        {0x01000000, 0x02000000, 0x10000, 0x100, 0x02FEFF07},  // 상위 바이트까지 쓰는 값
    };
    for (const auto &x : t) {
        char call[96];
        std::snprintf(call, sizeof call, "AddSubI32_a(%d, %d, %d, %d)", x.a, x.b, x.c, x.d);
        check(call, AddSubI32_a(x.a, x.b, x.c, x.d), x.want);
    }
}
static void test_bit() {
    const int as[] = {0, 0x55, -1, 0x12345678, i32(0x80000000u), i32(0xF0F0F0F0u)};
    const int bs[] = {0, 0xAA, -1, 0x0F0F0F0F, i32(0x87654321u)};
    char call[96];
    for (int a : as) {
        for (int b : bs) {
            std::snprintf(call, sizeof call, "BitwiseAnd(0x%08x, 0x%08x)", unsigned(a), unsigned(b));
            check(call, BitwiseAnd(a, b), a & b);
            std::snprintf(call, sizeof call, "BitwiseOr(0x%08x, 0x%08x)", unsigned(a), unsigned(b));
            check(call, BitwiseOr(a, b), a | b);
            std::snprintf(call, sizeof call, "BitwiseXor(0x%08x, 0x%08x)", unsigned(a), unsigned(b));
            check(call, BitwiseXor(a, b), a ^ b);
        }
        std::snprintf(call, sizeof call, "BitwiseNot(0x%08x)", unsigned(a));
        check(call, BitwiseNot(a), ~a);
    }
}
int main(int argc, char **argv) {
    static_assert(sizeof(int) == 4, "This lab uses 32-bit int");
    const char *part = argc > 1 ? argv[1] : "all";
    bool arith = !std::strcmp(part, "all") || !std::strcmp(part, "arith");
    bool bit = !std::strcmp(part, "all") || !std::strcmp(part, "bit");
    if (!arith && !bit) {
        std::printf("usage: %s [arith|bit]\n", argv[0]);
        return 2;
    }
    if (arith) test_arith();
    if (bit) test_bit();
    if (failures) {
        std::printf("%d of %d check(s) failed\n", failures, checks);
        return 1;
    }
    std::printf("PASS %s (%d checks)\n", part, checks);
    if (bit) std::printf("BitwiseNot(0x55) = %08x\n", unsigned(BitwiseNot(0x55)));
    return 0;
}
