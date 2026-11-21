# 04: 반복문과 배열

## 반복문 번역 패턴
**jump-to-middle** (`jump_to_middle_loop_sum`)
```
      jmp test
loop: 본문
test: 조건 검사 → 참이면 jmp loop
```
**guarded-do** (`guarded_do_loop_sum`)
```
      조건이 거짓이면 jmp done   ; 처음 한 번만 검사
loop: 본문
      조건이 참이면 jmp loop
done:
```
gcc는 `-Og`에서 jump-to-middle을, `-O1` 이상에서 guarded-do를 주로 씁니다. `reference_Og.s`와 `reference_O1.s`를 비교해 보세요.

## 배열 접근
`a[i]`(int 배열) → `[rdi + rcx*4]`: 시작 주소 + 인덱스 × 원소 크기. x86 주소 지정 모드가 곱셈을 대신해 줍니다.
- `sum_positive`: 조건 분기(`cmp`, `jle`)로 양수만 더하기
- `dot_product`: 두 배열을 같은 인덱스로 순회하며 곱해서 누적
- `max2`: 두 값 중 큰 값 (`cmp` + 조건부 이동/분기)

## 빌드와 실행
빌드·실행 명령은 같은 폴더의 [README.md](./README.md)에 있습니다.
