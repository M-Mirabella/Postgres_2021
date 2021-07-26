### Механизм блокировок

#### Цель:
- понимать как работает механизм блокировок объектов и строк

-- Подготовим данные

create table t1(id int);  

insert into t1(id)  
select generate_series  
from generate_series(1, 100000);

#### Настройте сервер так, чтобы в журнал сообщений сбрасывалась информация о блокировках, удерживаемых более 200 миллисекунд.  
    Воспроизведите ситуацию, при которой в журнале появятся такие сообщения.
	
-- В /etc/postgresql/13/main/postgresql.conf изменила пераметры:

log_lock_waits = on;
deadlock_timeout = 200ms;

-- В первом терминале начнем транзакцию:
Begin;
Update t1
set id = id+1
where id > 500;

-- Во втором терминале:
Begin;
Alter table t1 add column name varchar(50);

-- В журнале появились сообщения:

2021-07-26 16:55:14.445 UTC [2718] postgres@postgres LOG:  process 2718 still waiting for AccessExclusiveLock on relation 16384 of database 1344>
2021-07-26 16:55:14.445 UTC [2718] postgres@postgres DETAIL:  Process holding the lock: 2613. Wait queue: 2718.
2021-07-26 16:55:14.445 UTC [2718] postgres@postgres STATEMENT:  Alter table t1 add column name varchar(50);
	
#### Смоделируйте ситуацию обновления одной и той же строки тремя командами UPDATE в разных сеансах.  
    Изучите возникшие блокировки в представлении pg_locks и убедитесь, что все они понятны.  
	Пришлите список блокировок и объясните, что значит каждая.
	
Begin;  
Update t1  
set name = 'name1'  
where id = 1;

-------------------
SELECT locktype, relation::REGCLASS, virtualxid AS virtxid, transactionid AS xid, mode, granted FROM pg_locks;  

   locktype    | relation  | virtxid | xid |       mode       | granted  
---------------+-----------+---------+-----+------------------+---------  
 relation      | pg_locks  |         |     | AccessShareLock  | t   -- Разделяемая блокировка на таблицу pg_locks, которую мы сейчас смотрим
 virtualxid    |           | 6/7     |     | ExclusiveLock    | t   -- Эксклюзивная блокировка на виртуальный идентификатор транзакции
 relation      | t1_id_idx |         |     | RowExclusiveLock | t   -- Блокировка при модификации индекса
 relation      | t1        |         |     | RowExclusiveLock | t   -- Блокировка при изменении данных в таблице
 virtualxid    |           | 5/36    |     | ExclusiveLock    | t  
 relation      | t1_id_idx |         |     | RowExclusiveLock | t  
 relation      | t1        |         |     | RowExclusiveLock | t  
 virtualxid    |           | 4/90    |     | ExclusiveLock    | t  
 relation      | t1_id_idx |         |     | RowExclusiveLock | t  
 relation      | t1        |         |     | RowExclusiveLock | t  
 virtualxid    |           | 3/292   |     | ExclusiveLock    | t  
 transactionid |           |         | 491 | ShareLock        | f   -- блокировка вторым сеансом transactionid первого сеанса. Не выдана
 transactionid |           |         | 491 | ExclusiveLock    | t   -- блокировка реальной транзакции меняющей данные первого сеанса
 tuple         | t1        |         |     | ExclusiveLock    | t   -- блокировка кортежа, в коротором меняются данные
 transactionid |           |         | 492 | ExclusiveLock    | t   -- блокировка реальной транзакции меняющей данные второго сеанса
 transactionid |           |         | 493 | ExclusiveLock    | t  -- блокировка реальной транзакции меняющей данные третьего сеанса
 tuple         | t1        |         |     | ExclusiveLock    | f   -- блокировка кортежа, не выдана


	
#### Воспроизведите взаимоблокировку трех транзакций. Можно ли разобраться в ситуации постфактум, изучая журнал сообщений?

Begin;  
Update t1  
set name = 'name2'  
where id = 2;

2021-07-26 19:40:34.336 UTC [2718] postgres@postgres LOG:  process 2718 still waiting for ShareLock on transaction 494 after 200.180 ms
2021-07-26 19:40:34.336 UTC [2718] postgres@postgres DETAIL:  Process holding the lock: 3066. Wait queue: 2718.
2021-07-26 19:40:34.336 UTC [2718] postgres@postgres CONTEXT:  while updating tuple (0,2) in relation "t1"
2021-07-26 19:40:34.336 UTC [2718] postgres@postgres STATEMENT:  Update t1
        set name = 'name2'
        where id = 2;
2021-07-26 19:40:40.756 UTC [3633] postgres@postgres LOG:  process 3633 still waiting for ExclusiveLock on tuple (0,2) of relation 16384 of database 13445 after 200.14>
2021-07-26 19:40:40.756 UTC [3633] postgres@postgres DETAIL:  Process holding the lock: 2718. Wait queue: 3633.
2021-07-26 19:40:40.756 UTC [3633] postgres@postgres STATEMENT:  Update t1
        set name = 'name2'
        where id = 2;

-- Я считаю можно, т.к. есть текст блокирующего запроса и можно хотя бы определить откуда идет его вызов и какие операции блокируют друг друга.


#### Могут ли две транзакции, выполняющие единственную команду UPDATE одной и той же таблицы (без where), заблокировать друг друга?  
    Попробуйте воспроизвести такую ситуацию.
	
-- думаю такое возможно когда таблица большая и операция UPDATE будет выполняться долго. Тогда другая транзация будет ожидать окончания первой,
но взаимоблокировки все равно происходить не должны.

insert into t1 (id, name)  
select generate_series, 'name'  
from generate_series(100001, 200000001);

Update t1  
set id = id+1;  

2021-07-26 20:10:35.165 UTC [2718] postgres@postgres LOG:  process 2718 still waiting for ShareLock on transaction 506 after 200.101 ms  
2021-07-26 20:10:35.165 UTC [2718] postgres@postgres DETAIL:  Process holding the lock: 3066. Wait queue: 2718.  
2021-07-26 20:10:35.165 UTC [2718] postgres@postgres CONTEXT:  while updating tuple (163940,39) in relation "t1"  
2021-07-26 20:10:35.165 UTC [2718] postgres@postgres STATEMENT:  Update t1  
        set id = id+1;  
2021-07-26 20:13:21.921 UTC [2718] postgres@postgres LOG:  process 2718 acquired ShareLock on transaction 506 after 166956.057 ms  
2021-07-26 20:13:21.921 UTC [2718] postgres@postgres CONTEXT:  while updating tuple (163940,39) in relation "t1"  
2021-07-26 20:13:21.921 UTC [2718] postgres@postgres STATEMENT:  Update t1  
        set id = id+1;  

То есть это не взаимоблокировка, а первая транзация выполняетя долго, а вторая ожидает ее окончания. Когда первая закончилась, вторая получила свобю блокировку и тоже выполнилась.

