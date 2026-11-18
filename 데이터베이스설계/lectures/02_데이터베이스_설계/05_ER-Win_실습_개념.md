# 05. ER-Win 으로 모델링하기 (4·6·7주차 실습)

> 출처: `2026-2/데이터베이스설계/4주차 ER-Win(1).pdf`, `6주차 ER-Win(2).pdf`, `7주차 ER-Win(3).pdf`
> 실습 과제(모델 작성 문제)는 과제이므로 싣지 않고, 도구 사용법과 개념만 정리함.

## 한눈에 보기
- **ERwin Data Modeler**: GUI 로 ERD 를 그리고 DBMS 스키마까지 만들어 주는 **CASE 도구** (Computer-Aided Software Engineering)
- 흐름: **논리 모델(Logical)** → **물리 모델(Physical)** → **Forward Engineer** 로 스키마 생성 SQL

| 주차 | 내용 | 이론 연결 |
|---|---|---|
| 4 | 개체, 식별/비식별 관계, N:M, 서브타입 | Part 2 ER 모델 |
| 6 | 강한 개체·ID 종속·혼합·재귀 패턴, 도메인 | Part 2 패턴 |
| 7 | 열 속성(타입, NOT NULL, DEFAULT, 검증 규칙), Subject Area, 물리 모델링, 스키마 생성 | Part 3 변환 |

---

## 1. 시작 설정 (4주차)
- File → New → **Logical/Physical** 선택(둘 다 자유롭게 쓰려고), 대상 DB **ORACLE** 과 버전
- 화면: Model Explorer / Diagram / 도구·메뉴
- 표기법: **IE** 와 **IDEF1X** 지원 → Model → Model Properties → Notation 탭에서 Logical·Physical 을 **IE** 로 (수업 표기)
- 상단 콤보 박스로 Logical ↔ Physical 전환

## 2. 개체와 관계
- 개체 생성: 이름 → 기본키 영역 → 속성 영역 (TAB 으로 다음 칸, ENTER 로 새 속성)
- Format → Display Level 로 개체만 / 기본키만 / 속성까지 보기
- 관계: 도구상자의 관계선 선택 → **부모 클릭 → 자식 클릭**
| 관계 | 선 | 자식에 들어가는 부모 키 |
|---|---|---|
| **식별 관계** | 실선 | 자식의 **기본키 영역**으로 (ID 종속) |
| **비식별 관계** | 점선 | 자식의 **일반 속성 영역**으로 (외래키만) |
- Relationship Properties: **카디널리티**, **동사구(verb phrase)** 로 관계 설명 (Format → Relationship Display → Verb Phrase), 관계 타입(식별/비식별, 널 허용)

### N:M 관계
- **논리 모델에서만** 존재 (물리 테이블로는 바로 못 만듦)
- 해소: 관계 오른쪽 클릭 → **Create Association Entity**, 또는 Transform 툴바의 **Many to Many Transform** → 교차(연관) 개체 생성

### 서브타입
- Subtype Properties 에서 **Exclusive**(배타) / **Inclusive**(포함) 선택

## 3. 패턴과 도메인 (6주차)
- 강한 개체 1:1 / 1:N / N:M, ID 종속(연관, 다값 속성, 원형/인스턴스), 혼합(라인 아이템 등), 재귀 패턴을 도구로 그려 봄 → 각 패턴의 의미는 [02_ER_데이터모델링.md](02_ER_데이터모델링.md)
- **재귀 관계의 롤네임(Rolename)**: 한 개체 안에 같은 열 이름을 두 번 쓸 수 없으므로, 자기 자신을 참조하는 외래키 이름을 바꿔 줌 (Relationship Properties → Rolename 탭). 재귀 N:M 은 **먼저 다대다를 해소**한 뒤 지정
- **도메인(Domain)**: 여러 속성이 공유하는 타입·규칙의 틀
  - Domains 에서 새 도메인(예: Number 형 'Num') 생성 → 개체에 끌어다 놓기
  - 속성 이름 규칙 `%EntityName%AttDomain` → 적용되는 속성 이름 앞에 개체 이름이 자동으로 붙음
  - Sort Hierarchically 로 타입별 정렬 확인
> 도메인 = 같은 의미의 값(전화번호, 금액 등)을 한 곳에서 정의해 일관성 유지

## 4. 열 속성과 물리 모델 (7주차)
| 설정 | 내용 | Part 3 개념 |
|---|---|---|
| Datatype 탭 | 데이터 타입, **NOT NULL** 체크 | 널 여부, 타입 |
| **Default** | 기본값 (예: `'Unknown Provenance'`) | 기본값 |
| **Validation Rule** | 값 검증 규칙 → CHECK 제약 (예: `IN ('French', 'German', ...)`, `BETWEEN 1900 AND 2999`, `(SalesPrice > 0) AND (SalesPrice <= 500000)`) | 도메인·범위 제약 |
| **Subject Area** | 큰 모델을 주제별 부분 다이어그램으로 나눠 보기 | |
- **물리 모델링**: Logical 을 Physical 로 전환 → 테이블·열·타입으로 보임 (타입이 안 보이면 Table Display → Column Datatype)
- **스키마 생성**: 툴바 **Forward Engineer → Schema Generation Preview** → 생성될 `CREATE TABLE` 문 확인 (Part 4 의 순공학)

## 5. 모델링 요구사항을 읽는 요령 (과제 유형의 공통 개념)
요구사항 문장에서
- 명사 → **개체**와 속성, "~번호/ID" → 식별자
- "여러 ~을 할 수 있다", "하나 이상" → 최대 카디널리티 N, 최소 1 (필수)
- "~할 수 있다" vs "반드시 ~" → 최소 카디널리티 0 (선택) vs 1 (필수)
- "주문한 가구들의 수량", "몇 개씩 포함" 처럼 **관계 자체에 붙는 값** → N:M 을 **연관 개체(라인 아이템)** 로 해소하고 그 속성으로
- "두 명 이상" 처럼 숫자가 정해진 최소값은 ER 기호로 다 표현되지 않으므로 별도 제약·문서로
- 범위가 커지면(도시 → 지역 → 전국) 이전에 속성이던 것(예: 거리)이 **관계의 속성**이나 새 개체로 바뀜 → 모델은 요구에 따라 반복 수정

⬅️ 이전: [04_데이터베이스_재설계.md](04_데이터베이스_재설계.md) · ➡️ 다음: [03_멀티유저_DB](../03_멀티유저_DB/01_동시성_보안_복구.md)
