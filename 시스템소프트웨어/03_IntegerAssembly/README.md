# 정수어셈블리 실습 파일

해당 주제 폴더의 과제 강의자료와 함께 사용합니다. 학부 Linux 서버(x86-64)를 기준으로 합니다: Ubuntu 20.04, gcc 9.4, binutils 2.34, nasm 2.14, gdb 9.2.

NASM 파일의 TODO를 구현하십시오. 미완성 함수의 `ud2`는 실행을 명확히 중단하는 자리표시자이며, 구현 후 제거해야 합니다. 완성 답안은 포함하지 않습니다.

## 빌드와 실행

```sh
nasm -f elf64 hello.asm -o hello.o
ld hello.o -o hello
./hello
nasm -f elf64 AddSubI32_a.asm -o AddSubI32_a.o
nasm -f elf64 bitwise.asm -o bitwise.o
g++ -g main.cpp AddSubI32_a.o bitwise.o -o arithmetic
./arithmetic arith   # 문제 2만 검사
./arithmetic bit     # 문제 3만 검사
./arithmetic         # 전체
```
