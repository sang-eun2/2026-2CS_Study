# 01. 데이터베이스 어플리케이션 프로그래밍: JDBC 와 JSP (Part 9, Part 10 + 12주차 실습 환경)

> 출처: `2026-2/데이터베이스설계/09. 데이터베이스_어플리케이션_프로그래밍(1).pdf`, `10. 데이터베이스_어플리케이션_프로그래밍(2).pdf`, `12주차 PLSQL(3).pdf`(실습 환경 부분)

## 한눈에 보기
- **JDBC** = 자바에서 DB 접속, SQL 실행, 결과 처리를 위한 **표준 API**. 인터페이스는 표준, 구현(**드라이버**)은 DB 벤더가 제공
- 연동 4단계: **드라이버 로딩 → Connection → Statement → 실행(executeQuery / executeUpdate / execute)** → ResultSet 처리 → close
- JDBC 는 기본 **AutoCommit ON** → 여러 문장을 한 트랜잭션으로 묶으려면 `setAutoCommit(false)` + `commit()/rollback()`
- 실습: JSP + JDBC 로 수강신청 시스템(로그인, 정보 수정, 신청·삭제·조회, 로그아웃)

---

## 1. JDBC 를 쓰는 이유
- JDBC 이전: DB 마다(Oracle, Sybase, Informix) 다른 라이브러리를 익혀 따로 개발
- JDBC: **하나의 API** 로 DB 에 상관없이 작성 → **드라이버만 바꾸면** 같은 코드를 다른 DB 에 사용
- API 대부분이 **인터페이스**이고 `DriverManager` 등 일부만 클래스인 이유: DB 제품마다 구현이 달라서, 접속·처리 API 를 인터페이스로 정해 두고 **벤더가 구현(드라이버)** 하게 함

### java.sql 패키지
| 구분 | 요소 |
|---|---|
| 인터페이스 | Driver, **Connection**, **Statement**, **ResultSet**, **PreparedStatement**, CallableStatement, ResultSetMetaData, DatabaseMetaData, Blob, Clob … |
| 클래스 | **DriverManager**, Types, Date, Time, Timestamp |
| 예외 | **SQLException**, SQLWarning, DataTruncation, BatchUpdateException |

| 요소 | 역할 |
|---|---|
| DriverManager | 드라이버 목록 관리, URL 에 맞는 드라이버로 Connection 제공 |
| Connection | 하나의 논리적 DB 연결·트랜잭션 |
| Statement | SQL 실행 |
| ResultSet | 질의 결과 행들 |

## 2. 연결
| 방법 | 특징 |
|---|---|
| **DriverManager** (JDBC 1.0) | URL 로 드라이버를 찾아 연결 |
| **DataSource** (JDBC 2.0 확장) | 연결 상세를 캡슐화, **커넥션 풀**(ConnectionPoolDataSource) |

| DB | 드라이버 클래스 |
|---|---|
| Oracle | `oracle.jdbc.driver.OracleDriver` |
| MySQL | `org.gjt.mm.mysql.Driver` (현재는 `com.mysql.cj.jdbc.Driver`) |

```java
Class.forName("oracle.jdbc.driver.OracleDriver");              // 1) 드라이버 로딩
Connection con = DriverManager.getConnection(                   // 2) 연결
    "jdbc:oracle:thin:@localhost:1521:orcl", "사용자계정", "비밀번호");
// JDBC URL = jdbc:<subprotocol>:<subname>, thin 드라이버: @서버:포트:SID
```
> 계정·비밀번호는 코드에 직접 쓰지 말고 설정 파일·환경 변수로 분리 (공개 저장소에 올리면 안 됨)

## 3. Statement 와 실행 메소드
| 메소드 | 대상 | 반환 |
|---|---|---|
| `executeQuery(sql)` | **SELECT** | ResultSet |
| `executeUpdate(sql)` | INSERT, UPDATE, DELETE, DDL | **영향받은 행 수** (int) |
| `execute(sql)` | 아무 SQL | 첫 결과가 ResultSet 이면 true → `getResultSet()`, 아니면 false → `getUpdateCount()` |

- `createStatement()` 기본은 **전진 전용·읽기 전용** ResultSet
  - 스크롤: `TYPE_FORWARD_ONLY`(기본), `TYPE_SCROLL_INSENSITIVE`, `TYPE_SCROLL_SENSITIVE`
  - 동시성: `CONCUR_READ_ONLY`, `CONCUR_UPDATABLE`

## 4. ResultSet
- 처음엔 커서가 **첫 행 바로 앞** → `next()` 를 호출해야 첫 행. 행이 없으면 false
- `getXxx("컬럼명")` 또는 `getXxx(위치)` — **위치는 1부터**
- 스크롤 가능하면 `previous()`, `first()`, `last()`, `absolute()`, `relative()`
- **NULL 처리**: getXxx 는 NULL 이면 객체형 `null`, **숫자형 0**, boolean `false` 반환 → 진짜 0 인지 구별하려면 `wasNull()`
```java
ResultSet rs = stmt.executeQuery("SELECT ename FROM emp");
while (rs.next()) {
    String ename = rs.getString("ename");
}
rs.close(); stmt.close(); con.close();
```

### SQL ↔ 자바 타입
| SQL | 자바 |
|---|---|
| INTEGER / BIGINT / SMALLINT | int / long / short |
| REAL / FLOAT, DOUBLE | float / double |
| NUMERIC | java.math.BigDecimal |
| CHAR, VARCHAR | String |
| DATE / TIME / TIMESTAMP | java.sql.Date / Time / Timestamp |
| BLOB / CLOB | java.sql.Blob / Clob |

## 5. 트랜잭션
- 기본 **AutoCommit 모드**: 각 SQL 문이 하나의 트랜잭션, 실행 즉시 커밋
```java
conn.setAutoCommit(false);
try {
    ... 여러 executeUpdate ...
    conn.commit();
} catch (SQLException e) {
    conn.rollback();
}
```

## 6. 수강신청 시스템 (JSP)
| 화면 | 역할 |
|---|---|
| main.jsp | 메인, top.jsp 포함 |
| top.jsp | **세션**(`session.getAttribute("user")`)으로 로그인 여부 확인, 메뉴 |
| login.jsp → login_verify.jsp | 아이디·비밀번호 확인 → 맞으면 `session.setAttribute("user", id)` 후 main, 틀리면 login 으로 |
| update.jsp → update_verify.jsp | 주소·비밀번호 조회/수정. 수정 시 **트리거 BeforeUpdateStudent** 오류를 받아 메시지 표시 |
| insert / delete / select.jsp | 수강신청 입력(InsertEnroll 프로시저), 삭제, 조회(SelectTimeTable) |
| logout.jsp | `session.invalidate()` |

- 트리거 오류 처리: `catch (SQLException ex) { if (ex.getErrorCode() == 20002) ... }` — `RAISE_APPLICATION_ERROR(-20002, ...)` 의 번호가 **양수 20002** 로 들어옴

### ⚠️ 슬라이드 코드의 보안·정확성 주의점
1. **SQL 인젝션**: login_verify.jsp 가 문자열을 이어 붙여 SQL 을 만든다
   ```java
   "SELECT s_id FROM student WHERE s_id='" + userID + "' AND s_pwd='" + userPassword + "'"
   ```
   아이디에 `' OR '1'='1' --` 를 넣으면 비밀번호 없이 로그인된다. **PreparedStatement** 로 값 바인딩을 해야 한다:
   ```java
   PreparedStatement ps = con.prepareStatement(
       "SELECT s_id FROM student WHERE s_id = ? AND s_pwd = ?");
   ps.setString(1, userID);
   ps.setString(2, userPassword);
   ResultSet rs = ps.executeQuery();
   ```
2. update_verify.jsp 가 UPDATE 를 `executeQuery` 로 실행한다. Oracle 드라이버는 동작하지만 표준적으로는 **`executeUpdate`** 가 맞다
3. 연결·Statement 는 `finally` 나 **try-with-resources** 로 반드시 닫는다
4. 비밀번호를 평문으로 저장·비교하는 것은 학습용. 실제로는 **해시(+솔트)** 로 저장

## 7. 실습 환경 (12주차)
- Apache Tomcat(서블릿/JSP 컨테이너, 기본 `http://localhost:8080/`) + JDK
- Oracle JDBC 드라이버(`ojdbc8.jar`)를 Tomcat 의 lib 또는 웹앱 `WEB-INF/lib` 에 둔다 (Java 11 이상은 jre/lib/ext 가 없으므로 `WEB-INF/lib`)
- JSP 파일은 `webapps/ROOT` 아래에 두고 실행

⬅️ 이전: [04_PLSQL](../04_PLSQL/03_프로시저_함수_트리거.md)
