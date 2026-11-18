# 01. SQL: 데이터 정의·조작·제어, 뷰, 삽입 SQL (00. SQL)

> 출처: `2026-2/데이터베이스설계/00. SQL.pdf` (참고서: 김연희, 『데이터베이스 개론』)
> 슬라이드의 예시 질의는 그림이라 텍스트로 추출되지 않아, 같은 판매 데이터베이스(고객·제품·주문)로 예시를 다시 작성함.

## 한눈에 보기
| 분류 | 하는 일 | 명령 |
|---|---|---|
| **DDL** (정의어) | 테이블 생성·변경·삭제 | CREATE, ALTER, DROP |
| **DML** (조작어) | 검색·삽입·수정·삭제 | SELECT, INSERT, UPDATE, DELETE |
| **DCL** (제어어) | 권한 부여·취소 | GRANT, REVOKE |

- SQL = 관계 DB 표준 질의어, **비절차적** 언어 (무엇을 원하는지만 기술). SEQUEL(SYSTEM R)에서 유래, ANSI/ISO 표준
- 사용 방식: **대화식 SQL**(직접 실행) / **삽입 SQL**(프로그램 안에)
- 세미콜론으로 끝, 키워드는 대소문자 구분 안 함, **작은따옴표 안 문자열은 구분**

---

## 1. 데이터 정의 (DDL)
### CREATE TABLE
```sql
CREATE TABLE 고객 (
    고객아이디 VARCHAR(20) NOT NULL,
    고객이름   VARCHAR(10) NOT NULL,
    나이       INT,
    등급       VARCHAR(10) NOT NULL,
    직업       VARCHAR(20),
    적립금     INT DEFAULT 0,
    PRIMARY KEY (고객아이디)
);

CREATE TABLE 제품 (
    제품번호 CHAR(3) NOT NULL,
    제품명   VARCHAR(20),
    재고량   INT,
    단가     INT,
    제조업체 VARCHAR(20),
    PRIMARY KEY (제품번호),
    CHECK (재고량 >= 0 AND 재고량 <= 10000)
);

CREATE TABLE 주문 (
    주문번호 CHAR(3) NOT NULL,
    주문고객 VARCHAR(20),
    주문제품 CHAR(3),
    수량     INT,
    배송지   VARCHAR(30),
    주문일자 DATE,
    PRIMARY KEY (주문번호),
    FOREIGN KEY (주문고객) REFERENCES 고객(고객아이디),
    FOREIGN KEY (주문제품) REFERENCES 제품(제품번호)
);
```
| 키워드 | 의미 |
|---|---|
| `NOT NULL` | 널 불허 |
| `DEFAULT 값` | 기본값 (문자·날짜는 작은따옴표) |
| `PRIMARY KEY` | 기본키 (복합키 가능: `PRIMARY KEY(주문고객, 주문제품)`) |
| `UNIQUE` | **대체키**: 유일하지만 기본키와 달리 **널 허용** |
| `FOREIGN KEY ... REFERENCES` | 외래키 |
| `CHECK` | 무결성 제약. `CONSTRAINT 이름 CHECK(...)` 로 이름 부여 가능 |

### 참조 무결성 옵션 (참조되는 투플을 삭제·변경할 때)
| 옵션 | 동작 (부서 '홍보부' 삭제 시 사원 '정소화'는?) |
|---|---|
| `NO ACTION` | 삭제·변경 자체를 거부 |
| `CASCADE` | 관련 투플도 함께 삭제 / 외래키 값도 함께 변경 |
| `SET NULL` | 외래키를 NULL 로 |
| `SET DEFAULT` | 외래키를 기본값으로 |
```sql
FOREIGN KEY (소속부서) REFERENCES 부서(부서번호) ON DELETE CASCADE ON UPDATE CASCADE
```

### ALTER TABLE / DROP TABLE
```sql
ALTER TABLE 고객 ADD 가입날짜 DATE;                         -- 속성 추가
ALTER TABLE 고객 DROP COLUMN 가입날짜;                       -- 속성 삭제
ALTER TABLE 고객 ADD CONSTRAINT CHK_AGE CHECK (나이 >= 20);  -- 제약 추가
ALTER TABLE 고객 DROP CONSTRAINT CHK_AGE;                    -- 제약 삭제
DROP TABLE 배송업체;
```
- 삭제할 속성·테이블을 **참조하는 제약이 있으면 거부** → 관련 제약조건을 먼저 삭제

## 2. 데이터 조작 (DML)
### SELECT 기본
```sql
SELECT 제조업체 FROM 제품;               -- ALL (기본, 중복 허용)
SELECT DISTINCT 제조업체 FROM 제품;      -- 중복 제거
SELECT 제품명, 단가 AS 가격 FROM 제품;   -- 별칭 (공백 있으면 오라클은 큰따옴표)
SELECT 제품명, 단가 + 500 AS "조정 단가" FROM 제품;   -- 산술식 (실제 값은 안 바뀜)
SELECT * FROM 고객;
```

### 조건 검색
```sql
SELECT 제품명, 재고량 FROM 제품 WHERE 제조업체 = '한빛제과' AND 단가 >= 2000;
SELECT 고객이름 FROM 고객 WHERE 고객이름 LIKE '김%';   -- % 0개 이상, _ 한 글자
SELECT 고객아이디 FROM 고객 WHERE 고객아이디 LIKE '_____';  -- 정확히 5자
SELECT 고객이름 FROM 고객 WHERE 나이 IS NULL;           -- = NULL 은 안 됨
```
- **널과의 비교는 모두 거짓** → `IS NULL` / `IS NOT NULL`

### 정렬
```sql
SELECT 주문제품, 수량, 주문일자 FROM 주문 WHERE 수량 >= 10
ORDER BY 주문제품 ASC, 수량 DESC;
```
- 기본 ASC. **널은 오름차순에서 마지막, 내림차순에서 맨 앞** (오라클 기준)

### 집계 함수와 그룹
| 함수 | 의미 |
|---|---|
| COUNT, SUM, AVG, MAX, MIN | 개수, 합, 평균, 최대, 최소 |
- **널은 제외**하고 계산 → 정확한 행 수는 `COUNT(*)` 나 기본키로
- **WHERE 절에 못 씀** → SELECT 절이나 **HAVING** 절에서만
```sql
SELECT COUNT(DISTINCT 제조업체) AS "제조업체 수" FROM 제품;

SELECT 주문제품, SUM(수량) AS 총주문수량
FROM 주문
GROUP BY 주문제품
HAVING SUM(수량) >= 30;
```
- GROUP BY 를 쓰면 SELECT 에는 **그룹 기준 속성과 집계 함수만** 쓸 수 있다

### 조인
```sql
-- 조인 조건을 WHERE 에
SELECT 제품.제품명 FROM 제품, 주문
WHERE 주문.주문고객 = 'banana' AND 제품.제품번호 = 주문.주문제품;

-- 표준 INNER JOIN ... ON (나이 30 이상 고객이 주문한 제품번호와 주문일자)
SELECT 주문.주문제품, 주문.주문일자
FROM 고객 INNER JOIN 주문 ON 고객.고객아이디 = 주문.주문고객
WHERE 고객.나이 >= 30;

-- 외부 조인: 주문 안 한 고객도 포함
SELECT 고객.고객이름, 주문.주문제품, 주문.주문일자
FROM 고객 LEFT OUTER JOIN 주문 ON 고객.고객아이디 = 주문.주문고객;
```
- 조인 속성은 이름은 달라도 **도메인이 같아야** 함 (보통 외래키)
- 같은 이름 속성 구분을 위해 `테이블.속성`, 별명(`FROM 고객 c`) 사용 가능
- 외부 조인: **LEFT**(왼쪽 테이블 전부) / **RIGHT** / **FULL**

### 부속 질의문 (서브쿼리)
- 괄호로 묶고, **ORDER BY 불가**. 부속 질의를 먼저 실행해 그 결과로 상위 질의 실행
| 종류 | 연결 연산자 |
|---|---|
| **단일 행** | `=, <>, >, >=, <, <=` |
| **다중 행** | `IN, NOT IN, EXISTS, NOT EXISTS, ALL, ANY` (비교 연산자 불가) |
```sql
-- 단일 행: '달콤비스킷'과 같은 제조업체의 제품
SELECT 제품명, 단가 FROM 제품
WHERE 제조업체 = (SELECT 제조업체 FROM 제품 WHERE 제품명 = '달콤비스킷');

-- 단일 행: 적립금이 가장 많은 고객
SELECT 고객이름, 적립금 FROM 고객 WHERE 적립금 = (SELECT MAX(적립금) FROM 고객);

-- 다중 행: banana 가 주문한 제품
SELECT 제품명, 제조업체 FROM 제품
WHERE 제품번호 IN (SELECT 주문제품 FROM 주문 WHERE 주문고객 = 'banana');

-- ALL: 대한식품 모든 제품보다 비싼 제품
SELECT 제품명, 단가 FROM 제품
WHERE 단가 > ALL (SELECT 단가 FROM 제품 WHERE 제조업체 = '대한식품');

-- EXISTS: 2022-03-15 에 주문한 고객
SELECT 고객이름 FROM 고객
WHERE EXISTS (SELECT * FROM 주문
              WHERE 주문일자 = '2022-03-15' AND 주문.주문고객 = 고객.고객아이디);
```

### INSERT / UPDATE / DELETE
```sql
INSERT INTO 고객(고객아이디, 고객이름, 나이, 등급, 직업, 적립금)
VALUES ('strawberry', '최유경', 30, 'vip', '공무원', 100);
INSERT INTO 고객 VALUES ('tomato', '정은심', 36, 'gold', NULL, 4000);   -- 속성 순서대로, 널 직접

INSERT INTO 한빛제품(제품명, 재고량, 단가)                               -- 부속 질의로 삽입
SELECT 제품명, 재고량, 단가 FROM 제품 WHERE 제조업체 = '한빛제과';

UPDATE 제품 SET 단가 = 단가 * 1.1;                                      -- WHERE 없으면 전체
UPDATE 주문 SET 수량 = 5
WHERE 주문고객 IN (SELECT 고객아이디 FROM 고객 WHERE 고객이름 = '정소화');

DELETE FROM 주문 WHERE 주문일자 = '2022-05-22';
DELETE FROM 주문;            -- 모든 투플 삭제 → 빈 테이블 남음 (DROP TABLE 과 다름)
```

## 3. 데이터 제어 (DCL)
- 접근 제어: 로그인한 사용자만, 허용된 권한 내에서만. 객체는 **만든 사용자만** 권한을 가짐
### 객체 권한
```sql
GRANT SELECT ON 고객 TO kim;
GRANT INSERT, DELETE ON 고객 TO kim, park;
GRANT UPDATE(등급) ON 고객 TO lee;            -- UPDATE·SELECT 는 일부 속성만도 가능
GRANT SELECT ON 고객 TO PUBLIC;               -- 모든 사용자
GRANT SELECT ON 고객 TO hong WITH GRANT OPTION;   -- 받은 권한을 남에게 줄 수 있게
REVOKE SELECT ON 고객 FROM hong CASCADE;       -- hong 이 준 권한까지 연쇄 취소 (RESTRICT 는 연쇄 안 함)
```
- 권한 종류: INSERT, DELETE, UPDATE, SELECT, **REFERENCES**(외래키 정의 권한)
- 기본적으로 받은 권한은 남에게 못 준다 → `WITH GRANT OPTION`

### 시스템 권한
```sql
GRANT CREATE TABLE TO kim;       -- DBA 가 부여, 객체 지정 없음
REVOKE CREATE TABLE FROM kim;
```

### 역할 (role) = 권한 묶음
```sql
CREATE ROLE role_1;                          -- DBA
GRANT SELECT, INSERT, DELETE ON 고객 TO role_1;   -- 객체 소유자
GRANT role_1 TO hong, park, lee;             -- DBA
GRANT UPDATE ON 고객 TO role_1;              -- 역할 받은 모든 사용자에게 즉시 반영
REVOKE role_1 FROM park;
DROP ROLE role_1;                            -- 부여받은 사용자들의 권한도 모두 취소
```

## 4. 뷰 (View)
- 다른 테이블(**기본 테이블**)을 기반으로 만든 **가상 테이블**. 데이터를 실제로 저장하지 않음
```sql
CREATE VIEW 우수고객(고객아이디, 고객이름, 나이)
AS SELECT 고객아이디, 고객이름, 나이 FROM 고객 WHERE 등급 = 'vip'
WITH CHECK OPTION;          -- 뷰 정의 조건(등급 = 'vip')을 위반하는 삽입·수정 거부

CREATE VIEW 업체별제품수(제조업체, 제품수)
AS SELECT 제조업체, COUNT(*) FROM 제품 GROUP BY 제조업체;   -- 계산 속성은 이름 명시 필수
DROP VIEW 우수고객;         -- 기본 테이블은 영향 없음. 이 뷰를 참조하는 뷰가 있으면 거부
```
- 검색은 모든 뷰에 가능 (내부적으로 기본 테이블 질의로 변환)
- 삽입·수정·삭제는 **변경 가능한 뷰**만, 실제론 기본 테이블이 바뀜

### 변경 불가능한 뷰
- 기본 테이블의 **기본키 속성이 없는** 뷰 (삽입 시 기본키가 NULL)
- 기본 테이블에서 **NOT NULL 속성이 없는** 뷰
- **집계 함수**로 계산된 내용 포함
- **DISTINCT**, **GROUP BY** 포함
- 여러 테이블 **조인** (불가능한 경우가 많음)

### 뷰의 장점
1. 복잡한 질의(조인·그룹·집계)를 미리 만들어 두면 간단히 검색
2. **보안**: 뷰를 통해서만 접근하도록 권한 설정
3. 관련 없는 내용을 신경 쓰지 않아도 돼 관리가 편함

## 5. 삽입 SQL (Embedded SQL)
- 프로그램 안에 넣는 SQL. 앞에 **`EXEC SQL`**, 프로그램 변수는 **`:변수`**
- 변수 선언은 `BEGIN DECLARE SECTION` ~ `END DECLARE SECTION` (C 문자열은 널 문자 위해 1 길게)
- **커서 불필요**: CREATE, INSERT, DELETE, UPDATE, **결과가 한 행인 SELECT**
```c
EXEC SQL SELECT 제품명, 단가 INTO :p_name, :price FROM 제품 WHERE 제품번호 = :p_no;
```
- **커서 필요**: 여러 행을 반환하는 SELECT. 커서 = 결과 행을 하나씩 가리키는 포인터
```c
EXEC SQL DECLARE prod_cursor CURSOR FOR SELECT 제품명, 단가 FROM 제품;
EXEC SQL OPEN prod_cursor;                 // SELECT 실행
while (...) EXEC SQL FETCH prod_cursor INTO :p_name, :price;   // 한 행씩
EXEC SQL CLOSE prod_cursor;
```

➡️ 다음: [02_서브쿼리_심화와_테이블변경.md](02_서브쿼리_심화와_테이블변경.md)
