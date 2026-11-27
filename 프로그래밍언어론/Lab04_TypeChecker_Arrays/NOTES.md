# Lab04: 타입 검사기와 배열

## 타입 검사기 (`TypeChecker.java`)
- 실행 전에 프로그램 전체를 훑어 **타입 오류를 미리 잡는** 정적 검사입니다.
- `TypeEnv`(타입 환경)는 `<id, Type>` 스택입니다. `let` 블록에서 `addType`, 블록이 끝나면 `deleteType`을 합니다.
- 노드별 규칙 예시
  - `Binary`: `+ - * /`는 양쪽이 int, `&& ||`는 bool, 비교 연산의 결과는 bool
  - `Assignment`: 왼쪽 변수의 타입과 오른쪽 식의 타입이 같아야 함
  - `If` / `While`: 조건식은 bool이어야 함
  - 같은 블록에서 같은 이름을 두 번 선언하면 오류(`duplicate`)
- 오류가 나면 `checkError`가 메시지를 출력하고 실행하지 않습니다.

## 배열 확장 (과제 #4 개념)
- 문법: `int a[10];` 선언, `a[i] = e;` 대입, `a[i]` 사용
- 의미: 배열 전체를 바인딩 하나 `<a, Value[]>`로 저장하고, 원소 대입은 그 배열을 제자리에서 바꿉니다.

### 1. 배열의 정의
- **배열 (array)**: 같은 타입의 변수들이 연속적으로 모인 자료구조.
- **배열 원소 (array element)**: 배열을 이루는 각각의 변수. `배열 이름 + 인덱스`로 나타낸다. 예: `a[2]`
- 언어 S에서 인덱스는 0부터 시작한다. 크기가 `n`인 배열의 유효한 인덱스는 `0 … n-1`이다.

### 2. 문법 확장 (BNF)
```
<decl>   → <type> id ;  |  <type> id = <expr> ;  |  <type> id[n] ;        // 배열 선언, n은 정수 리터럴
<stmt>   → … | id = <expr> ;  |  id[<expr>] = <expr> ;                     // 원소 대입
<factor> → [-]( id | id[<expr>] | literal | ( <aexp> ) )                   // 원소 사용
```
- 선언에서 크기 `n`은 **리터럴만** 올 수 있다 (`literal()`). 사용과 대입에서 인덱스는 **임의의 식**이 올 수 있다 (`expr()`). 그래서 `a[a[1]-4]`처럼 중첩된 인덱스도 쓸 수 있다.
- 파서는 재귀 하강 (recursive descent) 방식이다. `id` 다음 토큰이 `[` (LBRACKET)인지 **한 토큰을 미리 보고 (lookahead)** 일반 변수와 배열을 구분한다.

### 3. AST 노드
| 구문 | AST |
|---|---|
| `<type> id[n];` | `Decl(String id, Type t, int n)`: `arraysize = n` (스칼라 변수는 0) |
| `id[<expr>]` | `Array(Identifier id, Expr index)` (Expr의 하위 클래스) |
| `id[<expr>] = <expr>;` | `Assignment(Array ar, Expr e)`: `ar != null`이면 원소 대입 |
| 배열 값 | `Value(Value[])`: type = `ARRAY`, `arrValue()`로 꺼낸다 |

### 4. 상태 (State)와 메모리 모델
- State는 `<id, Value>` 쌍을 쌓는 **스택**이다. `let` 블록에 들어가면 `allocate` (push)를 하고, 블록을 나오면 `free` (pop)를 한다. 이것이 정적 유효범위와 블록 구조를 구현한다.
- 배열은 **바인딩 하나**로 저장된다: `<a, Value(Value[n])>`. 슬라이드 8의 그림처럼 `id`가 Value를 가리키고, 그 Value가 원소 n개를 담은 배열을 가리킨다.
  - 덕분에 `free()`는 선언 하나당 `pop()` 한 번으로 배열 전체를 해제할 수 있다.
- **할당**: `new Value[n]`을 만들고 각 원소를 `new Value(type)`으로 초기화한다 (int→0, bool→false, string→""). 초기화하지 않으면 원소가 `null`이어서, 대입하기 전에 읽으면 NPE가 난다.

### 5. 의미 (Semantics)
- **원소 사용** `V(a[e])`: `state.get(a)`로 배열을 찾고, 인덱스 `V(e)`를 계산한 뒤 `vs[index]`를 반환한다.
- **원소 대입** `a[e1] = e2`:
  1. 오른쪽 값 `v = V(e2)`를 먼저 계산한다 (기본 코드의 순서).
  2. 인덱스 `V(e1)`를 계산한다.
  3. `ar[index] = v`로 **제자리 변경**한다. `state.set(a, v)`를 쓰면 배열 전체가 스칼라 하나로 바뀌어 버리므로 쓰면 안 된다.
  4. Java 배열은 참조이기 때문에 State에 다시 넣지 않아도 변경이 반영된다.
- 이것은 l-value (위치)와 r-value (값)의 구분이다. 대입문 왼쪽의 `a[i]`는 위치를 뜻하고, 오른쪽의 `a[i]`는 값을 뜻한다.

### 6. 오류와 경계 상황
- 범위를 벗어난 인덱스: Java의 `ArrayIndexOutOfBoundsException`이 발생한다. Sint의 main이 이를 잡아 `Error: …`를 출력하고 다음 명령을 계속 실행한다. 직접 실행해 확인했다.
- 제공된 `Assignment(Array, Expr)` 생성자는 `id`를 설정하지 않는다. 그래서 Parser의 AST 출력에서 NPE가 났다. Parser에서 `id`를 함께 넣어 고쳤다.
- 타입 검사 (TypeChecker)는 이번 과제의 TODO 범위가 아니다. Sint는 TypeChecker를 호출하지 않는다.

### 7. 테스트 결과 (슬라이드 p.4와 일치하는지 교차검증함)
| 파일 | 기대 출력 | 실제 출력 |
|---|---|---|
| q1 | 7 | 7 ✓ |
| q2 | Sum / 10 | ✓ |
| q3 | Max / 6 | ✓ |
| q4 | Sum of positive numbers / 22 | ✓ (원소는 −12,−14,−14,−12,−8,−2,6,16) |
| q5 | A U F G A B E true | ✓ (ar2 = [1,3,0,2,4,6], ar3[2] = false) |

## 실행
```sh
javac *.java
java Sint ../Lab03_Interpreter/test/hi0.s
```
