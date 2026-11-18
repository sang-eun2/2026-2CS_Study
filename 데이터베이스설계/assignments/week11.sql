SQL> /*---------Q1--------*/
SQL> create or replace procedure EMP_INPUT (p_empno in emp.empno%type,p_ename in emp.ename%type,p_job in emp.job%type, p_mgr in emp.mgr%type, p_hiredate in emp.hiredate%type, p_sal in emp.sal%type)
  2  is
  3  v_deptno emp.deptno%type;
  4  v_comm emp.comm%type;
  5  begin
  6  select deptno into v_deptno
  7  from emp where empno=p_mgr;
  8  if p_job='SALESMAN' then
  9  v_comm:=10;
 10  else
 11  v_comm:=null;
 12  end if;
 13  insert into emp values (p_empno,p_ename,p_job,p_mgr,p_hiredate,p_sal,v_comm,v_deptno);
 14  commit;
 15  exception
 16  when DUP_VAL_ON_INDEX then
 17  DBMS_OUTPUT.PUT_LINE('중복된 사원번호입니다.');
 18  end;
 19  /

프로시저가 생성되었습니다.

SQL> show errors
오류가 없음.
SQL> execute emp_input(7900,'ALVIN','SALESMAN',7788,SYSDATE,1500);
중복된 사원번호입니다.                                                          

PL/SQL 처리가 정상적으로 완료되었습니다.

SQL> EXECUTE emp_input(7904,'ALVIN','SALESMAN',7788,SYSDATE,1500);

PL/SQL 처리가 정상적으로 완료되었습니다.

SQL> execute emp_input(7367,'JOHN','CLERK',7902,SYSDATE,1200);

PL/SQL 처리가 정상적으로 완료되었습니다.

SQL> /*---------Q2--------*/
SQL> create or replace function D_E_CNT (p_dname IN dept.dname%type)
  2  return number
  3  is
  4  v_cnt number;
  5  begin
  6  select count(e.empno) into v_cnt
  7  from emp e,dept d
  8  where e.deptno=d.deptno and d.dname=p_dname;
  9  DBMS_OUTPUT.PUT_LINE('소속 사원 수: '|| v_cnt);
 10  return v_cnt;
 11  end;
 12  /

함수가 생성되었습니다.

SQL> show errors
오류가 없음.
SQL> var empCnt number
SQL> execute:empCnt:=D_E_CNT('SALES');
소속 사원 수: 6                                                                 

PL/SQL 처리가 정상적으로 완료되었습니다.

SQL> /*---------Q3--------*/
SQL> create or replace trigger shops_input
  2  before insert on shops
  3  declare
  4  v_profit shops.shop_profit%type;
  5  v_cost shops.shop_cost%type;
  6  begin
  7  select sum(shop_profit),sum(shop_cost) into v_profit, v_cost from shops;
  8  DBMS_OUTPUT.PUT_LINE('<INSERT문이 실행되기 전까지의 손익 현황>');
  9  DBMS_OUTPUT.PUT_LINE('총 수익 : ' ||v_profit);
 10  DBMS_OUTPUT.PUT_LINE('총 비용 : '||v_cost);
 11  DBMS_OUTPUT.PUT_LINE('총 순이익 : '||(v_profit-v_cost));
 12  end;
 13  /

트리거가 생성되었습니다.

SQL> show errors
오류가 없음.
SQL> insert into shops values(500,'동국상점5',2500000,800000);
<INSERT문이 실행되기 전까지의 손익 현황>                                        
총 수익 : 11300000                                                              
총 비용 : 4900000                                                               
총 순이익 : 6400000                                                             

1 개의 행이 만들어졌습니다.

SQL> commit;

커밋이 완료되었습니다.

SQL> spool off
