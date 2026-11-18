# 01. PL/SQL 기초: 블록, 데이터 타입, 제어 구조 (Part 6: 저장 프로시저 프로그래밍(1))

> 출처: `2026-2/데이터베이스설계/06. PLSQL(1).pdf`

## 한눈에 보기
- **PL/SQL** = Oracle's Procedural Language extension to SQL. SQL 에 **변수, 조건, 반복** 같은 절차적 제어를 더한 Oracle 고유 언어
- ESQL·SQLJ 처럼 범용 언어에 SQL 을 넣는 방식이 아니라 **오라클 자체 언어**
- 실행: PL/SQL 엔진이 **절차적 문장은 직접**, **SQL 문은 SQL 실행기**로 보냄

---

## 1. 블록 구조
```sql
DECLARE      -- 선택: 변수, 상수, 커서, 사용자 정의 예외
BEGIN        -- 필수: SQL 문, PL/SQL 제어문
EXCEPTION    -- 선택: 오류 발생 시 동작
END;         -- 필수
/            -- SQL*Plus 에서 블록 실행
```
- 블록 안에 하위 블록을 **얼마든지 중첩** 가능

| 블록 유형 | 설명 |
|---|---|
| **익명 블록** | 이름 없음, 한 번 실행 |
| **저장 프로시저 / 함수** | 이름 있음, 매개변수, 반복 사용 |
| **패키지** | 관련 프로시저·함수 묶음 |
| **트리거** | 테이블에 연결되어 **이벤트 시 자동 실행** |

## 2. 문법 요소
- **식별자**: 알파벳으로 시작, 30자 이내, 특수문자 일부 가능(&, -, /, 공백 제외), **대소문자 구분 안 함**. 큰따옴표로 감싸면 예약어·공백 사용 가능하고 대소문자 구분
| 연산자 | 의미 |
|---|---|
| `+ - * / **` | 산술 (`**` 지수) |
| `= < > <> != <= >=` | 관계 |
| **`:=`** | **대입** |
| `..` | 범위 (`1..100`) |
| `\|\|` | 문자열 연결 |
| `%` | 속성 (`%TYPE`, `%ROWTYPE`, `%FOUND`) |
| `--` / `/* */` | 한 줄 / 여러 줄 주석 |
| `<< >>` | 레이블 |
- 리터럴: 숫자(123, 1.43E5), 문자('STRING'), 불리언(TRUE, FALSE, NULL)

### 결과 출력
```sql
SET SERVEROUTPUT ON;            -- 이걸 켜야 출력이 보임
BEGIN DBMS_OUTPUT.PUT_LINE('HELLO'); END;
/
```

## 3. 변수와 데이터 타입
```
식별자 [CONSTANT] 데이터타입 [NOT NULL] [:= 초기값];
```
- `CONSTANT`, `NOT NULL` 은 **반드시 초기화**. 초기값이 없으면 NULL
```sql
v_gender     CHAR(1);
v_count      BINARY_INTEGER := 0;
v_total_sal  NUMBER(9,2) := 0;
v_order_date DATE := SYSDATE + 7;
c_tax_rate   CONSTANT NUMBER(3,2) := 8.25;
v_valid      BOOLEAN NOT NULL := TRUE;
```
| 스칼라 타입 | 설명 |
|---|---|
| BINARY_INTEGER | −2147483647 ~ 2147483647 정수 |
| NUMBER(p,s) | 정수·실수 |
| CHAR(n) / VARCHAR2(n) / LONG | 고정 / 가변 / 긴 가변 문자 (32767바이트까지) |
| DATE | 날짜·시간 |
| BOOLEAN | TRUE, FALSE, NULL (PL/SQL 전용) |

### %TYPE ⭐
- **컬럼(또는 이미 선언한 변수)의 타입을 그대로** 따라감 → 컬럼 타입이 바뀌어도 코드 수정 불필요
```sql
DECLARE
    v_empno emp.empno%TYPE;
    v_ename emp.ename%TYPE;
    v_sal   emp.sal%TYPE;
BEGIN
    SELECT empno, ename, sal INTO v_empno, v_ename, v_sal FROM emp WHERE empno = 7521;
    DBMS_OUTPUT.PUT_LINE('사원이름 : ' || v_ename);
END;
```

### 복합 타입
| 타입 | 특징 |
|---|---|
| **%ROWTYPE** | 테이블·뷰의 **한 행 전체 구조**를 그대로. 한 행 조회에 편리 (`v_emp emp%ROWTYPE;` → `v_emp.ename`) |
| **PL/SQL 테이블** | 1차원 배열과 비슷. BINARY_INTEGER 인덱스 + 한 컬럼 값. 선언 시 초기화 불가, 크기 제한 없이 자동 증가 |
| **PL/SQL 레코드** | 사용자 정의 구조체. 필드마다 이름·타입, 선언 시 초기화 가능 |

```sql
-- PL/SQL 테이블
TYPE ename_table IS TABLE OF emp.ename%TYPE INDEX BY BINARY_INTEGER;
ename_tab ename_table;
FOR emp_list IN (SELECT empno, ename FROM emp WHERE deptno = 20) LOOP
    i := i + 1;  ename_tab(i) := emp_list.ename;
END LOOP;

-- PL/SQL 레코드
TYPE emp_record IS RECORD (v_empno NUMBER, v_ename VARCHAR2(30));
emp_rec emp_record;
SELECT empno, ename INTO emp_rec.v_empno, emp_rec.v_ename FROM emp WHERE empno = 7369;
```
PL/SQL 테이블 속성
| 속성 | 의미 |
|---|---|
| `COUNT` | 전체 행 수 |
| `DELETE`, `DELETE(3)`, `DELETE(2,3)` | 전체 / 3번 / 2~3번 삭제 |
| `EXISTS(1)` | 1번 행 존재 여부 |
| `FIRST`, `LAST` | 첫/마지막 **인덱스 번호** (70, 75, 73 을 넣으면 FIRST=70, LAST=75) |
| `NEXT(i)`, `PRIOR(i)` | 다음/이전 인덱스 번호 (빈 인덱스를 건너뜀) |

## 4. 제어 구조
### 조건: IF
```sql
IF condition THEN ...;
[ELSIF condition THEN ...;]     -- ELSEIF 가 아니라 ELSIF
[ELSE ...;]
END IF;
```
```sql
SELECT TO_CHAR(SYSDATE, 'MM') INTO sMonth FROM DUAL;
IF (sMonth >= '03' AND sMonth <= '08') THEN DBMS_OUTPUT.PUT_LINE('1학기');
ELSE DBMS_OUTPUT.PUT_LINE('2학기');
END IF;
```

### 반복: 1~100 합을 세 가지로
```sql
LOOP                          -- 기본 LOOP: EXIT 로 탈출
    i := i + 1;  nSum := nSum + i;
    EXIT WHEN i >= 100;
END LOOP;

FOR i IN 1..100 LOOP          -- FOR: 인덱스 자동 선언·증가, REVERSE 로 역순
    nSum := nSum + i;
END LOOP;

WHILE i < 100 LOOP            -- WHILE: 조건이 참인 동안
    i := i + 1;  nSum := nSum + i;
END LOOP;
```

### 순차 제어
- `GOTO 레이블;` + `<<레이블>>` : 지정한 곳으로 건너뜀
- `NULL;` : **아무것도 안 함** (예: `WHEN ZERO_DIVIDE THEN NULL;` 로 예외 무시)

➡️ 다음: [02_SQL_커서_예외처리.md](02_SQL_커서_예외처리.md)
