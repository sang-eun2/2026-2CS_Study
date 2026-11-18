# 데이터베이스설계

Oracle과 MySQL로 스키마를 만들고, 질의·제약조건·정규화·PL/SQL을 실습합니다.

## 폴더
- `practice/`: 주차별 실습 테이블 생성 스크립트 (수업에서 제공된 샘플 데이터)
- `assignments/`: 주차별 과제 풀이 (SQL*Plus / mysql 실행 기록 포함)
- `practice/connect.jsp`: JSP에서 JDBC로 Oracle에 접속하는 예제. **계정·비밀번호는 자리표시자로 바꿔 두었습니다.**
- `lectures/`: 강의 전체(SQL, 설계, 멀티유저, PL/SQL, JDBC) 개념 정리

## 주차별 핵심 개념
| 주차 | 파일 | 개념 |
|---|---|---|
| 2 | `week02_mysql.sql`, `week02_oracle.sql` | CREATE TABLE, INSERT, SELECT 기본. Oracle과 MySQL 문법 차이 |
| 3 | `week03.sql` | 정규화: 부분 함수 종속 제거, 테이블 분해 후 JOIN으로 복원 |
| 8 | `week08.sql` | 제약조건: `CHECK`, `PRIMARY KEY`, `FOREIGN KEY`, `ALTER TABLE ... ADD CONSTRAINT` |
| 10 | `week10.sql` | PL/SQL 블록: `DECLARE`/`BEGIN`, `%TYPE`, `SELECT INTO`, `DBMS_OUTPUT` |
| 11 | `week11.sql` | 저장 프로시저: `CREATE OR REPLACE PROCEDURE`, IN 매개변수 |
| 12 | `week12.sql` | 프로시저 + 사용자 정의 예외(`EXCEPTION`), OUT 매개변수 (수강신청 검증) |

## 개념 메모
- **`%TYPE`**: 컬럼 타입을 그대로 따라가므로 테이블이 바뀌어도 변수 선언을 고칠 필요가 없습니다.
- **SELECT INTO**는 결과가 정확히 한 행이어야 합니다. 0행이면 `NO_DATA_FOUND`, 여러 행이면 `TOO_MANY_ROWS` 예외가 납니다.
- **사용자 정의 예외**: `e EXCEPTION;` 선언 → `RAISE e;` → `EXCEPTION WHEN e THEN ...`에서 처리합니다.
- `SET SERVEROUTPUT ON`을 해야 `DBMS_OUTPUT.PUT_LINE` 결과가 보입니다.
