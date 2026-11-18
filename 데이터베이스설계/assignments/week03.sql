/* =====================Q1================ */.
/* STUDENT_GRADE 정규화 후 스키마 */
SQL> DESC STUDENT_GRADE_1;
 이름                                                                                널?      유형
 ----------------------------------------------------------------------------------- -------- --------------------------------------------------------
 SID                                                                                 NOT NULL VARCHAR2(10)
 CID                                                                                 NOT NULL VARCHAR2(10)
 SCORE                                                                                        NUMBER(4)
 GRADE                                                                                        VARCHAR2(5)

/* STUDENT_GRADE 정규화 후 변환 결과 */
SQL> SELECT * FROM STUDENT_GRADE_1 ORDER BY Sid, Cid;

SID                  CID                       SCORE GRADE                                                                                            
-------------------- -------------------- ---------- ----------                                                                                       
2016127059           C100                         95 A                                                                                                
2016127060           C200                         81 B                                                                                                
2016127061           C200                         84 B                                                                                                
2016127062           C300                         70 C                                                                                                

/* STUDENT_GRADE 정규화 후 스키마 */
SQL> 
SQL> DESC STUDENT_GRADE_2;
 이름                                                                                널?      유형
 ----------------------------------------------------------------------------------- -------- --------------------------------------------------------
 CID                                                                                 NOT NULL VARCHAR2(10)
 CNAME                                                                                        VARCHAR2(15)
 CUNIT                                                                                        VARCHAR2(2)

/* STUDENT_GRADE 정규화 후 변환 결과 */
SQL> SELECT * FROM STUDENT_GRADE_2 ORDER BY Cid;

CID                  CNAME                          CUNI                                                                                              
-------------------- ------------------------------ ----                                                                                              
C100                 CLanguage                      3                                                                                                 
C200                 Database                       3                                                                                                 
C300                 Programing                     3          

/* 참조 무결성 확인 */                                                                                       
SQL> SELECT Cid FROM STUDENT_GRADE_1 WHERE Cid NOT IN (SELECT S1.Cid FROM STUDENT_GRADE_1 S1,STUDENT_GRADE_2 S2 WHERE S1.Cid = S2.Cid);

선택된 레코드가 없습니다.

/* 변환 전 */
SQL> 
SQL> SELECT Sid, Cid, Score, Grade, Cname, Cunit FROM STUDENT_GRADE ORDER BY SID,CID;

SID                                                                                                                                                   
--------------------                                                                                                                                  
CID                                                                                                                                                   
------------------------------------------------------------------------------------------------------------------------------------------------------
     SCORE GRADE      CNAME                          CUNI                                                                                             
---------- ---------- ------------------------------ ----                                                                                             
2016127059                                                                                                                                            
C100                                                                                                                                                  
        95 A          CLanguage                      3                                                                                                
                                                                                                                                                      
2016127060                                                                                                                                            
C200                                                                                                                                                  
        81 B          Database                       3                                                                                                
                                                                                                                                                      
2016127061                                                                                                                                            
C200                                                                                                                                                  
        84 B          Database                       3                                                                                                
                                                                                                                                                      
2016127062                                                                                                                                            
C300                                                                                                                                                  
        70 C          Programing                     3                                                                                                
                                                                                                                                                      
/* 변환 후 */
SQL> SELECT Sid, Cid, Score, Grade, Cname, Cunit FROM STUDENT_GRADE_1 NATURAL JOIN STUDENT_GRADE_2 ORDER BY SID,CID;

SID                  CID                       SCORE GRADE      CNAME                          CUNI                                                   
-------------------- -------------------- ---------- ---------- ------------------------------ ----                                                   
2016127059           C100                         95 A          CLanguage                      3                                                      
2016127060           C200                         81 B          Database                       3                                                      
2016127061           C200                         84 B          Database                       3                                                      
2016127062           C300                         70 C          Programing                     3                                                      

/* 타당성
기본키는 (Sid,Cid) 복합키이다. 하지만, FD2(Cid -> Cname,Cunit)으로 부분 함수 종속인 부분이 있어 기본키 전체에 대한 완전 함수 종속에 위배된다. 따라서, Cid를 기본키로 하고 Cname,Cunit을 속성으로 같은 별도의 릴레이션으로 분리한다면 2정규형으로 (Sid,Cid) -> Score,Grade 와 (Cid) -> Cname,Cunit의 두 릴레이션으로 분리한다면 무손실로 분해할 수 있다. 그렇다면 분리한 릴레이션들 사이에 공통으로 갖는 Cid로 자연 조인을 하면 정규화이전의 상태를 얻을 수 있다. 
*/

/* ======================== Q2 ======================= */

/* STUDENT_INFO_1 정규화 후 스키마 */
SQL> DESC STUDENT_INFO_1_1;
 이름                                                                                널?      유형
 ----------------------------------------------------------------------------------- -------- --------------------------------------------------------
 SID                                                                                 NOT NULL VARCHAR2(10)
 SNAME                                                                                        VARCHAR2(25)
 PHONE                                                                                        VARCHAR2(25)
 MID                                                                                          VARCHAR2(5)

/* STUDENT_INFO_1 정규화 후 변환 결과 */
SQL> SELECT * FROM STUDENT_INFO_1_1 ORDER BY Sid;

SID                  SNAME                                              PHONE                                              MID                        
-------------------- -------------------------------------------------- -------------------------------------------------- ----------                 
2018121001           James                                              010-0000-0001                                      C1041                      
2018121002           Michael                                            010-0000-0002                                      C1041                      
2018121003           Lisa                                               010-0000-0003                                      A2004                      
2018121004           Carol                                              010-0000-0004                                      A2004                      

/* STUDENT_INFO_1 정규화 후 스키마 */
SQL> DESC STUDENT_INFO_1_2;
 이름                                                                                널?      유형
 ----------------------------------------------------------------------------------- -------- --------------------------------------------------------
 MID                                                                                 NOT NULL VARCHAR2(5)
 MNAME                                                                                        VARCHAR2(25)

/* STUDENT_INFO_1 정규화 후 변환 결과 */
SQL> SELECT * FROM STUDENT_INFO_1_2 ORDER BY Mid;

MID        MNAME                                                                                                                                      
---------- --------------------------------------------------                                                                                         
A2004      ArtificialIntelligence                                                                                                                     
C1041      ComputerScience                                                                                                                            

/* 참조 무결성 확인 */   
SQL> SELECT Mid FROM STUDENT_INFO_1_1 WHERE Mid NOT IN (SELECT I1.Mid FROM STUDENT_INFO_1_1 I1,STUDENT_INFO_1_2 I2 WHERE I1.MID=I2.MID);

선택된 레코드가 없습니다.

/* 변환 전 */
SQL> 
SQL> SELECT Sid, Sname, Phone, Mid, Mname FROM STUDENT_INFO_1 ORDER BY SID;

SID                  SNAME                                              PHONE                                              MID                        
-------------------- -------------------------------------------------- -------------------------------------------------- ----------                 
MNAME                                                                                                                                                 
--------------------------------------------------                                                                                                    
2018121001           James                                              010-0000-0001                                      C1041                      
ComputerScience                                                                                                                                       
                                                                                                                                                      
2018121002           Michael                                            010-0000-0002                                      C1041                      
ComputerScience                                                                                                                                       
                                                                                                                                                      
2018121003           Lisa                                               010-0000-0003                                      A2004                      
ArtificialIntelligence                                                                                                                                
                                                                                                                                                      
2018121004           Carol                                              010-0000-0004                                      A2004                      
ArtificialIntelligence                                                                                                                                
                                                                                                                                                      

/* 변환 후 */
SQL> SELECT Sid, Sname, Phone, Mid, Mname FROM STUDENT_INFO_1_1 NATURAL JOIN STUDENT_INFO_1_2 ORDER BY SID;

SID                  SNAME                                              PHONE                                              MID                        
-------------------- -------------------------------------------------- -------------------------------------------------- ----------                 
MNAME                                                                                                                                                 
--------------------------------------------------                                                                                                    
2018121001           James                                              010-0000-0001                                      C1041                      
ComputerScience                                                                                                                                       
                                                                                                                                                      
2018121002           Michael                                            010-0000-0002                                      C1041                      
ComputerScience                                                                                                                                       
                                                                                                                                                      
2018121003           Lisa                                               010-0000-0003                                      A2004                      
ArtificialIntelligence                                                                                                                                
                                                                                                                                                      
2018121004           Carol                                              010-0000-0004                                      A2004                      
ArtificialIntelligence                                                                                                                                
                                                                                                                                                      
/* 타당성
기본키가 Sid 단일 속성이기에 2정규형상으로는 위배되지 않는다. 하지만, Sid->Mid->Mname 관계가 성립해 Mname은 Mid에 직접 종속되어 있기에 Mid라는 기본키가 아닌 일반 속성을 거쳐 간접적으로 Sid에 종속되어 있다고 볼 수 있기에, 이행적 함수 종속으로 3정규형에 위배된다. 따라서, Mid에 종속되는 Mname을 별도 릴레이션으로 분리해 (Sid)->Sname,Phone,Mid와 (Mid) -> Mname 으로 릴레이션을 분리한다면 무손실 분해를 할 수 있다. 따라서, 두 릴레이션에 동일하게 존재하는 Mid를 자연 조인한다면 정규화 이전의 상태를 얻을 수 있다.*/

SQL> 
/* ------------------------------ Q3 ====================== */

/* PROJECT_INFO 정규화 후 스키마 */
SQL> DESC PROJECT_INFO_1;
 이름                                                                                널?      유형
 ----------------------------------------------------------------------------------- -------- --------------------------------------------------------
 DNAME                                                                               NOT NULL VARCHAR2(25)
 MANAGER                                                                             NOT NULL VARCHAR2(25)

/* PROJECT_INFO 정규화 후 변환 결과 */
SQL> SELECT * FROM PROJECT_INFO_1 ORDER BY Dname, Manager;

DNAME                                              MANAGER                                                                                            
-------------------------------------------------- --------------------------------------------------                                                 
Development                                        Sarah                                                                                              
MachineryDivision                                  Ruth                                                                                               
Management                                         Michelle                                                                                           
TechnicalSupport                                   Donna                                                                                              

/* PROJECT_INFO 정규화 후 스키마 */
SQL> DESC PROJECT_INFO_2;
 이름                                                                                널?      유형
 ----------------------------------------------------------------------------------- -------- --------------------------------------------------------
 PNAME                                                                                        VARCHAR2(25)
 MANAGER                                                                             NOT NULL VARCHAR2(25)

/* PROJECT_INFO 정규화 후 변환 결과 */
SQL> SELECT * FROM PROJECT_INFO_2 ORDER BY Manager;

PNAME                                              MANAGER                                                                                            
-------------------------------------------------- --------------------------------------------------                                                 
RobotProject                                       Donna                                                                                              
SchoolProject                                      Michelle                                                                                           
RobotProject                                       Ruth                                                                                               
ProgrammingProject                                 Sarah                                                                                              

/* 참조 무결성 확인 */   
SQL> 
SQL> 
SQL> SELECT MANAGER FROM PROJECT_INFO_1 WHERE MANAGER NOT IN (SELECT P1.MANAGER FROM PROJECT_INFO_1 P1,PROJECT_INFO_2 P2 WHERE P1.MANAGER=P2.MANAGER);

선택된 레코드가 없습니다.

/* 변환 전 */
SQL> 
SQL> SELECT Pname, Dname, Manager FROM PROJECT_INFO ORDER BY PNAME,DNAME;

PNAME                                              DNAME                                                                                              
-------------------------------------------------- --------------------------------------------------                                                 
MANAGER                                                                                                                                               
--------------------------------------------------                                                                                                    
ProgrammingProject                                 Development                                                                                        
Sarah                                                                                                                                                 
                                                                                                                                                      
RobotProject                                       MachineryDivision                                                                                  
Ruth                                                                                                                                                  
                                                                                                                                                      
RobotProject                                       TechnicalSupport                                                                                   
Donna                                                                                                                                                 
                                                                                                                                                      
SchoolProject                                      Management                                                                                         
Michelle                                                                                                                                              
                                                                                                                                                      
/* 변환 후 */
SQL> SELECT Pname, Dname, Manager FROM PROJECT_INFO_1 NATURAL JOIN PROJECT_INFO_2 ORDER BY PNAME,DNAME;

PNAME                                              DNAME                                                                                              
-------------------------------------------------- --------------------------------------------------                                                 
MANAGER                                                                                                                                               
--------------------------------------------------                                                                                                    
ProgrammingProject                                 Development                                                                                        
Sarah                                                                                                                                                 
                                                                                                                                                      
RobotProject                                       MachineryDivision                                                                                  
Ruth                                                                                                                                                  
                                                                                                                                                      
RobotProject                                       TechnicalSupport                                                                                   
Donna                                                                                                                                                 
                                                                                                                                                      
SchoolProject                                      Management                                                                                         
Michelle                                                                                                                                              
   
/* 타당성 :
기본키는 (Pname, Dname)이며, Dname과 Pname 모두 기본키를 구성해 Manager를 종속하고 있고, Manager가 Pname을 결정하고 있는 상태이기에, 이행적 종속은 존재하지 않고, 부분 함수 종속 또한 없어 3정규형을 위배하지 않으나, Manager -> Pname에서 결정자인 Manager는  후보키가 아니다. 하지만 BCNF에서는 모든 결정자는 후보키여야 한다는 조건을 위배하므로 BCNF를 위반한다. 따라서, (Manager)->Pname으로 릴레이션을 분리하고, (Dname,Manager)로 복합키로 이루어진 릴레이션을 구성 한다면 모든 결정자가 후보키를 이루고 있는 동시에 무손실 분해가 이루어 있다. 따라서, 두 릴레이션에 동일하게 존재하는 Manager로 자연조인을 한다면 정규화 이전과 같은 결과를 얻을 수 있다. */
/* ===================-- Q4 ====================*/

/* STUDENT_INFO_2 정규화 후 스키마 */
SQL> DESC STUDENT_INFO_2_1;
 이름                                                                                널?      유형
 ----------------------------------------------------------------------------------- -------- --------------------------------------------------------
 SNAME                                                                               NOT NULL VARCHAR2(10)
 CLUB                                                                                NOT NULL VARCHAR2(25)

/* STUDENT_INFO_2 정규화 후 변환 결과 */
SQL> SELECT * FROM STUDENT_INFO_2_1 ORDER BY Sname, Club;

SNAME                CLUB                                                                                                                             
-------------------- --------------------------------------------------                                                                               
Chau                 BookClub                                                                                                                         
Chau                 PhotographyClub                                                                                                                  
Green                CookingClub                                                                                                                      
Jones                BadmintonClub                                                                                                                    
Jones                DanceClub                                                                                                                        
Jones                MusicClub                                                                                                                        

6 행이 선택되었습니다.

/* STUDENT_INFO_2 정규화 후 스키마 */
SQL> DESC STUDENT_INFO_2_2;
 이름                                                                                널?      유형
 ----------------------------------------------------------------------------------- -------- --------------------------------------------------------
 SNAME                                                                               NOT NULL VARCHAR2(10)
 VOLUNTEER                                                                           NOT NULL VARCHAR2(25)

/* STUDENT_INFO_2 정규화 후 변환 결과 */
SQL> SELECT * FROM STUDENT_INFO_2_2 ORDER BY Sname, Volunteer;

SNAME                VOLUNTEER                                                                                                                        
-------------------- --------------------------------------------------                                                                               
Chau                 SeniorCenter                                                                                                                     
Green                Orphanage                                                                                                                        
Jones                HomelessShelter                                                                                                                  
Jones                SeniorCenter                                                                                                                     
                                                                                                                                               

/* 참조 무결성 확인 */   
SQL> SELECT SNAME FROM STUDENT_INFO_2_1 WHERE SNAME NOT IN (SELECT S1.SNAME FROM STUDENT_INFO_2_1 S1,STUDENT_INFO_2_2 S2 WHERE S1.SNAME=S2.SNAME);

선택된 레코드가 없습니다.

/* 변환 전 */
SQL> 
SQL> SELECT Sname, Club, Volunteer FROM STUDENT_INFO_2 ORDER BY Sname, Club, Volunteer;

SNAME                CLUB                                               VOLUNTEER                                                                     
-------------------- -------------------------------------------------- --------------------------------------------------                            
Chau                 BookClub                                           SeniorCenter                                                                  
Chau                 PhotographyClub                                    SeniorCenter                                                                  
Green                CookingClub                                        Orphanage                                                                     
Jones                BadmintonClub                                      HomelessShelter                                                               
Jones                BadmintonClub                                      SeniorCenter                                                                  
Jones                DanceClub                                          HomelessShelter                                                               
Jones                DanceClub                                          SeniorCenter                                                                  
Jones                MusicClub                                          HomelessShelter                                                               
Jones                MusicClub                                          SeniorCenter                                                                  

9 행이 선택되었습니다.

/* 변환 후 */
SQL> SELECT Sname, Club, Volunteer FROM STUDENT_INFO_2_1 NATURAL JOIN STUDENT_INFO_2_2 ORDER BY Sname, Club, Volunteer;

SNAME                CLUB                                               VOLUNTEER                                                                     
-------------------- -------------------------------------------------- --------------------------------------------------                            
Chau                 BookClub                                           SeniorCenter                                                                  
Chau                 PhotographyClub                                    SeniorCenter                                                                  
Green                CookingClub                                        Orphanage                                                                     
Jones                BadmintonClub                                      HomelessShelter                                                               
Jones                BadmintonClub                                      SeniorCenter                                                                  
Jones                DanceClub                                          HomelessShelter                                                               
Jones                DanceClub                                          SeniorCenter                                                                  
Jones                MusicClub                                          HomelessShelter                                                               
Jones                MusicClub                                          SeniorCenter                                                                  

9 행이 선택되었습니다.
/* 타당성:
이 릴레이션에는 위반되는 함수 종속이 없어 BCNF까지 만족한다. 하지만, Sname->->Club하는 것과 Sname->->Volunteer에는 독립적인 다치 종속 관계이나, 한 릴레이션에 저장되며 카티션 곱으로 이루어 저장되고 있기에 4정규형에 위배되고 있다. 따라서, (Sname,Club)과 (Sname,Volunteer)로 완전히 분리하면 무손실 분해가 된다. 또한 Sname을 동일하게 가지고 있어 자연 조인을 통해 정규화 이전과 동일한 결과를 얻을 수 있다. */

SQL> spool off;
