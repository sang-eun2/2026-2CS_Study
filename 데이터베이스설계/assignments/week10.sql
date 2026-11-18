SQL> --1--
SQL> 
SQL> DECLARE
  2  v_max emp.sal%TYPE;
  3  v_min emp.sal%TYPE;
  4  BEGIN
  5  SELECT MAX(sal),MIN(sal) INTO v_max, v_min FROM emp;
  6  DBMS_OUTPUT.PUT_LINE('사원 중에 최고 급여는 '||v_max||'원, 최저 급여는 '||v_min||'원입니다.');
  7  END;
  8  /
사원 중에 최고 급여는 5000원, 최저 급여는 800원입니다.                          

PL/SQL 처리가 정상적으로 완료되었습니다.

SQL> --2--
SQL> 
SQL> DECLARE
  2  v_sal emp.sal%TYPE;
  3  v_grade salgrade.grade%TYPE;
  4  v_empno emp.empno%TYPE:=7698;
  5  BEGIN
  6  SELECT sal INTO v_sal FROM emp WHERE empno=v_empno;
  7  FOR i IN(SELECT grade,losal,hisal FROM salgrade) LOOP
  8  IF v_sal>=i.losal AND v_sal<=i.hisal THEN
  9  v_grade:=i.grade;
 10  END IF;
 11  END LOOP;
 12  DBMS_OUTPUT.PUT_LINE('사원번호가 '||v_empno||'인 사원의 급여는 '||v_grade ||'등급입니다.');
 13  END;
 14  /
사원번호가 7698인 사원의 급여는 4등급입니다.                                    

PL/SQL 처리가 정상적으로 완료되었습니다.

SQL> 
SQL> --3--
SQL> 
SQL> DECLARE
  2  v_avg emp.sal%TYPE;
  3  i BINARY_INTEGER:=0;
  4  TYPE ename_table IS TABLE OF emp.ename%TYPE INDEX BY BINARY_INTEGER;
  5  TYPE sal_table IS TABLE OF emp.sal%TYPE INDEX BY BINARY_INTEGER;
  6  ename_tab ename_table;
  7  sal_tab sal_table;
  8  BEGIN
  9  SELECT AVG(sal) INTO v_avg FROM emp;
 10  FOR j IN (SELECT ename,sal FROM emp WHERE sal>v_avg ORDER BY sal, ename) LOOP
 11  i:=i+1;
 12  ename_tab(i):=j.ename;
 13  sal_tab(i):=j.sal;
 14  END LOOP;
 15  
 16  DBMS_OUTPUT.PUT_LINE('- 평균 급여 :'||v_avg||chr(10)||chr(13));
 17  DBMS_OUTPUT.PUT_LINE(rpad('사원명',10)||'급여');
 18  DBMS_OUTPUT.PUT_LINE('--------- --------');
 19  FOR j IN 1..i LOOP
 20  DBMS_OUTPUT.PUT_LINE(rpad(ename_tab(j),10) || sal_tab(j));
 21  END LOOP;
 22  DBMS_OUTPUT.PUT_LINE(chr(10)||chr(13) ||'- 총 인원 수 : '||i||'명');
 23  END;
 24  /
- 평균 급여 :2073.21

                                                          
사원명    급여                                                                  
--------- --------                                                              
CLARK     2450                                                                  
BLAKE     2850                                                                  
JONES     2975                                                                  
FORD      3000                                                                  
SCOTT     3000                                                                  
KING      5000                                                                  


- 총 인원 수 : 6명                                                            

PL/SQL 처리가 정상적으로 완료되었습니다.

SQL> 
SQL> --4--
SQL> DECLARE
  2  v_job emp.job%TYPE;
  3  v_cnt NUMBER:=0;
  4  BEGIN
  5  DBMS_OUTPUT.PUT_LINE('직책명');
  6  DBMS_OUTPUT.PUT_LINE('--------');
  7  FOR i in (SELECT DISTINCT job  FROM emp WHERE deptno=10 ORDER BY job)LOOP
  8  v_cnt:=v_cnt+1;
  9  v_job:=i.job;
 10  DBMS_OUTPUT.PUT_LINE(v_job);
 11  END LOOP;
 12  
 13  DBMS_OUTPUT.PUT_LINE(chr(10)||chr(13)||'직책의 수 : '||v_cnt);
 14  END;
 15  /
직책명                                                                          
--------                                                                        
CLERK                                                                           
MANAGER                                                                         
PRESIDENT                                                                       


직책의 수 : 3                                                                 

PL/SQL 처리가 정상적으로 완료되었습니다.

SQL> --for문내부에 in으로 select하면 묵시적으로 cursor를 작동시킬 수 있음.--
SQL> 
SQL> 
SQL> --5--
SQL> 
SQL> DECLARE
  2  v_emp emp%ROWTYPE;
  3  CURSOR emp_cur(v_job emp.job%TYPE) IS
  4  SELECT * FROM emp WHERE job=v_job ORDER BY empno;
  5  BEGIN
  6  DBMS_OUTPUT.PUT_LINE(rpad('사원번호',10)||'사원명');
  7  DBMS_OUTPUT.PUT_LINE(rpad('--------',10)||'--------');
  8  OPEN emp_cur('MANAGER');
  9  LOOP
 10  FETCH emp_cur INTO v_emp;
 11  EXIT WHEN emp_cur%NOTFOUND;
 12  DBMS_OUTPUT.PUT_LINE(rpad(v_emp.empno,10)||v_emp.ename);
 13  END LOOP;
 14  DBMS_OUTPUT.PUT_LINE(chr(10)||chr(13)||'총 인원 수 : '||emp_cur%ROWCOUNT);
 15  CLOSE emp_cur;
 16  END;
 17  /
사원번호  사원명                                                                
--------  --------                                                              
7566      JONES                                                                 
7698      BLAKE                                                                 
7782      CLARK                                                                 


총 인원 수 : 3                                                                

PL/SQL 처리가 정상적으로 완료되었습니다.

SQL> 
SQL> spool off
