# Lab02: Lexer와 Parser

## 무엇을 배우나
- **Lexer(어휘 분석기)**: 문자 흐름을 `Token`(키워드, 식별자, 리터럴, 연산자)으로 자릅니다. `Token.java`는 토큰 종류를 enum으로 정의합니다.
- **Parser(구문 분석기)**: 재귀 하강 방식으로 문법을 따라가며 **AST(추상 구문 트리)** 를 만듭니다.
- **AST**: 괄호·세미콜론 같은 구문적 장식은 버리고 의미 있는 구조만 남긴 트리입니다. `AST.java`에 `Decl`, `Assignment`, `If`, `While`, `Let`, `Binary`, `Unary` 등의 노드 클래스가 있습니다.

## 포인트
- `stmt()`는 현재 토큰을 보고 어떤 문장인지(`if`, `while`, `let`, 대입 등) 고릅니다. 토큰 하나만 보고 규칙을 결정하는 것이 LL(1) 파싱의 핵심입니다.
- 식의 우선순위는 `expr → bexp → aexp → term → factor`처럼 단계별 메서드로 표현됩니다.

## 실행
```sh
javac *.java
java Parser test/hi0.s     # 파싱 결과(AST) 출력
```
