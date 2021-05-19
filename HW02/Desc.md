## Работа с уровнями изоляции транзакции в PostgreSQL

##### создать новый проект в Google Cloud Platform, например postgres2021-, где yyyymmdd год, месяц и день вашего рождения (имя проекта должно быть уникально на уровне GCP)
дать возможность доступа к этому проекту пользователю ifti@yandex.ru с ролью Project Editor

    Название проекта: Postgres2021-19831215. 

> далее создать инстанс виртуальной машины Compute Engine с дефолтными параметрами
добавить свой ssh ключ в GCE metadata
зайти удаленным ssh (первая сессия), не забывайте про ssh-add
поставить PostgreSQL
зайти вторым ssh (вторая сессия)
запустить везде psql из под пользователя postgres
выключить auto commit
сделать в первой сессии новую таблицу и наполнить ее данными create table persons(id serial, first_name text, second_name text); insert into persons(first_name, second_name) values('ivan', 'ivanov'); insert into persons(first_name, second_name) values('petr', 'petrov'); commit;
посмотреть текущий уровень изоляции: show transaction isolation level
начать новую транзакцию в обоих сессиях с дефолтным (не меняя) уровнем изоляции
в первой сессии добавить новую запись insert into persons(first_name, second_name) values('sergey', 'sergeev');
сделать select * from persons во второй сессии

#####видите ли вы новую запись и если да то почему?

    Не вижу, т.к. транзакция в первой сессии не закомичена, а в PostgreSQL нет аномалии dirtyRead

>завершить первую транзакцию - commit;
>сделать select * from persons во второй сессии

##### видите ли вы новую запись и если да то почему?

    Вижу, потому что теперь транзакция закомичена

>завершите транзакцию во второй сессии
>начать новые но уже repeatable read транзации - set transaction isolation level repeatable read;
>в первой сессии добавить новую запись insert into persons(first_name, second_name) values('sveta', 'svetova');
>сделать select * from persons во второй сессии

- видите ли вы новую запись и если да то почему?

##### Не вижу, т.к. транзакция в первой сессии не закомичена. 

>завершить первую транзакцию - commit;
сделать select * from persons во второй сессии

- видите ли вы новую запись и если да то почему?

##### Не вижу, т.к. транзакция во второй сессии не закомичена, а уровень изоляции repeatable read исключает аномалию не повторяющегося чтения.
    Соответственно второй сеанс видит только те данные, которые были зафиксированы до начала запроса.

завершить вторую транзакцию
сделать select * from persons во второй сессии

видите ли вы новую запись и если да то почему?

- Вижу, т.к. в первом сеансе транзакци была уже окончена к этому времени и выборка во втором сеансе эти данные увидела.