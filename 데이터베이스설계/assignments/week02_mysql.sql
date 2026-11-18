mysql> use dbtest;
Database changed

--테이블 생성 및 결과 확인
mysql> show tables;
+------------------+
| Tables_in_dbtest |
+------------------+
| customer         |
| dept             |
| emp              |
| invoice          |
| invoice_item     |
| salgrade         |
+------------------+
6 rows in set (0.035 sec)

--스키마 생성 및 결과 확인 (customer)
mysql> desc customer;
+------------+--------------+------+-----+---------+-------+
| Field      | Type         | Null | Key | Default | Extra |
+------------+--------------+------+-----+---------+-------+
| CUSTOMERID | int          | NO   | PRI | NULL    |       |
| FIRSTNAME  | varchar(25)  | NO   |     | NULL    |       |
| LASTNAME   | varchar(25)  | NO   |     | NULL    |       |
| PHONE      | varchar(12)  | YES  |     | NULL    |       |
| EMAIL      | varchar(100) | YES  |     | NULL    |       |
+------------+--------------+------+-----+---------+-------+
5 rows in set (0.029 sec)

--스키마 생성 및 결과 확인 (invoice)
mysql> desc invoice;
+----------------+--------------+------+-----+---------+-------+
| Field          | Type         | Null | Key | Default | Extra |
+----------------+--------------+------+-----+---------+-------+
| INVOICENUMBER  | int          | NO   | PRI | NULL    |       |
| CUSTOMERNUMBER | int          | NO   | MUL | NULL    |       |
| DATEIN         | date         | NO   |     | NULL    |       |
| DATEOUT        | date         | YES  |     | NULL    |       |
| TOTALAMOUNT    | decimal(8,2) | YES  |     | NULL    |       |
+----------------+--------------+------+-----+---------+-------+
5 rows in set (0.029 sec)

--스키마 생성 및 결과 확인(invoice_item)
mysql> desc invoice_item;
+---------------+--------------+------+-----+---------+-------+
| Field         | Type         | Null | Key | Default | Extra |
+---------------+--------------+------+-----+---------+-------+
| INVOICENUMBER | int          | NO   | PRI | NULL    |       |
| ITEMNUMBER    | int          | NO   | PRI | NULL    |       |
| ITEM          | varchar(50)  | NO   |     | NULL    |       |
| QUANTITY      | int          | NO   |     | NULL    |       |
| UNITPRICE     | decimal(8,2) | NO   |     | NULL    |       |
+---------------+--------------+------+-----+---------+-------+
5 rows in set (0.027 sec)

-- 인스턴스 생성 및 결과 확인(customer)
mysql> select * from customer;
+------------+-----------+-----------+--------------+--------------------------------+
| CUSTOMERID | FIRSTNAME | LASTNAME  | PHONE        | EMAIL                          |
+------------+-----------+-----------+--------------+--------------------------------+
|          1 | Nikki     | Kaccaton  | 723-543-1233 | Nikki.Kaccaton@somewhere.com   |
|          2 | Brenda    | Catnazaro | 723-543-2344 | Brenda.Catnazaro@somewhere.com |
|          3 | Bruce     | LeCat     | 723-543-3455 | Bruce.LeCat@somewhere.com      |
|          4 | Betsy     | Miller    | 725-654-3211 | Betsy.Miller@somewhere.com     |
|          5 | George    | Miller    | 725-654-4322 | George.Miller@somewhere.com    |
|          6 | Kathy     | Miller    | 723-514-9877 | Kathy.Miller@somewhere.com     |
|          7 | Betsy     | Miller    | 723-514-8766 | Betsy.Miller@elsewhere.com     |
+------------+-----------+-----------+--------------+--------------------------------+
7 rows in set (0.011 sec)

-- 인스턴스 생성 및 결과 확인(invoice)
mysql> select * from invoice;
+---------------+----------------+------------+------------+-------------+
| INVOICENUMBER | CUSTOMERNUMBER | DATEIN     | DATEOUT    | TOTALAMOUNT |
+---------------+----------------+------------+------------+-------------+
|       2015001 |              1 | 2015-10-04 | 2015-10-06 |      158.50 |
|       2015002 |              2 | 2015-10-04 | 2015-10-06 |       25.00 |
|       2015003 |              1 | 2015-10-06 | 2015-10-08 |       49.00 |
|       2015004 |              4 | 2015-10-06 | 2015-10-08 |       17.50 |
|       2015005 |              6 | 2015-10-07 | 2015-10-11 |       12.00 |
|       2015006 |              3 | 2015-10-11 | 2015-10-13 |      152.50 |
|       2015007 |              3 | 2015-10-11 | 2015-10-13 |        7.00 |
|       2015008 |              7 | 2015-10-12 | 2015-10-14 |      140.50 |
|       2015009 |              5 | 2015-10-12 | 2015-10-14 |       27.00 |
+---------------+----------------+------------+------------+-------------+
9 rows in set (0.011 sec)

-- 인스턴스 생성 및 결과 확인(invoice_item)
mysql> select * from invoice_item;
+---------------+------------+---------------+----------+-----------+
| INVOICENUMBER | ITEMNUMBER | ITEM          | QUANTITY | UNITPRICE |
+---------------+------------+---------------+----------+-----------+
|       2015001 |          1 | Blouse        |        2 |      3.50 |
|       2015001 |          2 | Dress Shirt   |        5 |      2.50 |
|       2015001 |          3 | Formal Gown   |        2 |     10.00 |
|       2015001 |          4 | Slacks-Mens   |       10 |      5.00 |
|       2015001 |          5 | Slacks-Womens |       10 |      6.00 |
|       2015001 |          6 | Suit-Mens     |        1 |      9.00 |
|       2015002 |          1 | Dress Shirt   |       10 |      2.50 |
|       2015003 |          1 | Slacks-Mens   |        5 |      5.00 |
|       2015003 |          2 | Slacks-Womens |        4 |      6.00 |
|       2015004 |          1 | Dress Shirt   |        7 |      2.50 |
|       2015005 |          1 | Blouse        |        2 |      3.50 |
|       2015005 |          2 | Dress Shirt   |        2 |      2.50 |
|       2015006 |          1 | Blouse        |        5 |      3.50 |
|       2015006 |          2 | Dress Shirt   |       10 |      2.50 |
|       2015006 |          3 | Slacks-Mens   |       10 |      5.00 |
|       2015006 |          4 | Slacks-Womens |       10 |      6.00 |
|       2015007 |          1 | Blouse        |        2 |      3.50 |
|       2015008 |          1 | Blouse        |        3 |      3.50 |
|       2015008 |          2 | Dress Shirt   |       12 |      2.50 |
|       2015008 |          3 | Slacks-Mens   |        8 |      5.00 |
|       2015008 |          4 | Slacks-Womens |       10 |      6.00 |
|       2015009 |          1 | Suit-Mens     |        3 |      9.00 |
+---------------+------------+---------------+----------+-----------+
22 rows in set (0.014 sec)

--질의 Q1
mysql> SELECT DATEIN,DATEOUT,PHONE FROM INVOICE I INNER JOIN CUSTOMER C ON C.CUSTOMERID=I.CUSTOMERNUMBER WHERE I.TOTALAMOUNT>=100;
+------------+------------+--------------+
| DATEIN     | DATEOUT    | PHONE        |
+------------+------------+--------------+
| 2015-10-04 | 2015-10-06 | 723-543-1233 |
| 2015-10-11 | 2015-10-13 | 723-543-3455 |
| 2015-10-12 | 2015-10-14 | 723-514-8766 |
+------------+------------+--------------+
3 rows in set (0.014 sec)

--질의 Q2
mysql> select phone,firstname from customer where firstname like 'B%';
+--------------+-----------+
| phone        | firstname |
+--------------+-----------+
| 723-543-2344 | Brenda    |
| 723-543-3455 | Bruce     |
| 725-654-3211 | Betsy     |
| 723-514-8766 | Betsy     |
+--------------+-----------+
4 rows in set (0.010 sec)

--질의 Q3
mysql> select max(totalamount),min(totalamount),avg(totalamount) from invoice;
+------------------+------------------+------------------+
| max(totalamount) | min(totalamount) | avg(totalamount) |
+------------------+------------------+------------------+
|           158.50 |             7.00 |        65.444444 |
+------------------+------------------+------------------+
1 row in set (0.009 sec)

--질의 Q4
mysql> select firstname,lastname,phone from customer where customerid in (select customernumber from invoice where totalamount>=100) order by lastname asc, firstname desc;
+-----------+----------+--------------+
| firstname | lastname | phone        |
+-----------+----------+--------------+
| Nikki     | Kaccaton | 723-543-1233 |
| Bruce     | LeCat    | 723-543-3455 |
| Betsy     | Miller   | 723-514-8766 |
+-----------+----------+--------------+
3 rows in set (0.017 sec)

--질의 Q5
mysql> SELECT FIRSTNAME,LASTNAME,PHONE FROM CUSTOMER C JOIN INVOICE I WHERE C.CUSTOMERID=I.CUSTOMERNUMBER AND TOTALAMOUNT>=100 ORDER BY LASTNAME ASC,FIRSTNAME DESC;
+-----------+----------+--------------+
| FIRSTNAME | LASTNAME | PHONE        |
+-----------+----------+--------------+
| Nikki     | Kaccaton | 723-543-1233 |
| Bruce     | LeCat    | 723-543-3455 |
| Betsy     | Miller   | 723-514-8766 |
+-----------+----------+--------------+
3 rows in set (0.012 sec)

--질의 Q6
mysql> select firstname,lastname,phone from Customer c inner join invoice i on c.customerid=i.customernumber where totalamount>=100 order by lastname asc,firstname desc;
+-----------+----------+--------------+
| firstname | lastname | phone        |
+-----------+----------+--------------+
| Nikki     | Kaccaton | 723-543-1233 |
| Bruce     | LeCat    | 723-543-3455 |
| Betsy     | Miller   | 723-514-8766 |
+-----------+----------+--------------+
3 rows in set (0.016 sec)

--질의 Q7
mysql> SELECT FirstName, LastName, Phone
    -> FROM CUSTOMER
    -> WHERE CustomerID IN (
    ->     SELECT CustomerNumber
    ->     FROM INVOICE
    ->     WHERE InvoiceNumber IN (
    ->         SELECT InvoiceNumber
    ->         FROM INVOICE_ITEM
    ->         WHERE Item = 'Dress Shirt'
    ->     )
    -> )
    -> ORDER BY LastName ASC, FirstName DESC;
+-----------+-----------+--------------+
| FirstName | LastName  | Phone        |
+-----------+-----------+--------------+
| Brenda    | Catnazaro | 723-543-2344 |
| Nikki     | Kaccaton  | 723-543-1233 |
| Bruce     | LeCat     | 723-543-3455 |
| Kathy     | Miller    | 723-514-9877 |
| Betsy     | Miller    | 725-654-3211 |
| Betsy     | Miller    | 723-514-8766 |
+-----------+-----------+--------------+
6 rows in set (0.015 sec)

--질의 Q8
mysql> SELECT FIRSTNAME,LASTNAME,PHONE FROM CUSTOMER C JOIN INVOICE I JOIN INVOICE_ITEM II WHERE II.INVOICENUMBER=I.INVOICENUMBER AND CUSTOMERID=CUSTOMERNUMBER AND ITEM='Dress Shirt' ORDER BY LASTNAME ASC,FIRSTNAME DESC;
+-----------+-----------+--------------+
| FIRSTNAME | LASTNAME  | PHONE        |
+-----------+-----------+--------------+
| Brenda    | Catnazaro | 723-543-2344 |
| Nikki     | Kaccaton  | 723-543-1233 |
| Bruce     | LeCat     | 723-543-3455 |
| Kathy     | Miller    | 723-514-9877 |
| Betsy     | Miller    | 725-654-3211 |
| Betsy     | Miller    | 723-514-8766 |
+-----------+-----------+--------------+
6 rows in set (0.017 sec)

--질의 Q9
mysql> SELECT FIRSTNAME,LASTNAME,PHONE FROM CUSTOMER JOIN INVOICE I ON CUSTOMERID=CUSTOMERNUMBER JOIN INVOICE_ITEM II ON I.INVOICENUMBER=II.INVOICENUMBER WHERE ITEM='Dress Shirt' ORDER BY LASTNAME ASC,FIRSTNAME DESC;
+-----------+-----------+--------------+
| FIRSTNAME | LASTNAME  | PHONE        |
+-----------+-----------+--------------+
| Brenda    | Catnazaro | 723-543-2344 |
| Nikki     | Kaccaton  | 723-543-1233 |
| Bruce     | LeCat     | 723-543-3455 |
| Kathy     | Miller    | 723-514-9877 |
| Betsy     | Miller    | 725-654-3211 |
| Betsy     | Miller    | 723-514-8766 |
+-----------+-----------+--------------+
6 rows in set (0.013 sec)

--질의 Q10
mysql> SELECT FIRSTNAME,LASTNAME,PHONE FROM CUSTOMER JOIN INVOICE I ON CUSTOMERID=CUSTOMERNUMBER WHERE I.INVOICENUMBER IN (SELECT II.INVOICENUMBER FROM INVOICE_ITEM II WHERE ITEM='Dress Shirt') ORDER BY LASTNAME ASC, FIRSTNAME DESC;
+-----------+-----------+--------------+
| FIRSTNAME | LASTNAME  | PHONE        |
+-----------+-----------+--------------+
| Brenda    | Catnazaro | 723-543-2344 |
| Nikki     | Kaccaton  | 723-543-1233 |
| Bruce     | LeCat     | 723-543-3455 |
| Kathy     | Miller    | 723-514-9877 |
| Betsy     | Miller    | 725-654-3211 |
| Betsy     | Miller    | 723-514-8766 |
+-----------+-----------+--------------+
6 rows in set (0.013 sec)

--질의 Q11
mysql> SELECT FIRSTNAME,LASTNAME,PHONE,TOTALAMOUNT FROM CUSTOMER JOIN INVOICE I ON CUSTOMERID=CUSTOMERNUMBER WHERE I.INVOICENUMBER IN (SELECT II.INVOICENUMBER FROM INVOICE_ITEM II WHERE ITEM='Dress Shirt') ORDER BY TOTALAMOUNT ASC,LASTNAME ASC, FIRSTNAME DESC;
+-----------+-----------+--------------+-------------+
| FIRSTNAME | LASTNAME  | PHONE        | TOTALAMOUNT |
+-----------+-----------+--------------+-------------+
| Kathy     | Miller    | 723-514-9877 |       12.00 |
| Betsy     | Miller    | 725-654-3211 |       17.50 |
| Brenda    | Catnazaro | 723-543-2344 |       25.00 |
| Betsy     | Miller    | 723-514-8766 |      140.50 |
| Bruce     | LeCat     | 723-543-3455 |      152.50 |
| Nikki     | Kaccaton  | 723-543-1233 |      158.50 |
+-----------+-----------+--------------+-------------+
6 rows in set (0.013 sec)

mysql> notee
