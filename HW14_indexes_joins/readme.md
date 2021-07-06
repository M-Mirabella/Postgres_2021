### Работа с индексами, join'ами, статистикой

#### 0. создаем таблицы, заполняем данными

create table users(id int, FirstName varchar(100), LastName varchar(100)); 

create schema sales;  
create table sales.orders(id int, user_id int, order_date date, status varchar(50), stock_item varchar(200)); 

create table positions(id int, name varchar(50));

insert into users(id, FirstName, LastName)  
values (1, 'Александр', 'Максимов'),  
       (2, 'Игорь', 'Пшиков'),  
       (3, 'Татьяна', 'Гришина'),  
       (4, 'Елена', 'Забгаева'),  
       (5, 'Светлана', 'Радаева'),  
       (6, 'Вячеслав', 'Авдонин');  
	   
	   
insert into sales.orders(id, user_id, order_date, status, stock_item)
select generate_series, (random()*7), date'2020-01-01' + (random() * 300)::int as order_date
       , (array['новый', 'в обоработке', 'отправлен', 'доставлен', 'отменен'])[(random()*5)::int]
	   , concat_ws(' ', (array['Меркурий', 'Энергомера', 'Стриж', 'Миртек', 'Нева'])[(random()*5)::int]
           , (array['механический', 'электронный', 'интеллектуальный'])[(random()*3)::int]
           , (array['с табло', 'с GSM модулем', 'однотарифный', 'дифференциальный'])[(random()*4)::int]
		   )  
from generate_series(1, 1000000);

insert into positions(id, name)  
values (1, 'Юрист')
	, (2, 'Менеджер')
	, (3, 'Инженер')
	, (4, 'Программист')
	, (5, 'Бухгалтер');

#### 1 вариант: Создать индексы на БД, которые ускорят доступ к данным. В данном задании тренируются навыки:

Необходимо:

-  Создать индекс к какой-либо из таблиц вашей БД

drop index if exists sales.idx_ord_id;  
create index idx_ord_id on sales.orders(id);

-  Прислать текстом результат команды explain, в которой используется данный индекс

explain  
select * from sales.orders where id < 100;

                                 QUERY PLAN
-----------------------------------------------------------------------------
 Index Scan using idx_ord_id on orders  (cost=0.42..11.19 rows=101 width=83)
   Index Cond: (id < 100)

- Реализовать индекс для полнотекстового поиска

> для начала создадим колонку, по которой может работать индекс, заполним ее данными

alter table sales.orders drop column if exists stock_item_lexeme;  
alter table sales.orders add column stock_item_lexeme tsvector;  
update sales.orders  
set stock_item_lexeme = to_tsvector(stock_item);

> создаем индекс для полнотекстового поиска. Он имеет тип gin

drop index if exists sales.idx_ord_stockitem_lex;  
CREATE INDEX idx_ord_stockitem_lex ON sales.orders USING GIN (stock_item_lexeme);

explain  
select *  
from sales.orders  
where stock_item_lexeme @@ to_tsquery('интеллектуальный');

 QUERY PLAN                          
--------------------------------------------------------------------------------------------------
 Gather  (cost=2531.91..75437.32 rows=165633 width=165)  
   Workers Planned: 2  
   ->  Parallel Bitmap Heap Scan on orders  (cost=1531.91..57874.02 rows=69014 width=165)  
         Recheck Cond: (stock_item_lexeme @@ to_tsquery('интеллектуальный'::text))  
         ->  Bitmap Index Scan on idx_ord_stockitem_lex  (cost=0.00..1490.50 rows=165633 width=0)  
               Index Cond: (stock_item_lexeme @@ to_tsquery('интеллектуальный'::text))  

- Реализовать индекс на часть таблицы или индекс на поле с функцией

> Скорее всего будут выбираться действующие заказы, поэтому индекс строим только по ним.

drop index if exists sales.idx_ord_status;  
CREATE INDEX idx_ord_status ON sales.orders(status) where status != 'отменен';

explain  
select * from sales.orders where status = 'новый';

  QUERY PLAN                                 
-------------------------------------------------------------------------------------
 Bitmap Heap Scan on orders  (cost=2267.86..43015.52 rows=201733 width=165)  
   Recheck Cond: ((status)::text = 'новый'::text)  
   ->  Bitmap Index Scan on idx_ord_status  (cost=0.00..2217.42 rows=201733 width=0)  
         Index Cond: ((status)::text = 'новый'::text)  

- Создать индекс на несколько полей

> Можно создать индекс, построенный на некольких полях, а можно включить в индекс доп колонки для вывода в результат запроса (includ)  
> здесь индекс для поиска по нескольким полям

drop index if exists sales.idx_ord_orderdate_userid;  
create index idx_ord_orderdate_userid on sales.orders(order_date, user_id);  

explain  
select * from sales.orders where order_date between date'2020-01-01' and date'2020-06-30' and user_id = 5;  

                                                    QUERY PLAN                  
-------------------------------------------------------------------------------------------------------------------
 Bitmap Heap Scan on orders  (cost=9740.76..49501.64 rows=87707 width=165)  
   Recheck Cond: ((order_date >= '2020-01-01'::date) AND (order_date <= '2020-06-30'::date) AND (user_id = 5))  
   ->  Bitmap Index Scan on idx_ord_orderdate_userid  (cost=0.00..9718.84 rows=87707 width=0)  
         Index Cond: ((order_date >= '2020-01-01'::date) AND (order_date <= '2020-06-30'::date) AND (user_id = 5))  

- Написать комментарии к каждому из индексов
- Описать что и как делали и с какими проблемами столкнулись

> Проблем не было.

#### 2 вариант: В результате выполнения ДЗ вы научитесь пользоваться различными вариантами соединения таблиц. В данном задании тренируются навыки:
написания запросов с различными типами соединений

Необходимо:

- Реализовать прямое соединение двух или более таблиц

select concat_ws(' ', users.LastName, users.FirstName) as user, count(ord.*)  
from sales.orders ord  
join users on users.id = ord.user_id  
where ord.order_date between date'2020-01-01' and date'2020-06-30'  
group by users.LastName, users.FirstName;  

- Реализовать левостороннее (или правостороннее) соединение двух или более таблиц

select coalesce(users.LastName, 'Неизвестный') as user, count(ord.*)  
from sales.orders ord  
left join users on users.id = ord.user_id  
where ord.order_date between date'2020-01-01' and date'2020-06-30'  
group by users.LastName, users.FirstName;  

- Реализовать кросс соединение двух или более таблиц

> весьма синтетический и известный пример. Ничего другого имеющего смысл не придумалось.

create table month(name varchar(20));  
insert into month (name)  
values('январь'), ('февраль'), ('март'), ('апрель'), ('май'), ('июнь'), ('июль'), ('август'), ('сентябрь'),  
 ('октябрь'), ('ноябрь'), ('декабрь');

select *  
from month  
cross join (select generate_series as number  
              from generate_series(2021, 2025)) as year;

- Реализовать полное соединение двух или более таблиц
	
alter table users add column position_id int;  
update users  
set position_id = random()*4::int;  

select *  
from users  
full join positions on positions.id = users.position_id;  
	
- Реализовать запрос, в котором будут использованы разные типы соединений

select positions.name, concat_ws(' ', users.LastName, users.FirstName) as user, count(ord.*)  
from sales.orders ord  
inner join users on users.id = ord.user_id   
left join positions on positions.id = users.position_id  
where ord.order_date between date'2020-01-01' and date'2020-06-30'  
group by positions.name, users.LastName, users.FirstName;

- Сделать комментарии на каждый запрос

> Комментировать нечего, все предельно просто.

- К работе приложить структуру таблиц, для которых выполнялись соединения

> DB diagram.jpg
