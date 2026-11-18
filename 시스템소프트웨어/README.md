# 시스템소프트웨어

C 코드가 기계 수준에서 어떻게 표현·번역·실행되는지 배웁니다. 기준 환경: x86-64 Linux, gcc 9.4, nasm 2.14, gdb 9.2.

| 폴더 | 핵심 개념 |
|---|---|
| [01_DataRepresentation](./01_DataRepresentation) | 비트 연산, 바이트 순서, 부호 있는/없는 정수 변환, 오버플로 검사 |
| [02_CompileDebug](./02_CompileDebug) | 전처리 → 컴파일 → 어셈블 → 링크, 정적 라이브러리, gdb |
| [03_IntegerAssembly](./03_IntegerAssembly) | NASM 문법, 레지스터, 정수 산술·비트 연산 명령, C/C++에서 어셈블리 함수 호출 |
| [04_LoopsArrays](./04_LoopsArrays) | 반복문의 어셈블리 패턴(jump-to-middle, guarded-do), 배열 인덱싱 |
| [lectures](./lectures) | 강의 1~7장 개념 정리 (정보의 표현, x86-64, 스택·제어, 프로시저, 데이터) |

각 폴더의 `README.md`는 실습 안내(빌드 명령 포함), `NOTES.md`는 개념 정리입니다.
