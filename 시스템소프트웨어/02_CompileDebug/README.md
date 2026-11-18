# 컴파일과디버깅 실습 파일

해당 주제 폴더의 과제 강의자료와 함께 사용합니다. 학부 Linux 서버(x86-64)를 기준으로 합니다: Ubuntu 20.04, gcc 9.4, binutils 2.34, nasm 2.14, gdb 9.2.

## 빌드와 실행

```sh
# 문제 1
gcc -O0 -g -S ops.c -o ops.s
gcc -O0 -g -c ops.c -o ops.o
objdump -d ops.o
# 문제 2
gcc -O0 -g -c main.c -o main.o
ar rcs libops.a ops.o
ar t libops.a
gcc main.o -L. -lops -o demo
./demo                      # 8 -2
gcc -L. -lops main.o -o demo_bad  # 일부러 실패시킴. demo와 다른 이름으로
# 문제 3
objdump -dr main.o > main_object.txt
objdump -d demo > demo_disasm.txt
# 문제 4
gdb ./demo
```
