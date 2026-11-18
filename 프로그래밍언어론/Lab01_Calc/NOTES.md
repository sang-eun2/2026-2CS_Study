# Lab01: 재귀 하강 계산기

## 무엇을 배우나
- **문법 → 함수 대응**: EBNF 규칙 하나가 메서드 하나가 됩니다.
  ```
  <expr>   → <term> { ('+'|'-') <term> }
  <term>   → <factor> { ('*'|'/') <factor> }
  <factor> → number | '(' <expr> ')'
  ```
- **우선순위와 결합성**: `*`, `/`가 더 깊은 규칙(term)에 있으므로 먼저 계산됩니다. `{ ... }` 반복을 while 루프로 돌리면 왼쪽 결합이 됩니다.
- **토큰 한 개 미리 보기(lookahead)**: `getToken()`이 다음 토큰을 읽어 두고, `match()`가 기대한 토큰인지 확인한 뒤 넘어갑니다.

## 코드 읽는 순서
1. `getToken()`: 공백을 건너뛰고, 숫자면 `NUMBER`, 아니면 문자를 그대로 반환
2. `expr()` → `term()` → `factor()`: 문법 규칙 그대로의 재귀 호출
3. `main`: 한 줄씩 읽어 결과 출력

## 실행
```sh
javac Calc.java && java Calc
```
