# Lab04: 타입 검사기와 배열

배열 개념은 같은 폴더의 [CONCEPTS.md](./CONCEPTS.md)에 자세히 정리했습니다.

## 타입 검사기 (`TypeChecker.java`)
- 실행 전에 프로그램 전체를 훑어 **타입 오류를 미리 잡는** 정적 검사입니다.
- `TypeEnv`(타입 환경)는 `<id, Type>` 스택입니다. `let` 블록에서 `addType`, 블록이 끝나면 `deleteType`을 합니다.
- 노드별 규칙 예시
  - `Binary`: `+ - * /`는 양쪽이 int, `&& ||`는 bool, 비교 연산의 결과는 bool
  - `Assignment`: 왼쪽 변수의 타입과 오른쪽 식의 타입이 같아야 함
  - `If` / `While`: 조건식은 bool이어야 함
  - 같은 블록에서 같은 이름을 두 번 선언하면 오류(`duplicate`)
- 오류가 나면 `checkError`가 메시지를 출력하고 실행하지 않습니다.

## 배열 확장
- 문법: `int a[10];` 선언, `a[i] = e;` 대입, `a[i]` 사용
- 의미: 배열 전체를 바인딩 하나 `<a, Value[]>`로 저장하고, 원소 대입은 그 배열을 제자리에서 바꿉니다.

## 실행
```sh
javac *.java
java Sint ../Lab03_Interpreter/test/hi0.s
```
