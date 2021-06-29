## Работа с базами данных, пользователями и правами

- Цель:  
    - создание новой базы данных, схемы и таблицы  
    - создание роли для чтения данных из созданной схемы созданной базы данных  
    - создание роли для чтения и записи из созданной схемы созданной базы данных

#### 1 создайте новый кластер PostgresSQL 13 (на выбор - GCE, CloudSQL) 

- gcloud beta compute --project=postgres2021-19831215 instances create postgres2 --zone=us-central1-a --machine-type=e2-medium --subnet=default --network-tier=PREMIUM --maintenance-policy=MIGRATE --service-account=456164116659-compute@developer.gserviceaccount.com --scopes=https://www.googleapis.com/auth/devstorage.read_only,https://www.googleapis.com/auth/logging.write,https://www.googleapis.com/auth/monitoring.write,https://www.googleapis.com/auth/servicecontrol,https://www.googleapis.com/auth/service.management.readonly,https://www.googleapis.com/auth/trace.append --image=ubuntu-2010-groovy-v20210211a --image-project=ubuntu-os-cloud --boot-disk-size=10GB --boot-disk-type=pd-ssd --boot-disk-device-name=postgres13 --no-shielded-secure-boot --shielded-vtpm --shielded-integrity-monitoring --reservation-affinity=any  

    gcloud compute ssh postgres2  

    sudo apt update && sudo apt upgrade -y && sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list' && wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add - && sudo apt-get update && sudo apt-get -y install postgresql && sudo apt install unzip

#### 2 зайдите в созданный кластер под пользователем postgres 

- sudo -u postgres psql 

#### 3 создайте новую базу данных testdb 

- CREATE DATABASE testdb;

#### 4 зайдите в созданную базу данных под пользователем postgres 

- \c testdb

#### 5 создайте новую схему testnm 

- CREATE SCHEMA testnm;

#### 6 создайте новую таблицу t1 с одной колонкой c1 типа integer 

- CREATE TABLE t1(c1 integer);

#### 7 вставьте строку со значением c1=1 

- INSERT INTO t1(c1) VALUES(1);

#### 8 создайте новую роль readonly 

- CREATE ROLE readonly;

#### 9 дайте новой роли право на подключение к базе данных testdb 

- GRANT CONNECT ON DATABASE testdb TO readonly;

#### 10 дайте новой роли право на использование схемы testnm 

- GRANT USAGE ON SCHEMA testnm TO readonly;

#### 11 дайте новой роли право на select для всех таблиц схемы testnm 

- GRANT SELECT ON ALL TABLES IN SCHEMA testnm TO readonly;

#### 12 создайте пользователя testread с паролем test123 

- CREATE USER testread WITH PASSWORD 'test123';

#### 13 дайте роль readonly пользователю testread 

- GRANT readonly TO testread;

#### 14 зайдите под пользователем testread в базу данных testdb 

- Для этого надо сначала нужно переключить аутентификацию на md5.  
Меняем пароль у пользователя postgres:  
    alter user postgres encrypted password 'p123';  
    
    отредактируем pg_hba.conf:  
    sudo nano /etc/postgresql/13/main/pg_hba.conf  

>local   all             postgres                                md5  
"local" is for Unix domain socket connections only  
local   all             all                                     md5  

    перезагружаем конфигурацию postgres из psql  
    select pg_reload_conf();

    \c testdb testread

#### 15 сделайте select * from t1; 

#### 16 получилось? (могло если вы делали сами не по шпаргалке и не упустили один существенный момент про который позже) 

#### 17 напишите что именно произошло в тексте домашнего задания 

- не получилось, пишет что у пользователя нет прав на эту таблицу

#### 18 у вас есть идеи почему? ведь права то дали? 

- таблица t1 создалась в схеме public, а права дали только на схему testnm

#### 19 посмотрите на список таблиц 

- \dt  
 
>       List of relations  
> Schema | Name | Type  |  Owner  
> --------+------+-------+----------  
> public | t1   | table | postgres

#### 20 подсказка в шпаргалке под пунктом 20 

#### 21 а почему так получилось с таблицей (если делали сами и без шпаргалки то может у вас все нормально) 

- потому что при создании таблицы не указали явно схему. В search_path стоит $user, public.  
    создавали таблицу от пользователя postgres, схемы postgres нет, поэтому таблица создалась в схеме public

#### 22 вернитесь в базу данных testdb под пользователем postgres 

- \c testdb postgres

#### 23 удалите таблицу t1 

- DROP TABLE t1;

#### 24 создайте ее заново но уже с явным указанием имени схемы testnm 

- CREATE TABLE testnm.t1(c1 integer);

#### 25 вставьте строку со значением c1=1 

- INSERT INTO testnm.t1(c1) VALUES(1);

#### 26 зайдите под пользователем testread в базу данных testdb 

- \c testdb testread

#### 27 сделайте select * from t1; 

#### 28 получилось? 29 есть идеи почему? если нет - смотрите шпаргалку 

- не получилось, потому что t1 пересоздавали, а права даны только на таблицы, которые были
  на тот момент. Смотрела шпаргалку

#### 30 как сделать так чтобы такое больше не повторялось? если нет идей - смотрите шпаргалку 

- Перечитала информацию на сайте postgrespro, не нашла описания что "GRANT SELECT ON ALL TABLES IN SCHEMA" действует только на уже созданные таблицы и не
распространяется на таблицы создаваемые в будущем.  

    \c testdb postgres;  
    alter default privileges in schema testnm grant select on tables to readonly;  
    \c testdb testread;

#### 31 сделайте select * from testnm.t1; 

#### 32 получилось? 

#### 33 есть идеи почему? если нет - смотрите шпаргалку 31 сделайте select * from testnm.t1; 

- надо опять дать права на уже созданную таблицу t1

#### 32 получилось? 

#### 33 ура! 

- Получилось

#### 34 теперь попробуйте выполнить команду create table t2(c1 integer); insert into t2 values (2); 

#### 35 а как так? нам же никто прав на создание таблиц и insert в них под ролью readonly? 

#### 36 есть идеи как убрать эти права? если нет - смотрите шпаргалку 

#### 37 если вы справились сами то расскажите что сделали и почему, если смотрели шпаргалку - объясните что сделали и почему выполнив указанные в ней команды 

- Потому что пользователь testread состоит в группе public и таблица t2 создалась в схеме public.

    \c testdb postgres;  
    revoke create on schema public from public; - запретили роли public создавать что либо в схеме public.  
    revoke all on database testdb from public; - запретили роли public создавать что либо в БД testdb.  
    \c testdb testread;   

#### 38 теперь попробуйте выполнить команду create table t3(c1 integer); insert into t2 values (2); 

#### 39 расскажите что получилось и почему

    create table t3(c1 integer); - на дал, т.к. нет прав на схему public  
    insert into t2 values (2); - получилось, т.к. мы запретили создавать новые обекты в Схеме public, а на эту таблицу права уже даны.  

- Теперь четко поняла про назначение прав в PG, про search_path и почему нужно запрещать схему public.
