SQL> SET SERVEROUTPUT ON
SQL> -----Q1
SQL> CREATE OR REPLACE PROCEDURE InsertEnroll(sStudentId IN VARCHAR2,
  2                                           sCourseId IN VARCHAR2,
  3                                           nCourseIdNo IN NUMBER,
  4                                           result OUT VARCHAR2)
  5  IS
  6      too_many_sumCourseUnit EXCEPTION;
  7      too_many_courses EXCEPTION;
  8      too_many_students EXCEPTION;
  9      duplicate_time EXCEPTION;
 10      nYear NUMBER;
 11      nSemester NUMBER;
 12      nSumCourseUnit NUMBER;
 13      nCourseUnit NUMBER;
 14      nCnt NUMBER;
 15      nTeachMax NUMBER;
 16
 17      CURSOR dup_time_cur IS
 18          SELECT t_time
 19          FROM teach
 20          WHERE t_year = nYear AND t_semester = nSemester
 21            AND c_id = sCourseId AND c_id_no = nCourseIdNo
 22          INTERSECT
 23          SELECT t.t_time
 24          FROM teach t, enroll e
 25          WHERE e.s_id = sStudentId AND e.e_year = nYear
 26            AND e.e_semester = nSemester AND t.t_year = nYear
 27            AND t.t_semester = nSemester AND e.c_id = t.c_id
 28            AND e.c_id_no = t.c_id_no;
 29
 30      vTime teach.t_time%TYPE;
 31  BEGIN
 32      result := '';
 33      DBMS_OUTPUT.put_line('#');
 34      DBMS_OUTPUT.put_line(sStudentId || '님이 과목번호 ' || sCourseId || ', 분반 ' ||
 35                           TO_CHAR(nCourseIdNo) || '의 수강 등록을 요청하였습니다.');
 36
 37      /* 년도, 학기 알아내기 */
 38      nYear := Date2EnrollYear(SYSDATE);
 39      nSemester := Date2EnrollSemester(SYSDATE);
 40
 41      /* 에러 처리 1 : 최대학점 초과여부 */
 42      SELECT SUM(c.c_unit)
 43      INTO nSumCourseUnit
 44      FROM course c, enroll e
 45      WHERE e.s_id = sStudentId AND e.e_year = nYear AND e.e_semester = nSemester
 46        AND e.c_id = c.c_id AND e.c_id_no = c.c_id_no;
 47
 48      SELECT c_unit
 49      INTO nCourseUnit
 50      FROM course
 51      WHERE c_id = sCourseId AND c_id_no = nCourseIdNo;
 52
 53      IF (nSumCourseUnit + nCourseUnit > 18) THEN
 54          RAISE too_many_sumCourseUnit;
 55      END IF;
 56
 57      /* 에러 처리 2 : 동일한 과목 신청 여부 */
 58      SELECT COUNT(*)
 59      INTO nCnt
 60      FROM enroll
 61      WHERE s_id = sStudentId AND c_id = sCourseId;
 62
 63      IF (nCnt > 0) THEN
 64          RAISE too_many_courses;
 65      END IF;
 66
 67      /* 에러 처리 3 : 수강신청 인원 초과 여부 */
 68      SELECT t_max
 69      INTO nTeachMax
 70      FROM teach
 71      WHERE t_year = nYear AND t_semester = nSemester
 72        AND c_id = sCourseId AND c_id_no = nCourseIdNo;
 73
 74      SELECT COUNT(*)
 75      INTO nCnt
 76      FROM enroll
 77      WHERE e_year = nYear AND e_semester = nSemester
 78        AND c_id = sCourseId AND c_id_no = nCourseIdNo;
 79
 80      IF (nCnt >= nTeachMax) THEN
 81          RAISE too_many_students;
 82      END IF;
 83
 84      /* 에러 처리 4 : 신청한 과목들 시간 중복 여부 (명시적 커서) */
 85      nCnt := 0;
 86      OPEN dup_time_cur;
 87      LOOP
 88          FETCH dup_time_cur INTO vTime;
 89          EXIT WHEN dup_time_cur%NOTFOUND;
 90          nCnt := nCnt + 1;
 91      END LOOP;
 92      CLOSE dup_time_cur;
 93
 94      IF (nCnt > 0) THEN
 95          RAISE duplicate_time;
 96      END IF;
 97
 98      /* 수강 신청 등록 */
 99      INSERT INTO enroll(S_ID, C_ID, C_ID_NO, E_YEAR, E_SEMESTER)
100      VALUES (sStudentId, sCourseId, nCourseIdNo, nYear, nSemester);
101      COMMIT;
102      result := '수강신청 등록이 완료되었습니다.';
103
104  EXCEPTION
105      WHEN too_many_sumCourseUnit THEN
106          result := '최대학점을 초과하였습니다.';
107      WHEN too_many_courses THEN
108          result := '이미 등록된 과목을 신청하였습니다.';
109      WHEN too_many_students THEN
110          result := '수강신청 인원이 초과되어 등록이 불가능합니다.';
111      WHEN duplicate_time THEN
112          result := '이미 등록된 과목 중 중복되는 시간이 존재합니다.';
113      WHEN OTHERS THEN
114          ROLLBACK;
115          result := SQLCODE;
116  END;
117  /

프로시저가 생성되었습니다.

SQL> --프로시저 검증 test 코드
SQL> DECLARE
  2      r VARCHAR2(200);
  3  BEGIN
  4      -- 1) 시간 중복 (M100=5교시, 20011234는 C200=5교시 수강 중)
  5      InsertEnroll('20011234', 'M100', 3, r);
  6      DBMS_OUTPUT.put_line('시간중복: ' || r);
  7
  8      -- 2) 이미 등록된 과목
  9      InsertEnroll('20011234', 'C100', 3, r);
 10      DBMS_OUTPUT.put_line('동일과목: ' || r);
 11
 12      -- 3) 정상 등록 (20021245는 2027-1 내역 없음, C300=2교시)
 13      InsertEnroll('20021245', 'C300', 3, r);
 14      DBMS_OUTPUT.put_line('정상등록: ' || r);
 15  END;
 16  /
#
20011234님이 과목번호 M100, 분반 3의 수강 등록을 요청하였습니다.
시간중복: 이미 등록된 과목 중 중복되는 시간이 존재합니다.
#
20011234님이 과목번호 C100, 분반 3의 수강 등록을 요청하였습니다.
동일과목: 이미 등록된 과목을 신청하였습니다.
#
20021245님이 과목번호 C300, 분반 3의 수강 등록을 요청하였습니다.
정상등록: 수강신청 등록이 완료되었습니다.

PL/SQL 처리가 정상적으로 완료되었습니다.

SQL> DELETE FROM enroll
  2  WHERE s_id = '20021245' AND c_id = 'C300' AND c_id_no = 3;

1 행이 삭제되었습니다.

SQL>
SQL> COMMIT;

커밋이 완료되었습니다.

SQL> ----Q2
SQL> CREATE OR REPLACE PROCEDURE emp_delete(p_empno IN emp.empno%TYPE)
  2  IS
  3      v_ename   emp.ename%TYPE;
  4      v_cnt     NUMBER;
  5      no_sub    EXCEPTION;
  6
  7      CURSOR sub_cur(p_mgr emp.mgr%TYPE) IS
  8          SELECT e.empno, e.ename, d.dname, e.job, e.mgr
  9          FROM emp e, dept d
 10          WHERE e.deptno = d.deptno
 11            AND e.mgr = p_mgr;
 12
 13      v_empno   emp.empno%TYPE;
 14      v_name    emp.ename%TYPE;
 15      v_dname   dept.dname%TYPE;
 16      v_job     emp.job%TYPE;
 17      v_mgr     emp.mgr%TYPE;
 18  BEGIN
 19
 20      SELECT ename INTO v_ename FROM emp WHERE empno = p_empno;
 21      DBMS_OUTPUT.put_line('삭제할 사원 이름 : ' || v_ename);
 22
 23
 24      SELECT COUNT(*) INTO v_cnt FROM emp WHERE mgr = p_empno;
 25
 26      IF v_cnt = 0 THEN
 27          RAISE no_sub;
 28      END IF;
 29
 30
 31      DBMS_OUTPUT.put_line(chr(10) || chr(13) || '<부하직원 정보>');
 32      DBMS_OUTPUT.put_line(rpad('사원번호', 12) || rpad('이름', 12) ||
 33                           rpad('부서명', 12) || rpad('직책', 12) || '관리자번호');
 34      DBMS_OUTPUT.put_line(rpad('-------', 12) || rpad('-------', 12) ||
 35                           rpad('-------', 12) || rpad('-------', 12) || '-------');
 36
 37      OPEN sub_cur(p_empno);
 38      LOOP
 39          FETCH sub_cur INTO v_empno, v_name, v_dname, v_job, v_mgr;
 40          EXIT WHEN sub_cur%NOTFOUND;
 41          DBMS_OUTPUT.put_line(rpad(v_empno, 12) || rpad(v_name, 12) ||
 42                               rpad(v_dname, 12) || rpad(v_job, 12) || v_mgr);
 43      END LOOP;
 44      CLOSE sub_cur;
 45
 46      UPDATE emp SET mgr = NULL WHERE mgr = p_empno;
 47
 48      DELETE FROM emp WHERE empno = p_empno;
 49      COMMIT;
 50
 51  EXCEPTION
 52      WHEN NO_DATA_FOUND THEN
 53          DBMS_OUTPUT.put_line('존재하지 않는 사원입니다.');
 54      WHEN no_sub THEN
 55          DELETE FROM emp WHERE empno = p_empno;
 56          COMMIT;
 57          DBMS_OUTPUT.put_line('부하직원이 없는 사원입니다.');
 58  END;
 59  /

프로시저가 생성되었습니다.

SQL> EXECUTE emp_delete(7566);
삭제할 사원 이름 : JONES

<부하직원 정보>
사원번호    이름        부서명      직책        관리자번호
-------     -------     -------     -------     -------
7788        SCOTT       RESEARCH    ANALYST     7566
7902        FORD        RESEARCH    ANALYST     7566

PL/SQL 처리가 정상적으로 완료되었습니다.

SQL> EXECUTE emp_delete(7934);
삭제할 사원 이름 : MILLER
부하직원이 없는 사원입니다.

PL/SQL 처리가 정상적으로 완료되었습니다.

SQL> EXECUTE emp_delete(9999);
존재하지 않는 사원입니다.

PL/SQL 처리가 정상적으로 완료되었습니다.

SQL> SELECT * FROM emp;

     EMPNO ENAME                JOB                       MGR HIREDATE
---------- -------------------- ------------------ ---------- --------
       SAL       COMM     DEPTNO
---------- ---------- ----------
      7369 SMITH                CLERK                    7902 80/12/17
       800                    20

      7499 ALLEN                SALESMAN                 7698 81/02/20
      1600        300         30

      7521 WARD                 SALESMAN                 7698 81/02/22
      1250        500         30


     EMPNO ENAME                JOB                       MGR HIREDATE
---------- -------------------- ------------------ ---------- --------
       SAL       COMM     DEPTNO
---------- ---------- ----------
      7654 MARTIN               SALESMAN                 7698 81/09/28
      1250       1400         30

      7698 BLAKE                MANAGER                  7839 81/05/01
      2850                    30

      7782 CLARK                MANAGER                  7839 81/06/09
      2450                    10


     EMPNO ENAME                JOB                       MGR HIREDATE
---------- -------------------- ------------------ ---------- --------
       SAL       COMM     DEPTNO
---------- ---------- ----------
      7788 SCOTT                ANALYST                       87/01/13
      3000                    20

      7839 KING                 PRESIDENT                     81/11/17
      5000                    10

      7844 TURNER               SALESMAN                 7698 81/09/08
      1500          0         30


     EMPNO ENAME                JOB                       MGR HIREDATE
---------- -------------------- ------------------ ---------- --------
       SAL       COMM     DEPTNO
---------- ---------- ----------
      7876 ADAMS                CLERK                    7788 87/10/23
      1100                    20

      7900 JAMES                CLERK                    7698 81/12/03
       950                    30

      7902 FORD                 ANALYST                       81/12/03
      3000                    20


12 행이 선택되었습니다.

SQL> COMMIT;

커밋이 완료되었습니다.