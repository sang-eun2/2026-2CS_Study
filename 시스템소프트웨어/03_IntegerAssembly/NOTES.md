# 03: 정수 어셈블리 (NASM, x86-64)

## 호출 규약 (System V AMD64)
- 정수 인자: `rdi, rsi, rdx, rcx, r8, r9` 순서 (32비트는 `edi, esi, ...`)
- 반환값: `rax` / `eax`
- 그래서 `int BitwiseAnd(int a, int b)`는 `mov eax, edi` → `and eax, esi` → `ret`이면 끝입니다.

## 파일
- `hello.asm`: `_start`에서 `syscall`로 write/exit를 직접 호출 (C 런타임 없이 실행)
- `AddSubI32_a.asm`: `add`, `sub`로 정수 산술
- `bitwise.asm`: `and`, `or`, `xor`, `not`
- `main.cpp`: `extern "C"`로 선언해 C++에서 어셈블리 함수를 호출하고 결과를 확인

## 포인트
- 32비트 레지스터(`eax`)에 쓰면 64비트 레지스터의 상위 32비트가 0으로 지워집니다.
- `ud2`는 미구현 함수 자리표시자입니다. 구현한 뒤 지웁니다.
