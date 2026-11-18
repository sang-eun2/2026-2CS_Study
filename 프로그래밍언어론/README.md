# 프로그래밍언어론

작은 교육용 언어 **S**를 단계적으로 구현하며 언어 처리기의 구조를 익힙니다.

```
소스 코드 ──Lexer──▶ 토큰 ──Parser──▶ AST ──TypeChecker──▶ (타입 오류 검사) ──Sint──▶ 실행 결과
```

| 폴더 | 핵심 개념 | 주요 파일 |
|---|---|---|
| [Lab01_Calc](./Lab01_Calc) | 문법(BNF/EBNF), 재귀 하강 파싱으로 수식 계산 | `Calc.java` |
| [Lab02_Parser](./Lab02_Parser) | 어휘 분석(Lexer)과 구문 분석(Parser), AST 생성 | `Lexer.java`, `Parser.java`, `AST.java` |
| [Lab03_Interpreter](./Lab03_Interpreter) | 의미론, 상태(State)와 환경, 블록 유효범위 | `Sint.java`, `State.java` |
| [Lab04_TypeChecker_Arrays](./Lab04_TypeChecker_Arrays) | 정적 타입 검사, 배열 선언·사용·대입 | `TypeChecker.java`, `TypeEnv.java` |

## 실행 방법 (공통)
```sh
cd Lab03_Interpreter
javac *.java
java Sint test/hi0.s      # 언어 S 프로그램 실행
```
`test/` 폴더의 `*.s` 파일이 예제 프로그램입니다.
