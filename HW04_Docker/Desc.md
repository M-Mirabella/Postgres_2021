## Установка и настройка PostgteSQL в контейнере Docker

##### сделать в GCE инстанс с Ubuntu 20.04 

- gcloud beta compute --project=celtic-house-266612 instances create docker --zone=us-central1-a --machine-type=e2-medium --subnet=default --network-tier=PREMIUM --maintenance-policy=MIGRATE --service-account=933982307116-compute@developer.gserviceaccount.com --scopes=https://www.googleapis.com/auth/devstorage.read_only,https://www.googleapis.com/auth/logging.write,https://www.googleapis.com/auth/monitoring.write,https://www.googleapis.com/auth/servicecontrol,https://www.googleapis.com/auth/service.management.readonly,https://www.googleapis.com/auth/trace.append --image=ubuntu-2010-groovy-v20210211a --image-project=ubuntu-os-cloud --boot-disk-size=10GB --boot-disk-type=pd-ssd --boot-disk-device-name=postgres13 --no-shielded-secure-boot --shielded-vtpm --shielded-integrity-monitoring --reservation-affinity=any
 
#### поставить на нем Docker Engine 

- Читала статью: https://www.digitalocean.com/community/tutorials/how-to-install-and-use-docker-on-ubuntu-20-04-ru
Там все подробнейше описано. Все получилось.

#### сделать каталог /var/lib/postgres 

- mkdir /var/lib/postgres

#### развернуть контейнер с PostgreSQL 13 смонтировав в него /var/lib/postgres 

- sudo docker network create pg-net
- sudo docker run --name pg-docker --network pg-net -e POSTGRES_PASSWORD=postgres -d -p 5432:5432 -v /var/lib/postgres:/var/lib/postgresql/data postgres:13

#### развернуть контейнер с клиентом postgres 

- sudo docker run -it --network pg-net --name pg-client postgres:13 psql -h pg-docker -U postgres

#### gроверяем, что подключились через отдельный контейнер:

- sudo docker ps -a

>CONTAINER ID   IMAGE         COMMAND                  CREATED          STATUS                              PORTS                                       NAMES  
8744655dca0c   postgres:13   "docker-entrypoint.s…"   26 seconds ago   Up 26 sec         onds              5432/tcp                                    pg-client  
1beb783e9390   postgres:13   "docker-entrypoint.s…"   17 hours ago     Up 5 minu         tes               0.0.0.0:5432->5432/tcp, :::5432->5432/tcp   pg-docker  

#### подключится из контейнера с клиентом к контейнеру с сервером и сделать таблицу с парой строк 

>create table persons(id serial, first_name text, second_name text);  
insert into persons(first_name, second_name) values('ivan', 'ivanov');  
insert into persons(first_name, second_name) values('petr', 'petrov');  
commit;  

#### подключится к контейнеру с сервером с ноутбука/компьютера извне инстансов GCP 

- на компьютере подняла виртуалку с ubuntu. Установила туда docker.  
На VM в GCP открыла порт 5432 (спасибо Алексею Ковтуновичу).   
На компьютере ping на внеший ip идет. По telnet доступ к порту 5432 есть.  
Дальше я не понимаю что делать. Я искала в интернете, несколько дней пыталась, но у меня так и
не получилось подключиться.

#### удалить контейнер с сервером 

 - sudo docker stop pg-docker
 - sudo docker rm pg-docker

#### создать его заново 

- Команда по созданию та же

>CONTAINER ID   IMAGE         COMMAND                  CREATED          STATUS          PORTS                                       NAMES  
> b90b4ae47230   postgres:13   "docker-entrypoint.s…"   20 seconds ago   Up 19 seconds   0.0.0.0:5432->5432/tcp, :::5432->5432/tcp   pg-docker  

-   sudo docker exec -it pg-docker psql -h pg-docker -U postgres

>postgres=# select * from persons;  
 id | first_name | second_name  
----+------------+-------------  
  1 | ivan       | ivanov  
  2 | petr       | petrov  
(2 rows)  

#### подключится снова из контейнера с клиентом к контейнеру с сервером. Проверить, что данные остались на месте 

- Проверила, все на месте

#### оставляйте в ЛК ДЗ комментарии что и как вы делали и как боролись с проблемами.

-  Большую часть времени потратила на попытку подключиться с локального хоста к контейнеру в GCP.  
В целом идея докера стала ясна и понятна. До этого читала, никак понять не могла зачем он нужен вобще.
