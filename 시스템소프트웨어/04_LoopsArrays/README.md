# 반복문과배열 실습 파일

해당 주제 폴더의 과제 강의자료와 함께 사용합니다. 학부 Linux 서버(x86-64)를 기준으로 합니다: Ubuntu 20.04, gcc 9.4, binutils 2.34, nasm 2.14, gdb 9.2.

## 파일

| 파일 | 역할 |
|---|---|
| `loops.asm` | **학생이 완성하는 파일.** 다섯 함수의 TODO를 채웁니다 |
| `test_loops.c` | 테스트 (수정하지 않음) |
| `test_helpers.asm` | 테스트 전용 보조 함수 (수정하지 않음) |
| `reference.c` | 최적화 수준별 어셈블리 비교용 C 함수 |

## 구현할 함수

| 함수 | 할 일 |
|---|---|
| `int max2(int a, int b)` | 두 값 중 큰 값 반환 (준비 실습: 반복 없음) |
| `int jump_to_middle_loop_sum(const int *arr, int n)` | 처음에 아래쪽 조건 검사로 이동하는 배열 합 |
| `int guarded_do_loop_sum(const int *arr, int n)` | 진입 가능 여부(`n <= 0`)를 먼저 검사하는 배열 합 |
| `int sum_positive(const int *arr, int n)` | 양수인 원소만 더하기 (반복 안에 if가 하나 더 있음) |
| `int dot_product(const int *a, const int *b, int n)` | 같은 인덱스의 두 원소를 곱해 누적 |

`max2`에는 반복이 없습니다. 비교 한 줄과 조건부 점프 한 줄만 채우면 됩니다. 레이블(`.pick_a`)과 `mov`/`ret`은 주어져 있습니다.

배열을 받는 네 함수는 `n <= 0`이면 배열을 읽지 않고 0을 반환합니다. 두 합 함수의 골격에서 초기화·계산·조건 비교를 완성합니다. guarded-do는 본문 진입 전의 종료 분기도 작성합니다. `sum_positive`는 주어진 골격에서 원소 읽기·양수 판정·누적·반복 조건을 채웁니다. 내적은 레이블과 분기를 포함한 반복 구조 전체를 작성합니다.

각 함수 첫 줄의 `ud2`는 **미완성 표시**입니다. 실행되면 프로그램이 `Illegal instruction`으로 멈춥니다. 그 함수를 구현할 때 지우십시오. 완성 답안은 포함하지 않습니다.

## 빌드와 실행 (한 함수씩)

```sh
nasm -f elf64 loops.asm -o loops.o
nasm -f elf64 test_helpers.asm -o test_helpers.o
gcc -std=c11 -Wall -Wextra -g test_loops.c loops.o test_helpers.o -o loops
./loops max   # 1. max2만 검사
./loops jtm   # 2. jump_to_middle_loop_sum만 검사
./loops gdo   # 3. guarded_do_loop_sum만 검사
./loops pos   # 4. sum_positive만 검사
./loops dot   # 5. dot_product만 검사
./loops       # 6. 다섯 함수를 모두 완성한 뒤 전체 검사
```

한 함수만 완성했을 때 `./loops`(전체)를 실행하면 다른 함수의 `ud2`에서 멈춥니다. 위 순서대로 진행하십시오.

- 성공: `PASS max (11 checks)`, `PASS jtm (18 checks)`, `PASS gdo (18 checks)`, `PASS pos (19 checks)`, `PASS dot (14 checks)`, 전체는 `PASS all (80 checks)`
- 실패: `FAIL jump_to_middle_loop_sum(vals, 3): got 7 (...), want 6 (...)` — **got은 내 함수의 결과, want는 기대 결과**입니다. 괄호 안은 같은 값의 16진수입니다.
- 멈춤: `CRASH guarded_do_loop_sum(vals, 1): Illegal instruction (ud2: 미완성 함수?)` — 어느 검사에서 멈췄는지 알려 줍니다. `ud2`가 남았거나, 잘못된 주소를 읽은 경우(`Segmentation fault`)입니다.

## 최적화 수준 비교

```sh
gcc -Og -S -masm=intel reference.c -o reference_Og.s
gcc -O1 -S -masm=intel reference.c -o reference_O1.s
```

`for_loop_sum`에서 첫 진입 분기, 조건 검사 위치, 되돌아가는 분기를 비교합니다.

## 테스트로 가릴 수 없는 것

`max2(7, 7)`은 어느 경로로 가도 7이고, `sum_positive`에서 0을 더해도 합은 그대로입니다. 즉 `jg`/`jge`와 `jl`/`jle`의 차이는 **결과로는 드러나지 않습니다**. 경계에서 어느 경로로 가는지는 코드를 직접 따라가거나 GDB로 확인하십시오.

C 테스트는 원본 PDF의 함수 인터페이스를 바탕으로 새로 작성했습니다. 과거 서버 `/mnt/SysSW/Prac2`, `/mnt/SysSW/Prac3`의 원본 파일을 복구한 것은 아닙니다.
