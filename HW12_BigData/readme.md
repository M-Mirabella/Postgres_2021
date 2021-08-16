### Разворачиваем и настраиваем БД с большими данными

####Цель:
- знать различные механизмы загрузки данных
- уметь пользоваться различными механизмами загрузки данных

Необходимо провести сравнение скорости работы запросов на различных СУБД

- Выбрать одну из СУБД

В качестве второй СУБД выбрала MS SQL Server 2017, т.к. он установлен на моем ПК с 16 Гб оперативы, 4.20GHz, 8 ядер. 

- Загрузить в неё данные (10 Гб)

На GCS скачала часть таблицы Чикагского такси.
Загрузила его на локальный диск:

В PG:
CREATE DATABASE taxi;  
\c taxi

create table taxi_trips (  
unique_key text,  
taxi_id text,  
trip_start_timestamp TIMESTAMP,  
trip_end_timestamp TIMESTAMP,  
trip_seconds bigint,  
trip_miles numeric,  
pickup_census_tract bigint,  
dropoff_census_tract bigint,  
pickup_community_area bigint,  
dropoff_community_area bigint,  
fare numeric,  
tips numeric,  
tolls numeric,  
extras numeric,  
trip_total numeric,  
payment_type text,  
company text,  
pickup_latitude numeric,  
pickup_longitude numeric,  
pickup_location text,  
dropoff_latitude numeric,  
dropoff_longitude numeric,  
dropoff_location text  
);

Включим тайминг
\timing

COPY taxi_trips(unique_key,  
taxi_id,  
trip_start_timestamp,  
trip_end_timestamp,  
trip_seconds,  
trip_miles,  
pickup_census_tract,  
dropoff_census_tract,  
pickup_community_area,  
dropoff_community_area,  
fare,  
tips,  
tolls,  
extras,  
trip_total,  
payment_type,  
company,  
pickup_latitude,  
pickup_longitude,  
pickup_location,  
dropoff_latitude,  
dropoff_longitude,  
dropoff_location)  
FROM PROGRAM 'awk FNR-1 /tmp/ts_otus/*.csv | cat' DELIMITER ',' CSV HEADER;

COPY 28927717  
Time: 926304.233 ms (15:26.304)

Сравнить скорость выполнения запросов на PosgreSQL и выбранной СУБД

Запросы для импрорта приведены в MS SQL Bulk insert.sql. 44 файла импортировались за 21 минуту. Медленно, скорее всего из за курсора.

#### 1 запрос: 
select count (*) from taxi_trips; 

(No column name)  
28927717  

SQL Server Execution Times:  
   CPU time = 6249 ms,  elapsed time = 182152 ms.
   

PG:  
 count  
----------  
 28927717  
(1 row)

Time: 505222.557 ms (08:25.223)  

Индексов нет нигде.

#### 2 запрос:

SELECT payment_type, round(sum(tips)/sum(trip_total)*100, 0) + 0 as tips_percent, count(*) as c  
FROM taxi_trips  
group by payment_type  
order by 3;

 SQL Server Execution Times:  
   CPU time = 292189 ms,  elapsed time = 552122 ms.

PG:  
Time: 463220.272 ms (07:43.220)


Описать что и как делали и с какими проблемами столкнулись

В PG вобще никаких проблем, спасибо Владимиру за подробнейшее объяснение в лекции. А вот с MS SQL ковырялась долго, т.к. операцию bulk insert, да еще из csv использую нечасто. Но хотелось очень это сделать.