### Секционирование таблицы

- Цель:
-- научиться секционировать таблицы.

Секционировать большую таблицу из демо базы flights

#### 1. Скачаем БД flights, распакуем и установим.

- wget https://edu.postgrespro.ru/demo-big.zip  
- unzip demo-big.zip
- \i demo-big-20170815.sql

#### 2. Партиционируем таблицу tickets по хэшу, т.к. явного ключа партиционирования нет

-- переименуем старую таблицу  
ALTER TABLE tickets RENAME TO tickets_old;  

-- создадим новую с тем же именем  
CREATE TABLE tickets (  
    ticket_no character(13) NOT NULL,  
    book_ref character(6) NOT NULL,  
    passenger_id character varying(20) NOT NULL,  
    passenger_name text NOT NULL,  
    contact_data jsonb  
) partition by hash(ticket_no);   

create table tickets_1 partition of tickets FOR VALUES WITH (MODULUS 5, REMAINDER 0);  
create table tickets_2 partition of tickets FOR VALUES WITH (MODULUS 5, REMAINDER 1);  
create table tickets_3 partition of tickets FOR VALUES WITH (MODULUS 5, REMAINDER 2);  
create table tickets_4 partition of tickets FOR VALUES WITH (MODULUS 5, REMAINDER 3);  
create table tickets_5 partition of tickets FOR VALUES WITH (MODULUS 5, REMAINDER 4);  

insert into tickets ( ticket_no, book_ref, passenger_id, passenger_name, contact_data)  
select  ticket_no, book_ref, passenger_id, passenger_name, contact_data  
from tickets_old;

select count(*) from tickets; -- 2949857  
select count(*) from tickets_1; -- 589653  
select count(*) from tickets_2; -- 588455  
select count(*) from tickets_3; -- 590877  
select count(*) from tickets_4; -- 590461  
select count(*) from tickets_5; -- 590411  
-- 2949857 - в сумме по секциям  

#### 3. Партиционируем таблицу bookings по диапазону  

-- переименуем старую таблицу  
ALTER TABLE bookings RENAME TO bookings_old;  

CREATE TABLE bookings (  
    book_ref character(6) NOT NULL,  
    book_date timestamp with time zone NOT NULL,  
    total_amount numeric(10,2) NOT NULL  
) partition by range (book_date);  

create table bookings_2016_Q3 partition of bookings for values from ('2016-07-01') to ('2016-10-01');  
create table bookings_2016_Q4 partition of bookings for values from ('2016-10-01') to ('2017-01-01');  
create table bookings_2017_Q1 partition of bookings for values from ('2017-01-01') to ('2017-04-01');  
create table bookings_2017_Q2 partition of bookings for values from ('2017-04-01') to ('2017-07-01');  
create table bookings_2017_Q3 partition of bookings for values from ('2017-07-01') to ('2017-10-01');  

insert into bookings (book_ref, book_date, total_amount)  
select book_ref, book_date, total_amount  
from bookings_old;  
 
