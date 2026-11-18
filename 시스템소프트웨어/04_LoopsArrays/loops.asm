; 반복문과 배열: 학생이 완성하는 파일
;
; 함수마다 주어지는 것과 채울 것이 다릅니다.
;   max2          : 비교와 조건부 점프를 채움 (레이블과 mov/ret 은 주어짐)
;   두 합 함수    : 초기화·계산·조건 검사를 채움 (guarded-do 는 진입 분기도 작성)
;   sum_positive  : 원소 읽기·양수 판정·누적·반복 조건을 채움 (레이블은 주어짐)
;   dot_product   : 레이블과 분기를 포함한 반복 구조 전체를 작성
;
; 각 함수 첫 줄의 ud2는 "아직 미완성"이라는 표시입니다. 그 함수를 구현할 때 지우십시오.
; 공통 계약: 배열을 받는 함수는 n <= 0이면 배열을 읽지 않고 0을 반환. 중간 결과는 int32 범위 안.

section .text
global max2
global jump_to_middle_loop_sum
global guarded_do_loop_sum
global sum_positive
global dot_product

; ------------------------------------------------------------
; int max2(int a, int b)
;   a: edi, b: esi, 반환: eax
;   준비 실습: 반복은 없습니다. 비교 한 줄과 조건부 점프 한 줄만 채우면 됩니다.
;   (7,3) (3,7) (7,7)에서 각각 어느 경로로 가는지 따라가 보십시오.
max2:
    cmp edi,esi	; a-b를 계산해 플래그만 설정 (결과는 저장x): a와 b 비교                   (cmp)
    jg .pick_a	; 부호 있는 a>b이면 :  .pick_a 로 점프   (조건부 점프 한 줄) (ZF=0이 true)
    mov eax, esi                ; 여기로 내려오면 b를 고른 것 (a<=b)
    ret
.pick_a:
    mov eax, edi                ; a를 고른 것 + 여기로 내려오면 a<=b :b를 고른 것
    ret
; 경로 :(7,3) : a>b 참 -> 점프 -> return 7 / (3,7) : 거짓 -> 안 뜀 ->return 7
; 경로 : (7,7) : a-b=0이라 ZF=1 -> jg 조건(ZF=0) 불성립으로 점프하지 않고 b경로로 이동.(mov eax,edi).
; 따라서 a>b는 같을 때가 거짓으로 판정되어 else의 return b와 같은 경로이다.



; ------------------------------------------------------------
; int jump_to_middle_loop_sum(const int *arr, int n)
;   arr: rdi, n: esi, 반환: eax
;   제안 배치: total -> edx, i -> eax
jump_to_middle_loop_sum:
    xor edx,edx	; total = 0(edx) i = 0(eax)
    xor eax, eax
    jmp .check                  ; (첫 진입) 본문 건너뛰고 아래 조건 검사로 먼저 이동
.body:
    movsxd rcx,eax	;  total += arr[i]     (movsxd로 i를 64비트로, dword [rdi + rcx*4])
    add edx, dword [rdi+rcx*4]
    add eax, 1	;  i++
.check:
    cmp eax,esi	; (조건검사 i-n계산) i와 n 비교          (cmp)
    jl .body                    ; (반복 분기)i < n 이면 본문으로
    mov eax, edx                ; 반환값 = total
    ret
; n>=0 경로에서 첫jmp로 check에 오면 0<n이 거짓으로 .body에 한번도 들어가지 않고 arr를 읽지 않은 채 total=0이 반환된다


; ------------------------------------------------------------
; int guarded_do_loop_sum(const int *arr, int n)
;   arr: rdi, n: esi, 반환: eax
;   제안 배치: total -> edx, i -> eax
guarded_do_loop_sum:
    xor edx, edx	; total = 0(edx), i = 0(eax)
    xor eax, eax
    test esi, esi	; (첫진입 n이 0인가 확인 가능) n <= 0 이면 배열을 읽지 않고 .done으로   (test 또는 cmp, 그리고 jle)
    jle .done ; (첫진입) n<=0이면 배열을 읽지 않고 .done으로 이동
.body:
    movsxd rcx, eax	; 64비트 부호 확장 및  total += arr[i]
    add edx, dword[rdi+rcx*4]	
    add eax, 1	; i++
    cmp eax, esi	; (조건 검사i-n) i와 n 비교
    jl .body                    ; (반복 분기)i < n 이면 본문 반복
.done:
    mov eax, edx                ; 반환값 = total
    ret
;n<=0인 경우 test 후 jle가 점프해 .body를 건너 뛰고 total=0을 반환한다. 
;n이 1이상인 경우,  본문에 들어왔을 때  본문은 최소 한 번은 실행된다 (do-while구조)


; ------------------------------------------------------------
; int sum_positive(const int *arr, int n)      양수인 원소만 더하기
;   arr: rdi, n: esi, 반환: eax
;   제안 배치: total -> edx, i -> eax, arr[i] -> r8d
;   분기가 두 개입니다. 아래 jl은 "반복을 계속할까"이고,
;   .next로 건너뛰는 분기는 "이 원소를 더할까"입니다. 둘을 섞지 마십시오.
sum_positive:
    xor edx, edx	; total = 0(edx), i = 0(eax)
    xor eax, eax	
    jmp .check                  ; 처음에는 본문을 건너뛰고 아래 조건 검사로
.body:
    movsxd rcx, eax	; 부호확장 및  arr[i]를 r8d로 읽기        (movsxd, dword [rdi + rcx*4])
    mov r8d, dword[rdi+rcx*4]
    cmp r8d, 0	; (반복 안의 조건문 arr[i]과 0비교) 양수가 아니면 .next 로      (cmp, jle)   <- 반복 안의 if
    jle .next	;arr[i]<=0(양수x) 이면 더하지 않고 next로 점프
    add edx, r8d	; 양수일때만 total += arr[i]
.next:
    add eax,1	;  i++(더하지 않더라도 실행해야 다음 인덱스 접근 가능)
.check:
    cmp eax, esi	; (조건 검사i-n) i와 n 비교
    jl .body                    ; (반복 조건) i < n 이면 본문으로   <- 반복 조건
    mov eax, edx                ; 반환값 = total
    ret
;(경계 : 인덱스의 원소 값이 0일때) cmp r8d,0 -> ZF=1 -> jle 조건 (zf=1||sf!=of) 성립 -> .next 건너뜀.
;0은 양수가 아니므로 더하지 않는다. 0을 더하더라도 합은 같아 테스트 결과상 구분되지는 않는다.
;n<=0 경로인 경우, 첫 jmp로 .check에 오면 0<n은 false라 배열을 읽지 않고 0을 반환한다.


; ------------------------------------------------------------
; int dot_product(const int *a, const int *b, int n)
;   a: rdi, b: rsi, n: edx, 반환: eax
;   n이 edx에 있으므로 곱셈 결과를 edx에 두지 마십시오(예: r8d 사용).
;   반복 구조 : guarded -do (진입 검사 한 번 + 아래쪽 검사로 되돌아감)
dot_product:
    xor r9d, r9d ;sum=0	
    xor ecx, ecx ; i=0 (32비트 쓰기는 상위 rcx 상위 32bit를 0으로 만들어 그대로 사용)
			
    test edx, edx	; (첫 진입 n의 부호와 0여부 확인): 반복 (n <= 0이면 원소를 읽지 않음)
    jle .done		; (첫 진입 n<=0이면 a,b,를 읽지 않고 .done으로)a[i] 읽기 -> b[i]와 곱하기(imul) -> sum에 더하기 -> i++
.body:
    mov r8d, dword[rdi+rcx*4] ; r8d=a[i]
    imul r8d, dword[rsi+rcx*4] ; r8d=a[i]*b[i]
    add r9d, r8d	; sum+=a[i]*b[i]
    add ecx, 1		; i++
    cmp ecx,edx		; 조건 검사 : i-n 계산
    jl .body		; 반복 분기 : i<n이면 .body로
.done:
    mov eax,r9d		;반환값=sum    
    ret                         ; 반환값은 eax
;n<=0 경로인경우 test후 jle이 점프하여 a,b를 한번도 읽지 않고 sum=0을 반환한다.
section .note.GNU-stack noalloc noexec nowrite progbits
