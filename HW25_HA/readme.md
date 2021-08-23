### Развернуть HA кластер

#### Цель:
- развернуть высокодоступный кластер PostgeSQL собственными силами
- развернуть высокодоступный сервис на базе PostgeSQL на базе одного из 3-ки ведущих облачных провайдеров - AWS, GCP и Azure


#### Выбрать один из вариантов и развернуть кластер. Описать что и как делали и с какими проблемами столкнулись

После долгих попыток установки оказалось, что Cluster Control не устанавливается на Ubuntu 20, т.к. при установке он хочет скачать пакет PHP5, а они не доступны.
Поэтому VM развернула на Centos7.

wget -O install-cc https://severalnines.com/scripts/install-cc?juvlMob2P_RnAdHbAoSl-mJfAkcI8IcP3-JdcRbiPrQ,

chmod +x install-cc

S9S_CMON_PASSWORD=e8zwU9 S9S_ROOT_PASSWORD=dBvYlJ
sudo ./install-cc

Open your web browser to http://35.238.79.121/clustercontrol and create the default Admin user by entering a valid email address and password.

В GCP создала правило для моего внешнего IP, что бы можно было подключиться с моей машины в Web gui.

Создала пользователя admin230821

Далее:
 ssh-keygen -t rsa 
 
ssh-copy-id -i ~/.ssh/id_rsa 10.128.0.28
 
 И тут облом. Нет прав на этот файл. делаю под пользователем root. Упорно гуглила, включила аутентификацию по паролю, задала пароль руту. Бесполезно!
 
 Мое терпение кончилось, я потратила несколько дней на это. И времени у меня больше нет.

#### Вариант 1 • How to Deploy PostgreSQL for High Availability

#### Вариант 2 • Introducing pg_auto_failover: Open source extension for automated failover and high-availability in PostgreSQL

