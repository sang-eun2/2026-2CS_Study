//Q1

SQL> ALTER TABLE artist
  2  ADD CONSTRAINT artist_con_nationality
  3  CHECK (nationality IN ('Spanish', 'Russian', 'German', 'French', 'United States'));

테이블이 변경되었습니다.

SQL> 
SQL> insert into artist(artistid, lastname, firstname, nationality, dateofbirth, datedeceased)
  2  values(10440, 'Miro3', 'Joan3', 'Japan', 1900, 1983);
insert into artist(artistid, lastname, firstname, nationality, dateofbirth, datedeceased)
*
1행에 오류:
ORA-02290: 체크 제약조건(SYSTEM.ARTIST_CON_NATIONALITY)이 위배되었습니다 


//Q2

SQL> 
SQL> 
SQL> ALTER TABLE artist
  2  MODIFY (nationality DEFAULT 'United States');

테이블이 변경되었습니다.

SQL> 
SQL> insert into artist(artistid, lastname, firstname, dateofbirth, datedeceased)
  2  values(10441, 'Miro4', 'Joan4', 1910, 1985);

1 개의 행이 만들어졌습니다.

SQL> 
SQL> select * from artist;

  ARTISTID LASTNAME                                                             
---------- --------------------------------------------------                   
FIRSTNAME                                                                       
--------------------------------------------------                              
NATIONALITY                                                  DATEOFBIRTH        
------------------------------------------------------------ -----------        
DATEDECEASED                                                                    
------------                                                                    
         1 Miro                                                                 
Joan                                                                            
Spanish                                                             1893        
        1983                                                                    
                                                                                

  ARTISTID LASTNAME                                                             
---------- --------------------------------------------------                   
FIRSTNAME                                                                       
--------------------------------------------------                              
NATIONALITY                                                  DATEOFBIRTH        
------------------------------------------------------------ -----------        
DATEDECEASED                                                                    
------------                                                                    
         2 Kandinsky                                                            
Wassily                                                                         
Russian                                                             1866        
        1944                                                                    
                                                                                

  ARTISTID LASTNAME                                                             
---------- --------------------------------------------------                   
FIRSTNAME                                                                       
--------------------------------------------------                              
NATIONALITY                                                  DATEOFBIRTH        
------------------------------------------------------------ -----------        
DATEDECEASED                                                                    
------------                                                                    
         3 Klee                                                                 
Paul                                                                            
German                                                              1879        
        1940                                                                    
                                                                                

  ARTISTID LASTNAME                                                             
---------- --------------------------------------------------                   
FIRSTNAME                                                                       
--------------------------------------------------                              
NATIONALITY                                                  DATEOFBIRTH        
------------------------------------------------------------ -----------        
DATEDECEASED                                                                    
------------                                                                    
         4 Matisse                                                              
Henri                                                                           
French                                                              1869        
        1954                                                                    
                                                                                

  ARTISTID LASTNAME                                                             
---------- --------------------------------------------------                   
FIRSTNAME                                                                       
--------------------------------------------------                              
NATIONALITY                                                  DATEOFBIRTH        
------------------------------------------------------------ -----------        
DATEDECEASED                                                                    
------------                                                                    
         5 Chagall                                                              
Marc                                                                            
French                                                              1887        
        1985                                                                    
                                                                                

  ARTISTID LASTNAME                                                             
---------- --------------------------------------------------                   
FIRSTNAME                                                                       
--------------------------------------------------                              
NATIONALITY                                                  DATEOFBIRTH        
------------------------------------------------------------ -----------        
DATEDECEASED                                                                    
------------                                                                    
        11 Sargent                                                              
John Singer                                                                     
United States                                                       1856        
        1925                                                                    
                                                                                

  ARTISTID LASTNAME                                                             
---------- --------------------------------------------------                   
FIRSTNAME                                                                       
--------------------------------------------------                              
NATIONALITY                                                  DATEOFBIRTH        
------------------------------------------------------------ -----------        
DATEDECEASED                                                                    
------------                                                                    
        17 Tobey                                                                
Mark                                                                            
United States                                                       1890        
        1976                                                                    
                                                                                

  ARTISTID LASTNAME                                                             
---------- --------------------------------------------------                   
FIRSTNAME                                                                       
--------------------------------------------------                              
NATIONALITY                                                  DATEOFBIRTH        
------------------------------------------------------------ -----------        
DATEDECEASED                                                                    
------------                                                                    
        18 Horiuchi                                                             
Paul                                                                            
United States                                                       1906        
        1999                                                                    
                                                                                

  ARTISTID LASTNAME                                                             
---------- --------------------------------------------------                   
FIRSTNAME                                                                       
--------------------------------------------------                              
NATIONALITY                                                  DATEOFBIRTH        
------------------------------------------------------------ -----------        
DATEDECEASED                                                                    
------------                                                                    
        19 Graves                                                               
Morris                                                                          
United States                                                       1920        
        2001                                                                    
                                                                                

  ARTISTID LASTNAME                                                             
---------- --------------------------------------------------                   
FIRSTNAME                                                                       
--------------------------------------------------                              
NATIONALITY                                                  DATEOFBIRTH        
------------------------------------------------------------ -----------        
DATEDECEASED                                                                    
------------                                                                    
     10441 Miro4                                                                
Joan4                                                                           
United States                                                       1910        
        1985                                                                    
                                                                                

10 행이 선택되었습니다.


//Q3

SQL> ALTER TABLE artist MODIFY (DateofBirth NOT NULL);

테이블이 변경되었습니다.

SQL> DESC ARTIST;
 이름                                      널?      유형
 ----------------------------------------- -------- ----------------------------
 ARTISTID                                  NOT NULL NUMBER(38)
 LASTNAME                                  NOT NULL CHAR(25)
 FIRSTNAME                                 NOT NULL CHAR(25)
 NATIONALITY                                        CHAR(30)
 DATEOFBIRTH                               NOT NULL NUMBER(4)
 DATEDECEASED                                       NUMBER(4)


//Q4

SQL> 
SQL> SELECT Sname,Age FROM SAILOR s WHERE NOT EXISTS (
  2  SELECT b.Bid FROM BOAT b
  3  MINUS
  4  SELECT r.Bid FROM RESERVE r WHERE r.Sid=s.Sid);

SNAME                                                                           
--------------------------------------------------------------------------------
       AGE                                                                      
----------                                                                      
Dustin                                                                          
      45.2                                                                      
                                                                                

//Q5
SQL> 
SQL> CREATE TABLE EMPLOYEE_V2(
  2  ID INT primary key,
  3  Name CHAR(50),
  4  Department CHAR(20),
  5  Budget INT);

테이블이 생성되었습니다.

SQL> INSERT INTO EMPLOYEE_V2 SELECT * FROM EMPLOYEE;

5 행이 생성되었습니다.

SQL> ALTER TABLE EMPLOYEE_V2 DROP COLUMN Budget;

테이블이 변경되었습니다.

SQL> ALTER TABLE EMPLOYEE_V2 ADD (Age NUMBER(3));

테이블이 변경되었습니다.

SQL> DROP TABLE EMPLOYEE;

테이블이 삭제되었습니다.

SQL> DESC EMPLOYEE_V2;
 이름                                      널?      유형
 ----------------------------------------- -------- ----------------------------
 ID                                        NOT NULL NUMBER(38)
 NAME                                               CHAR(50)
 DEPARTMENT                                         CHAR(20)
 AGE                                                NUMBER(3)

SQL> commit;

커밋이 완료되었습니다.

SQL> spool off
