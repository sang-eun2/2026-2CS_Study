# 02. PL/SQL 안의 SQL, 커서, 예외 처리 (Part 7: 저장 프로시저 프로그래밍(2))

> 출처: `2026-2/데이터베이스설계/07. PLSQL(2).pdf`

## 한눈에 보기
- `SELECT ... INTO` 는 **정확히 한 행**만 → 0행이면 `NO_DATA_FOUND`, 2행 이상이면 `TOO_MANY_ROWS`
- 여러 행은 **명시적 커서**: DECLARE → OPEN → FETCH(반복) → CLOSE. **FOR 문**을 쓰면 자동
- 예외 3종: **미리 정의된** / **미리 정의되지 않은**(PRAGMA EXCEPTION_INIT) / **사용자 정의**(RAISE)

---

## 1. PL/SQL 안의 SQL
```sql
SELECT 컬럼목록 INTO 변수 | 레코드 FROM 테이블 WHERE 조건;
```
- shop 테이블에 1015, 1016 두 행이 있을 때
  - `SELECT shop_no, shop_name INTO v_no, v_name FROM shop;` → **TOO_MANY_ROWS**
  - `... WHERE shop_no = 1000;` → **NO_DATA_FOUND**
- INSERT, UPDATE, DELETE 는 SQL 과 같고 변수를 그대로 쓸 수 있음
```sql
SELECT shop_no, shop_name INTO v_no, v_name FROM shop WHERE shop_name = 'MUSIC_STAR';
INSERT INTO shop(shop_no, shop_name) VALUES (v_no + 1, v_name);
UPDATE shop SET shop_name = v_name WHERE shop_name = 'MUSIC_STAR';
DELETE FROM shop WHERE shop_name = 'PICTURE_STAR';
```

## 2. 커서
- SQL 을 실행하면 서버가 파싱·실행용 메모리 영역을 여는데 그게 **커서**. 이름을 붙이면 그 결과에 접근 가능

### 묵시적 커서
- **모든 DML 과 PL/SQL SELECT** 에 자동. 실행 순간 열리고 닫힘
| 속성 | 의미 |
|---|---|
| `SQL%ROWCOUNT` | 영향받은 행 수 |
| `SQL%FOUND` | 1행 이상이면 TRUE |
| `SQL%NOTFOUND` | 0행이면 TRUE |
| `SQL%ISOPEN` | **항상 FALSE** (실행 후 바로 닫히니까) |
```sql
UPDATE emp SET sal = sal * 1.1 WHERE empno = v_empno;
v_update_row := SQL%ROWCOUNT;      -- 급여 인상된 사원 수
```

### 명시적 커서 ⭐
```
DECLARE → OPEN → FETCH → (비었나? 아니면 다시 FETCH) → CLOSE
```
| 단계 | 문법 | 하는 일 |
|---|---|---|
| 선언 | `CURSOR c IS SELECT ...;` | 이름 있는 SQL 영역 |
| 열기 | `OPEN c;` | 질의 실행, 결과 집합 준비 |
| 읽기 | `FETCH c INTO v1, v2;` | 현재 행을 변수로, 한 행씩. **컬럼 수·타입이 변수와 같아야** |
| 닫기 | `CLOSE c;` | 자원 해제. 닫은 뒤 FETCH 불가, 다시 OPEN 가능 |

| 속성 | 의미 |
|---|---|
| `c%ROWCOUNT` | 지금까지 FETCH 한 행 수 |
| `c%FOUND` / `c%NOTFOUND` | 마지막 FETCH 가 행을 반환했나 / 안 했나 (**루프 종료 검사**) |
| `c%ISOPEN` | 열려 있나 |

```sql
DECLARE
    v_empno emp.empno%TYPE; v_ename emp.ename%TYPE; v_sal emp.sal%TYPE;
    CURSOR emp_list IS SELECT empno, ename, sal FROM emp;
BEGIN
    OPEN emp_list;
    LOOP
        FETCH emp_list INTO v_empno, v_ename, v_sal;
        EXIT WHEN emp_list%NOTFOUND;
    END LOOP;
    DBMS_OUTPUT.PUT_LINE('전체데이터 수 : ' || emp_list%ROWCOUNT);
    CLOSE emp_list;
END;
```

### FOR 문 커서 (가장 간단)
- OPEN, FETCH, CLOSE 와 **레코드 변수 선언이 자동**
```sql
FOR emp_list IN dept_cnt LOOP
    DBMS_OUTPUT.PUT_LINE('부서명 : ' || emp_list.dname || ', 사원수 : ' || emp_list.cnt);
END LOOP;
```
(`FOR r IN (SELECT ...) LOOP` 처럼 질의를 바로 써도 됨)

### 매개변수 커서
```sql
CURSOR emp_list(v_deptno emp.deptno%TYPE) IS
    SELECT ename FROM emp WHERE deptno = v_deptno;
FOR emplst IN emp_list(10) LOOP ... END LOOP;   -- OPEN 될 때 값 전달
```

### WHERE CURRENT OF
- ROWID 없이 **커서가 방금 FETCH 한 행**을 수정·삭제
- 커서 선언에 **`FOR UPDATE`** 가 반드시 있어야 함
```sql
CURSOR emp_list IS SELECT empno FROM emp WHERE empno = 7934 FOR UPDATE;
FOR emplst IN emp_list LOOP
    UPDATE emp SET job = 'SALESMAN' WHERE CURRENT OF emp_list;
END LOOP;
```

## 3. 예외 처리
```sql
EXCEPTION
    WHEN 예외1 [OR 예외2] THEN ...;
    WHEN 예외3 THEN ...;
    WHEN OTHERS THEN ...;      -- 반드시 맨 마지막
```
- 예외가 나면 여러 처리부 중 **하나로만** 트랩

| 종류 | 설명 | 처리 |
|---|---|---|
| **미리 정의된** | 자주 나는 약 20개 | 선언 없이 이름으로 자동 트랩 |
| **미리 정의되지 않은** | 그 밖의 오라클 서버 오류 | 선언부에서 이름 선언 + `PRAGMA EXCEPTION_INIT` 으로 오류 번호와 연결 |
| **사용자 정의** | 개발자가 정한 조건 위반 | 선언 후 실행부에서 **`RAISE`** |

### 미리 정의된 예외
| 이름 | 상황 |
|---|---|
| NO_DATA_FOUND | SELECT INTO 결과 0행 |
| TOO_MANY_ROWS | SELECT INTO 결과 2행 이상 |
| ZERO_DIVIDE | 0으로 나눔 |
| DUP_VAL_ON_INDEX | UNIQUE 컬럼 중복 INSERT |
| INVALID_CURSOR | 잘못된 커서 연산 |
| CURSOR_ALREADY_OPEN | 이미 열린 커서를 다시 OPEN |
| INVALID_NUMBER | 숫자 아님 ('3D2') |
| VALUE_ERROR | 계산·변환·절단 오류 |
| TIMEOUT_ON_RESOURCE, STORAGE_ERROR, PROGRAM_ERROR, ROWTYPE_MISMATCH | 자원 대기 시간 초과, 메모리 부족, 내부 오류, 커서 변수 타입 불일치 |

### 미리 정의되지 않은 예외: 3단계
```sql
DECLARE
    not_null_test EXCEPTION;                       -- 1. 이름 선언
    PRAGMA EXCEPTION_INIT(not_null_test, -1400);   -- 2. 오류 번호와 연결 (ORA-01400: NULL 삽입 불가)
BEGIN
    INSERT INTO emp(ename, deptno) VALUES ('tiger', 30);   -- empno 누락
EXCEPTION
    WHEN not_null_test THEN DBMS_OUTPUT.PUT_LINE('not null 에러 발생');   -- 3. 참조
END;
```

### 사용자 정의 예외: 3단계
```sql
DECLARE
    user_define_error EXCEPTION;                  -- 1. 선언
    cnt NUMBER;
BEGIN
    SELECT COUNT(empno) INTO cnt FROM emp WHERE deptno = 234;
    IF cnt < 5 THEN RAISE user_define_error; END IF;    -- 2. 발생
EXCEPTION
    WHEN user_define_error THEN                    -- 3. 참조
        RAISE_APPLICATION_ERROR(-20001, '사원 부족');
END;
```
- **`RAISE_APPLICATION_ERROR(코드, 메시지)`**: 코드는 **−20000 ~ −20999** 범위의 사용자 오류로 호출자에게 전달

### SQLCODE, SQLERRM
- `WHEN OTHERS` 로 잡힌 오류의 실제 번호·메시지 확인
| SQLCODE | 의미 |
|---|---|
| 0 | 성공 |
| 1 | 사용자 정의 예외 |
| +100 | NO_DATA_FOUND |
| 음수 | 그 밖의 오라클 서버 오류 |
```sql
SELECT * INTO v_emp FROM emp;   -- 여러 행
-- ERR CODE : -1422 / ORA-01422: exact fetch returns more than requested number of rows
```

⬅️ 이전: [01_PLSQL_기초와_제어구조.md](01_PLSQL_기초와_제어구조.md) · ➡️ 다음: [03_프로시저_함수_트리거.md](03_프로시저_함수_트리거.md)
