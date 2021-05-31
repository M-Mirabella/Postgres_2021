### Установка и настройка PostgreSQL

#### Цель:
- создавать дополнительный диск для уже существующей виртуальной машины, размечать его и делать на нем файловую систему
- переносить содержимое базы данных PostgreSQL на дополнительный диск
- переносить содержимое БД PostgreSQL между виртуальными машинами

> создайте виртуальную машину c Ubuntu 20.04 LTS (bionic) в GCE типа e2-medium в default VPC в любом регионе и зоне, например us-central1-a
поставьте на нее PostgreSQL через sudo apt
проверьте что кластер запущен через sudo -u postgres pg_lsclusters
зайдите из под пользователя postgres в psql и сделайте произвольную таблицу с произвольным содержимым postgres=# create table test(c1 text); postgres=# insert into test values('1'); \q
остановите postgres например через sudo -u postgres pg_ctlcluster 13 main stop
создайте новый standard persistent диск GKE через Compute Engine -> Disks в том же регионе и зоне что GCE инстанс размером например 10GB
добавьте свеже-созданный диск к виртуальной машине - надо зайти в режим ее редактирования и дальше выбрать пункт attach existing disk
проинициализируйте диск согласно инструкции и подмонтировать файловую систему, только не забывайте менять имя диска на актуальное, в вашем случае это скорее всего будет /dev/sdb - https://www.digitalocean.com/community/tutorials/how-to-partition-and-format-storage-devices-in-linux
сделайте пользователя postgres владельцем /mnt/data - chown -R postgres:postgres /mnt/data/
перенесите содержимое /var/lib/postgres/13 в /mnt/data - mv /var/lib/postgresql/13 /mnt/data

##### Ссылка на проект: https://console.cloud.google.com/compute/instances?project=postgres2021-19831215&hl=ru

> попытайтесь запустить кластер - sudo -u postgres pg_ctlcluster 13 main start
напишите получилось или нет и почему

##### Не получилось, т.к. он пытается запуститься из несуществующей папки.В данный каталог /var/lib/postgres/13 Postgres устанавливается по умолчанию, там же хранятся БД.

> задание: найти конфигурационный параметр в файлах раположенных в /etc/postgresql/10/main который надо поменять и поменяйте его
напишите что и почему поменяли

##### В файле postgresql.conf поменяла параметр data_directory = '/mnt/data/13/main' 

> попытайтесь запустить кластер - sudo -u postgres pg_ctlcluster 13 main start
напишите получилось или нет и почему

##### Все получилось, т.к. теперь при запуске ссылается на нужную папку
![image](https://user-images.githubusercontent.com/61549145/120236150-4aa86480-c264-11eb-86b4-fd42e75447d9.png)

> зайдите через через psql и проверьте содержимое ранее созданной таблицы

##### Все данные на месте.
