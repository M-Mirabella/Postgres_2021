### Работа с журналами

#### Настройте выполнение контрольной точки раз в 30 секунд.

- В файле /etc/postgresql/13/main/postgresql.conf установила checkpoint_timeout = 30s 
перезагрузила сервер

#### 10 минут c помощью утилиты pgbench подавайте нагрузку.

- pgbench -c8 -P 60 -T 600 -U postgres postgres

#### Измерьте, какой объем журнальных файлов был сгенерирован за это время.  

    SELECT pg_current_wal_insert_lsn();  
    pg_current_wal_insert_lsn перед запуском pgbench  
---------------------------  
 0/50657600  

    pg_current_wal_insert_lsn Сразу после окончания  
---------------------------  
 0/6F8F00C0  

SELECT '0/6F8F00C0'::pg_lsn - '0/50657600'::pg_lsn;  

сгенерировано данных:  
 522816192 B = 522,82 MB  

#### Оцените, какой объем приходится в среднем на одну контрольную точку.

- 522816192/20 B = 26 140 809,6 B = 26,14 MB на одну точку

#### Проверьте данные статистики: все ли контрольные точки выполнялись точно по расписанию. Почему так произошло?

- SELECT * FROM pg_stat_bgwriter \gx  
-[ RECORD 1 ]---------+------------------------------  
checkpoints_timed     | 349  
checkpoints_req       | 0  

- Я так и не поняла как посмотреть время выполнения контрольных точек. Лекцию 5 раз смотрела, гуглила, информацию не нашла.  
  Я так понимаю, что если нечего будет писать, то и чекпоинта не будет.  
- Здесь похоже, что все чекпоинты выполнялись

#### Сравните tps в синхронном/асинхронном режиме утилитой pgbench. Объясните полученный результат.

- pgbench -c8 -P 1 -T 30 -U postgres postgres

    В синхронном режиме: среднее tps = 929.817669
    В асинхронном режиме: среднее tps = 2055.018820

    Асинхронный режим быстрее, т.к. сервер не ждет пока данные сбросятся в WAL, а сразу подтверждает транзакцию после её логического окончания.  
    Поэтому транзакции выполняются быстрее, однако это чревато потерей данных.

#### Создайте новый кластер с включенной контрольной суммой страниц.
	Создайте таблицу. Вставьте несколько значений. Выключите кластер.
	Измените пару байт в таблице. Включите кластер и сделайте выборку из таблицы.
	Что и почему произошло? как проигнорировать ошибку и продолжить работу?
	
- Создала postgres2

- Включим контрольные суммы 
sudo /usr/lib/postgresql/13/bin/pg_checksums -e -D /var/lib/postgresql/13/main

CREATE TABLE t1(c1 integer);

insert into t1 (c1)
select generate_series
from generate_series(1,1000);

SELECT pg_relation_filepath('t1');

    pg_relation_filepath
----------------------
 base/13445/16387
 
  sudo -u postgres pg_ctlcluster 13 main stop
  sudo -u postgres dd if=/dev/zero of=/var/lib/postgresql/13/main/base/13445/16387 oflag=dsync conv=notrunc bs=1 count=8

  sudo -u postgres pg_ctlcluster 13 main start
  
- select * from t1;

WARNING:  page verification failed, calculated checksum 51547 but expected 43892
ERROR:  invalid page in block 0 of relation base/13445/16387

ALTER SYSTEM SET ignore_checksum_failure = on;

SELECT pg_reload_conf();

- после этого данные выбираются, но с сообщением:

WARNING:  page verification failed, calculated checksum 51547 but expected 43892


	
	
