# 02. 언어 S 설계, AST, 어휘 분석기와 파서 구현 (Lecture 3: Parsing)

> 출처: `2026-2/프로그래밍언어론/Lecture03_Parsing.pdf`

## 한눈에 보기
```
소스 → [어휘 분석기 Lexer] → 토큰 → [파서 Parser] → AST → [인터프리터] → 실행 결과
```
- **Lexer**: 문자열을 토큰으로 쪼갠다 (`getToken()`)
- **Parser**: 재귀 하강 파싱을 하면서 **AST(추상 구문 트리)** 를 만들어 돌려준다
- **Interpreter**: AST 를 순회하며 의미대로 실행한다

---

## 1. 언어 S 의 설계 목표
1. 이해·구현이 쉬운 교육용 언어
2. **대화형 인터프리터** 방식 (`>>` 프롬프트)
3. 식, 실행문, 변수 선언, 함수 정의, 예외처리, 타입 검사 등 핵심 개념을 담음
4. **블록 구조**(중첩 블록) → 전역/지역 변수, 유효범위 개념
5. **강타입 언어**: 실행 전 타입 검사
6. Lexer → Parser → AST → 타입 검사기 → 인터프리터 순으로 점진적 구현

### 언어 S 문법 (EBNF)
```
<program> → {<command>}
<command> → <decl> | <stmt> | <function>
<decl>    → <type> id [= <expr>];
<stmt>    → id = <expr>;
          | '{' <stmts> '}'
          | if (<expr>) then <stmt> [else <stmt>]
          | while (<expr>) <stmt>
          | read id;
          | print <expr>;
          | let <decls> in <stmts> end;
<stmts>   → {<stmt>}
<decls>   → {<decl>}
<type>    → int | bool | string
```
예시:
```
let int x=0; int y=1; in
    read x;
    while (x>0) { y = y * x; x = x-1; }
    print y;
end;
```
(`let` 문 = 지역 변수 선언 + 실행문 묶음)

## 2. 파스 트리 vs AST
- **파스 트리**: 유도 과정을 그대로 (`<expr>`, `<term>`, `<factor>` 같은 중간 노드 포함)
- **AST**: 구조의 핵심(연산)만 남긴 요약 트리

`a + b * c`
```
파스 트리                         AST
<expr>                             +
 ├ <term> ─ <factor> ─ a          / \
 ├ +                             a   *
 └ <term>                           / \
    ├ <factor> ─ b                 b   c
    ├ *
    └ <factor> ─ c
```

### 언어 S 의 AST 노드
| 구문 | AST |
|---|---|
| 식 | `Expr = Identifier \| Value \| Binary \| Unary` |
| 이항식 | `Binary = Operator op; Expr expr1, expr2` |
| 단항식 | `Unary = Operator op; Expr expr` (예: `-(a+b)`) |
| 변수 선언 | `Decl = Type type; Identifier id; Expr expr` |
| 대입문 | `Assignment = Identifier id; Expr expr` |
| read / print | `Read = Identifier`, `Print = Expr` |
| 복합문 | `Stmts = Stmt*` (ArrayList) |
| if | `If = Expr expr; Stmt stmt1; Stmt stmt2` |
| while | `While = Expr expr; Stmt stmt` |
| let | `Let = Decls decls; Stmts stmts` |

```java
class Binary extends Expr {
    Operator op; Expr expr1, expr2;
    Binary(Operator o, Expr e1, Expr e2) { op = o; expr1 = e1; expr2 = e2; }
}
```

## 3. 어휘 분석기 (Lexer)
**토큰 = 문법의 터미널 기호**: 식별자, 상수 리터럴, 키워드(예약어), 연산자, 구분자

### 정규식 (Regular Expression)
| 표기 | 의미 |
|---|---|
| `x` | 문자 x |
| `M \| N` | M 또는 N |
| `MN` | M 다음 N (연결) |
| `M*` | 0번 이상 |
| `M+` | 1번 이상 (= MM*) |
| `M?` | 0 또는 1번 |
| `[a-z]` | 문자 집합 |

- `letter = [a-zA-Z]`, `digit = [0-9]`
- **NUMBER = digit+**
- **ID = letter (letter | digit)\***

### 언어 S 의 토큰
- 키워드: bool true false if then else int string while void fun return let in end read print
- 연산자: `= == < <= > >= ! != + - * / & |`
- 구분자: `{ } [ ] ( ) ; ,` EOF

```java
enum Token {
    BOOL("bool"), IF("if"), ..., PLUS("+"), SEMICOLON(";"),
    ID(""), NUMBER(""), STRLITERAL("");
    private String value;
    private Token(String v) { value = v; }
    public String value() { return value; }
}
```

### getToken() 동작
1. 첫 글자가 **알파벳** → 알파벳/숫자가 이어지는 동안 읽고, 키워드인지 식별자인지 판정
2. 첫 글자가 **숫자** → 숫자가 이어지는 동안 읽어 NUMBER
3. 그 외 → 연산자·구분자 판정 (`=` 다음에 `=` 이면 `==` 처럼 한 글자 더 확인)

### 연습: 정규식 → 문법
| 정규식 | 문법 |
|---|---|
| `ab*` | `S → Sb \| a` |
| `a*b*` | `S → AB, A → aA \| ε, B → bB \| ε` |
| `ab*c*` | `S → aBC, B → bB \| ε, C → cC \| ε` |

## 4. 파서 구현 (Java)
- 다음 토큰을 `token` 변수에 미리 읽어 두고(lookahead 1개), 그 토큰을 보고 어떤 규칙을 쓸지 정한다
```java
private String match(Token t) {      // 현재 토큰 확인 후 다음 토큰 읽기
    String value = token.value();
    if (token == t) token = lexer.getToken();
    else error(t);
    return value;
}

public Command command() {           // <command> → <decl> | <function> | <stmt>
    if (isType())             return decl();
    if (token == Token.FUN)   return function();
    if (token != Token.EOF)   return stmt();
    return null;
}

Stmt stmt() {                        // 첫 토큰으로 문장 종류 결정
    switch (token) {
        case ID:     return assignment();
        case LBRACE: match(Token.LBRACE); Stmts s = stmts(); match(Token.RBRACE); return s;
        case IF:     return ifStmt();
        case WHILE:  return whileStmt();
        case LET:    return letStmt();
        ...
        default: error("Illegal statement"); return null;
    }
}

If ifStmt() {                        // if ( <expr> ) then <stmt> [else <stmt>]
    match(Token.IF); match(Token.LPAREN);
    Expr e = expr();
    match(Token.RPAREN); match(Token.THEN);
    Stmt s1 = stmt();
    Stmt s2 = new Empty();           // else 가 없으면 빈 문장
    if (token == Token.ELSE) { match(Token.ELSE); s2 = stmt(); }
    return new If(e, s1, s2);
}

Expr aexp() {                        // <aexp> → <term> {+ <term> | - <term>}
    Expr e = term();
    while (token == Token.PLUS || token == Token.MINUS) {
        Operator op = new Operator(match(token));
        Expr t = term();
        e = new Binary(op, e, t);    // 왼쪽에 계속 쌓으므로 좌결합
    }
    return e;
}
```

`factor` (`<factor> → [-] ( number | '(' <aexp> ')' | id )`) 의 올바른 형태:
```java
Expr factor() {
    Operator op = null;
    if (token == Token.MINUS) op = new Operator(match(Token.MINUS));
    Expr e = null;
    switch (token) {
        case ID:      e = new Identifier(match(Token.ID)); break;
        case NUMBER: case STRLITERAL: e = literal(); break;
        case LPAREN:  match(Token.LPAREN); e = expr(); match(Token.RPAREN); break;
        default: error("Identifier | Literal");
    }
    return (op != null) ? new Unary(op, e) : e;
}
```
> ⚠️ 슬라이드의 factor 코드에는 `Operator op` 를 if 안에서 다시 선언하고, `new Unary(op, p)` 로 오타가 있다. 위처럼 바깥 `op` 에 대입하고 `e` 를 넘겨야 컴파일·동작한다.

## 5. 실습 #2: AST 출력
들여쓰기 수준(level)으로 트리를 표현한다.
```
>> x = x+10;
Assignment
  Identifier: x
  Binary
    Operator: +
    Identifier: x
    Value: 10
```
```java
public void display(int level) {      // Assignment
    Indent.display(level, "Assignment");
    id.display(level + 1);
    expr.display(level + 1);
}
```

⬅️ 이전: [01_구문과_문법.md](01_구문과_문법.md) · ➡️ 다음: [03_변수와_의미](../03_변수와_의미/01_변수_블록_유효범위.md)
