### Нагрузочное тестирование и тюнинг PostgreSQL

#### Цель:
- сделать нагрузочное тестирование PostgreSQL
- настроить параметры PostgreSQL для достижения максимальной производительности

- сделать проект ---10.  сделать инстанс Google Cloud Engine типа e2-medium с ОС Ubuntu 20.04 •
- поставить на него PostgreSQL 13 из пакетов собираемых postgres.org
- настроить кластер PostgreSQL 13 на максимальную производительность не обращая внимание на возможные проблемы с надежностью в случае аварийной перезагрузки виртуальной машины
- нагрузить кластер через утилиту https://github.com/Percona-Lab/sysbench-tpcc (требует установки https://github.com/akopytov/sysbench)

#### Установим Sysbench  

curl -s https://packagecloud.io/install/repositories/akopytov/sysbench/script.deb.sh  
sudo bash  
sudo apt -y install sysbench  

sudo -u postgres psql  

  
CREATE USER sbtest WITH PASSWORD 'password';  
 CREATE DATABASE sbtest;  
 GRANT ALL PRIVILEGES ON DATABASE sbtest TO sbtest;  
 
-- отредактируем pg_hba.conf:  
sudo nano /etc/postgresql/13/main/pg_hba.conf  

local   sbtest          sbtest                                  md5  

-- убедимся что sbtest может зайти в psql  
psql -U sbtest -d sbtest -W  

Скачаем sysbench-tpcc
wget https://github.com/Percona-Lab/sysbench-tpcc/archive/refs/heads/master.zip
unzip master.zip
cd sysbench-tpcc-master

./tpcc.lua --pgsql-host=127.0.0.1 --pgsql-user=sbtest --pgsql-password=password --pgsql-db=sbtest --time=150 --threads=20 --report-interval=1 --tables=10 --scale=3 --db-driver=pgsql prepare

./tpcc.lua --pgsql-host=127.0.0.1 --pgsql-user=sbtest --pgsql-password=password --pgsql-db=sbtest --time=150 --threads=20 --report-interval=1 --tables=10 --scale=3 --db-driver=pgsql run

- написать какого значения tps удалось достичь, показать какие параметры в какие значения устанавливали и почему

#### 1 тест.
Сначала я сделала тест на дефолтных настройках. Среднее tps = 107.18  

#### 2 тест
Далее взяла настройки рекомендованные сайтом https://pgtune.leopard.in.ua/#/ :  
shared_buffers = 1GB  
effective_cache_size = 3GB  
maintenance_work_mem = 256MB  
checkpoint_completion_target = 0.9  
wal_buffers = 16MB  
default_statistics_target = 100  
random_page_cost = 1.1  
effective_io_concurrency = 200  
work_mem = 10485kB  
min_wal_size = 2GB  
max_wal_size = 8GB  
max_worker_processes = 2  
max_parallel_workers_per_gather = 1  
max_parallel_workers = 2  
max_parallel_maintenance_workers = 1  

По тесту среднее tps составило 196.23.

#### 3 тест

checkpoint_timeout = 60min  
synchronous_commit = off  

По тесту среднее tps составило 197.44. Но были провалы

#### 4 тест

Настроила автовакуум как в лекции про автовакуум

По тесту среднее tps составило 172.82

#### Вывод: лучшие настройки дал сайт pgtune, дальше пыталась выкручивать их, но лучшего результата не добилась
