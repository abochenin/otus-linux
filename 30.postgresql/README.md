## Домашнее задание 30.postgres
PostgreSQL
- Настроить hot_standby репликацию с использованием слотов
- Настроить правильное резервное копирование

Для сдачи работы присылаем ссылку на репозиторий, в котором должны обязательно быть Vagranfile 
и плейбук Ansible, конфигурационные файлы postgresql.conf, pg_hba.conf и recovery.conf, 
а так же конфиг barman, либо скрипт резервного копирования. Команда "vagrant up" должна 
поднимать машины с настроенной репликацией и резервным копированием. Рекомендуется в 
README.md файл вложить результаты (текст или скриншоты) проверки работы репликации и 
резервного копирования. 

## Развертываем инфраструктуру

```bash
$ vagrant up
```
# Проблема с barman
В процессе работы столкнулся с нестабильной доступностью сайта https://dl.2ndquadrant.com 
(репозитории для barman - системы резервного копирования для постгрес)

```
Проверка https://dl.2ndquadrant.com/default/release/get/11/rpm выполнена 17 декабря 2019 года в 20:54:50 по московскому времени с помощью http://ping-admin.ru/free_test/.

Россия, Москва, восток 3	Невозможно соединиться с указанным адресом.
Россия, Москва, запад 1	188.40.80.163
Россия, Москва, запад 2	Операция прервана, т.к. сервис не ответил в течение 8 секунд.
Россия, Москва, запад 3	188.40.80.163
Россия, Москва, запад 4	188.40.80.163
Россия, Москва, север	188.40.80.163
Россия, Москва, северо-восток 1	188.40.80.163
Россия, Москва, северо-восток 2	Невозможно соединиться с указанным адресом.
Россия, Москва, северо-восток 3	188.40.80.163
Россия, Москва, северо-восток 4	Невозможно соединиться с указанным адресом.
Россия, Москва, северо-запад	Невозможно соединиться с указанным адресом.
Россия, Москва, центр 1	188.40.80.163
Россия, Москва, центр 2	188.40.80.163
Россия, Москва, центр 3	Операция прервана, т.к. сервис не ответил в течение 8 секунд.
Россия, Москва, центр 4	188.40.80.163
Россия, Москва, юг 1	188.40.80.163
Россия, Москва, юг 2	188.40.80.163
Россия, Москва, юг 3	188.40.80.163
Россия, Москва, юго-восток	188.40.80.163
Россия, Москва, юго-запад 1	188.40.80.163
Россия, Москва, юго-запад 2	188.40.80.163
Россия, Апатиты	Невозможно соединиться с указанным адресом.
Россия, Владивосток	Операция прервана, т.к. сервис не ответил в течение 8 секунд.
Россия, Владимир	188.40.80.163
Россия, Воронеж	188.40.80.163
Россия, Дубровка	188.40.80.163
Россия, Екатеринбург, запад	188.40.80.163
Россия, Екатеринбург, север	188.40.80.163
Россия, Екатеринбург, юг	188.40.80.163
Россия, Казань	188.40.80.163
Россия, Калининград	Проблема с соединением через SSL. Скорее всего на сервере отключены ряд шифров для SSL, из-за чего некоторые клиенты не смогут подключиться. Обращение производилось к IP: 188.40.80.163.
Россия, Кемерово	Проблема с соединением через SSL. Скорее всего на сервере отключены ряд шифров для SSL, из-за чего некоторые клиенты не смогут подключиться. Обращение производилось к IP: 188.40.80.163.
Россия, Королёв	188.40.80.163
Россия, Краснодар	Проблема с соединением через SSL. Скорее всего на сервере отключены ряд шифров для SSL, из-за чего некоторые клиенты не смогут подключиться. Обращение производилось к IP: 188.40.80.163.
Россия, Красноярск	188.40.80.163
Россия, Нижний Новгород	Проблема с соединением через SSL. Скорее всего на сервере отключены ряд шифров для SSL, из-за чего некоторые клиенты не смогут подключиться. Обращение производилось к IP: 188.40.80.163.
Россия, Новокузнецк	Проблема с соединением через SSL. Скорее всего на сервере отключены ряд шифров для SSL, из-за чего некоторые клиенты не смогут подключиться. Обращение производилось к IP: 188.40.80.163.
Россия, Новосибирск, север	Операция прервана, т.к. сервис не ответил в течение 8 секунд.
Россия, Новосибирск, юг	188.40.80.163

и т.д., в том числе и некоторые зарубежные площадки
```

Как видно, проблема масштабная. Поэтому в скриптах ансибла для этого репо применяется свободный прокси 
сервер, например, Германия, нагуглил тут https://hidemy.name/ru/proxy-list/?country=DE&ports=3128#list
Опасность свободных прокси (модификация транзитного трафика) осознаю, и в продакшене никому не рекомендую...
В виртуалках - на свое усмотрение.

# postgres

Активность репликации можно проверить следующим образом:
На master сервере выполнить команду
```bash
[root@master ~]# ps -ef|grep wal
postgres 29755 29749  0 18:35 ?        00:00:00 postgres: walwriter
postgres 30053 29749  0 18:38 ?        00:00:00 postgres: walsender streaming_user 192.168.11.102(58226) streaming 0/90001A8
postgres 30309 29749  0 18:57 ?        00:00:00 postgres: walsender barman_streaming_user 192.168.11.103(39818) streaming 0/90001A8
```

Аналогично на slave

```bash
[root@slave ~]# ps -ef|grep wal
postgres  6130  6123  0 18:38 ?        00:00:03 postgres: walreceiver   streaming 0/90001A8
```

## backup

Проверим статус потокового клиента, прикрепленного к master
```bash
[root@backup ~]# barman replication-status master
Status of streaming clients for server 'master':
  Current LSN on master: 0/90000C8
  Number of streaming clients: 2

  1. Async standby
     Application name: walreceiver
     Sync stage      : 5/5 Hot standby (max)
     Communication   : TCP/IP
     IP Address      : 192.168.11.102 / Port: 58226 / Host: -
     User name       : streaming_user
     Current state   : streaming (async)
     Replication slot: pg_slot_1
     WAL sender PID  : 30053
     Started at      : 2019-12-17 18:38:24.146935+00:00
     Sent LSN   : 0/90000C8 (diff: 0 B)
     Write LSN  : 0/90000C8 (diff: 0 B)
     Flush LSN  : 0/90000C8 (diff: 0 B)
     Replay LSN : 0/90000C8 (diff: 0 B)

  2. Async WAL streamer
     Application name: barman_receive_wal
     Sync stage      : 3/3 Remote write
     Communication   : TCP/IP
     IP Address      : 192.168.11.103 / Port: 39818 / Host: -
     User name       : barman_streaming_user
     Current state   : streaming (async)
     Replication slot: barman
     WAL sender PID  : 30309
     Started at      : 2019-12-17 18:57:03.496388+00:00
     Sent LSN   : 0/90000C8 (diff: 0 B)
     Write LSN  : 0/90000C8 (diff: 0 B)
     Flush LSN  : 0/9000000 (diff: -200 B)
[root@backup ~]#
```

Выполняем pg_switch_wal() на master, и ждем, пока один файл xlog будет заархивирован
```bash
[root@backup ~]# barman switch-wal --archive master
The WAL file 000000010000000000000006 has been closed on server 'master'
Waiting for the WAL file 000000010000000000000006 from server 'master' (max: 30 seconds)
Processing xlog segments from streaming for master
        000000010000000000000005
Processing xlog segments from streaming for master
        000000010000000000000006
```

Выполянем бакап БД

```bash
[root@backup ~]# barman backup master
Starting backup using postgres method for server master in /var/lib/barman/master/base/20191217T190045
Backup start at LSN: 0/7000060 (000000010000000000000007, 00000060)
Starting backup copy via pg_basebackup for 20191217T190045
Copy done (time: 3 seconds)
Finalising the backup.
Backup size: 22.7 MiB
Backup end at LSN: 0/9000000 (000000010000000000000008, 00000000)
Backup completed (start time: 2019-12-17 19:00:45.086940, elapsed time: 4 seconds)
Processing xlog segments from streaming for master
        000000010000000000000007
Processing xlog segments from file archival for master
        000000010000000000000006
        000000010000000000000007
        000000010000000000000008
        000000010000000000000008.00000028.backup
```

Проверяем результат

```bash
[root@backup ~]# barman list-backup master
master 20191217T190045 - Tue Dec 17 19:00:49 2019 - Size: 22.7 MiB - WAL Size: 0 B
master 20191217T185948 - Tue Dec 17 18:59:53 2019 - Size: 22.7 MiB - WAL Size: 48.2 KiB - WAITING_FOR_WALS

[root@backup ~]# barman check master
Server master:
        PostgreSQL: OK
        is_superuser: OK
        PostgreSQL streaming: OK
        wal_level: OK
        replication slot: OK
        directories: OK
        retention policy settings: OK
        backup maximum age: OK (no last_backup_maximum_age provided)
        compression settings: OK
        failed backups: OK (there are 0 failed backups)
        minimum redundancy requirements: OK (have 2 backups, expected at least 0)
        pg_basebackup: OK
        pg_basebackup compatible: OK
        pg_basebackup supports tablespaces mapping: OK
        systemid coherence: OK
        pg_receivexlog: OK
        pg_receivexlog compatible: OK
        receive-wal running: OK
        archive_mode: OK
        archive_command: OK
        continuous archiving: OK
        archiver errors: OK
[root@backup ~]#
```
