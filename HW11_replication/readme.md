### Репликация

#### Цель:
- реализовать свой миникластер на 3 ВМ.

CREATE DATABASE Rep;  
\c Rep


- На 1 ВМ создаем таблицы test для записи, test2 для запросов на чтение.  

create table test (id integer, name varchar(50));  
insert into test (id, name) values (1, 'name1'), (2, 'name2'), (3, 'name3');

create table test2 (id integer, name varchar(50));

На ВМ2 создаем таблицы test и test2. Заполняем данными test2.  
insert into test2 (id, name) values (1, 'qwer1'), (2, 'qwer2'), (3, 'qwer3');

- Создаем публикацию таблицы test и подписываемся на публикацию таблицы test2 с ВМ №2. На 2 ВМ создаем таблицы test2 для записи, test для запросов на чтение. Создаем публикацию таблицы test2 и подписываемся на публикацию таблицы test1 с ВМ №1.

#### На ВМ 1  
ALTER SYSTEM SET wal_level = logical;

Дадим доступ ВМ 2 к ВМ 1:  
В postgresql.conf на первом сервере:  
listen_addresses = '*'  

В pg_hba.conf на ВМ 1:  
host    rep             all             10.128.0.20/32          md5

Рестартуем кластер  
sudo pg_ctlcluster 13 main restart

На ВМ 1 создаем публикацию:  
CREATE PUBLICATION test_pub FOR TABLE test;

Задать пароль  
\password  
11111

Просмотр созданной публикации на ВМ1  
\dRp+

На ВМ 2 создадим подписку к БД на таблицу test с ВМ 1  
CREATE SUBSCRIPTION test_sub  
CONNECTION 'host=postgres1 hostaddr=10.128.0.19 port=5432 user=postgres password=11111 dbname=rep'  
PUBLICATION test_pub WITH (copy_data = true);

#### На ВМ 2  
ALTER SYSTEM SET wal_level = logical;

Дадим доступ ВМ 1 к ВМ 2:  
В postgresql.conf на первом сервере:  
listen_addresses = '*'  

В pg_hba.conf на ВМ 1:  
host    rep             all             10.128.0.19/32          md5

Рестартуем кластер  
sudo pg_ctlcluster 13 main restart

На ВМ 2 создаем публикацию:  
CREATE PUBLICATION test2_pub FOR TABLE test2;

Задать пароль  
\password  
11111

Просмотр созданной публикации на ВМ1  
\dRp+

На ВМ 1 создадим подписку к БД на таблицу test2 с ВМ 2  
CREATE SUBSCRIPTION test2_sub  
CONNECTION 'host=postgres2 hostaddr=10.128.0.20 port=5432 user=postgres password=11111 dbname=rep'  
PUBLICATION test2_pub WITH (copy_data = true);

Смотрим подписки:  
\dRs+

Проверила, все работает.

- 3 ВМ использовать как реплику для чтения и бэкапов (подписаться на таблицы из ВМ №1 и №2 ). Небольшое описание, того, что получилось.
 
 На ВМ1 и ВМ2 в pg_hba.conf добавим адрес ВМ3 для доступа:  
 host    rep             all             10.128.0.21/32          md5
 
 На ВМ3 создаем БД rep и таблицы test и test2.  

На ВМ 3 создадим подписку к БД на таблицу test с ВМ 1  
CREATE SUBSCRIPTION test_sub_VM3  
CONNECTION 'host=postgres1 hostaddr=10.128.0.19 port=5432 user=postgres password=11111 dbname=rep'  
PUBLICATION test_pub WITH (copy_data = true);  

На ВМ 3 создадим подписку к БД на таблицу test2 с ВМ 2  
CREATE SUBSCRIPTION test2_sub_VM3  
CONNECTION 'host=postgres2 hostaddr=10.128.0.20 port=5432 user=postgres password=11111 dbname=rep'  
PUBLICATION test2_pub WITH (copy_data = true);  

select * from test;  
select * from test2;  
 
 Все работает.