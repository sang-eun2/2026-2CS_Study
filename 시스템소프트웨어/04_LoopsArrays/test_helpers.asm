; 테스트 전용 보조 함수 (수정하지 마십시오)
; int 인자를 받는 함수를, 그 인자 레지스터의 상위 32비트에 다른 값을 채운 채 호출합니다.
; 구현이 64비트 레지스터(rsi, rdx) 대신 32비트(esi, edx)만 보는지 확인하는 용도입니다.
; C에서 함수 포인터의 인자형을 바꿔 호출하는 것은 표준상 호환되지 않으므로 여기서 처리합니다.

section .text
global call_sum_hi
global call_dot_hi
global call_max2_hi

; int call_sum_hi(int (*f)(const int *, int), const int *arr, int n, unsigned hi)
;   f(arr, n)을 호출하되 rsi = (hi << 32) | (unsigned)n
call_sum_hi:
    mov rax, rdi                ; 호출할 함수
    mov rdi, rsi                ; 인자 1: arr
    mov esi, edx                ; 인자 2: n (rsi 상위 32비트는 0이 됨)
    shl rcx, 32                 ; hi를 상위 32비트로
    or  rsi, rcx
    jmp rax                     ; f의 반환값이 그대로 호출자에게 감

; int call_dot_hi(int (*f)(const int *, const int *, int),
;                 const int *a, const int *b, int n, unsigned hi)
;   f(a, b, n)을 호출하되 rdx = (hi << 32) | (unsigned)n
call_dot_hi:
    mov rax, rdi
    mov rdi, rsi                ; 인자 1: a
    mov rsi, rdx                ; 인자 2: b
    mov edx, ecx                ; 인자 3: n
    shl r8, 32
    or  rdx, r8
    jmp rax

; int call_max2_hi(int (*f)(int, int), int a, int b, unsigned hi)
;   f(a, b)를 호출하되 rdi = (hi << 32) | (unsigned)a, rsi = (hi << 32) | (unsigned)b
call_max2_hi:
    mov rax, rdi                ; 호출할 함수
    mov edi, esi                ; 인자 1: a (rdi 상위 32비트는 0이 됨)
    mov esi, edx                ; 인자 2: b (rsi 상위 32비트는 0이 됨)
    shl rcx, 32                 ; hi를 상위 32비트로
    or  rdi, rcx
    or  rsi, rcx
    jmp rax

section .note.GNU-stack noalloc noexec nowrite progbits
