## Домашнее задание 31.postgresql_cluster
Кластер PostgreSQL на Patroni
Развернуть кластер PostgreSQL из трех нод. Создать тестовую базу - проверить статус репликации
Сделать switchover/failover
Поменять конфигурацию PostgreSQL + с параметром требующим перезагрузки

## Описание
Создано на основе материалов курса из  https://gitlab.com/otus_linux/patroni/

## Развертываем инфраструктуру

```bash
$ vagrant up
$ ansible-playbook site.yml -i hosts
```

Consul UI: `192.168.11.100:8500`

Проверка состояния кластера из любого хоста pg{1,2,3}: `patronictl -c /etc/patroni/patroni.yml list`

## Проверки

```bash
$ vagrant ssh pg1
vagran@pg1~$ sudo su -
```
Пробуем подключиться к первому серверу, (пароль gfhjkm) и создать тестовую базу данных.

```bash
root@pg1:~# psql -h 192.168.11.121 --username=postgres
postgres=# create database otus;
ERROR:  cannot execute CREATE DATABASE in a read-only transaction
```
Неудача. Почему? Проверим статус кластера, оказывается мы подключились к слейву

```bash
root@pg1:~# patronictl -c /etc/patroni/patroni.yml list
+---------+--------+----------------+--------+---------+----+-----------+
| Cluster | Member |      Host      |  Role  |  State  | TL | Lag in MB |
+---------+--------+----------------+--------+---------+----+-----------+
|   otus  |  pg1   | 192.168.11.121 |        | running |  2 |       0.0 |
|   otus  |  pg2   | 192.168.11.122 | Leader | running |  2 |           |
|   otus  |  pg3   | 192.168.11.123 |        | running |  2 |       0.0 |
+---------+--------+----------------+--------+---------+----+-----------+
```

Мастером является второй узел, поэтому продолжим, подключвшись на этот раз к мастеру.

```bash
root@pg2:~#  psql -h 192.168.11.122 --username=postgres
Password for user postgres:
psql (11.6 (Ubuntu 11.6-1.pgdg18.04+1))
Type "help" for help.

postgres=# create database otus;
CREATE DATABASE
```

Также установим переменную окружения PATRONI_CONSUL_HOST, это даст удобство в дальнейшем.

```bash
root@pg2:~# export PATRONI_CONSUL_HOST='192.168.11.100:8500'

root@pg2:~# patronictl list otus
+---------+--------+----------------+--------+---------+----+-----------+
| Cluster | Member |      Host      |  Role  |  State  | TL | Lag in MB |
+---------+--------+----------------+--------+---------+----+-----------+
|   otus  |  pg1   | 192.168.11.121 |        | running |  2 |       0.0 |
|   otus  |  pg2   | 192.168.11.122 | Leader | running |  2 |           |
|   otus  |  pg3   | 192.168.11.123 |        | running |  2 |       0.0 |
+---------+--------+----------------+--------+---------+----+-----------+
```

Имимтируем сбой мастера. для этого достаточно остановить на pg2 сервис patroni

```bash
root@pg2:~# systemctl stop patroni
root@pg2:~# patronictl list otus
+---------+--------+----------------+--------+---------+----+-----------+
| Cluster | Member |      Host      |  Role  |  State  | TL | Lag in MB |
+---------+--------+----------------+--------+---------+----+-----------+
|   otus  |  pg1   | 192.168.11.121 | Leader | running |  3 |           |
|   otus  |  pg2   | 192.168.11.122 |        | stopped |    |   unknown |
|   otus  |  pg3   | 192.168.11.123 |        | running |    |   unknown |
+---------+--------+----------------+--------+---------+----+-----------+
```

failover корректно отработал, мастером стал первый узел

```bash
root@pg2:~# systemctl start patroni
root@pg2:~# patronictl list otus
+---------+--------+----------------+--------+---------+----+-----------+
| Cluster | Member |      Host      |  Role  |  State  | TL | Lag in MB |
+---------+--------+----------------+--------+---------+----+-----------+
|   otus  |  pg1   | 192.168.11.121 | Leader | running |  3 |           |
|   otus  |  pg2   | 192.168.11.122 |        | running |  2 |       0.0 |
|   otus  |  pg3   | 192.168.11.123 |        | running |  3 |       0.0 |
+---------+--------+----------------+--------+---------+----+-----------+
```

Теперь пробуем принудительно мигрировать БД на другой узел, например с pg1 на pg3:

```bash
root@pg2:~# patronictl -c /etc/patroni/patroni.yml switchover
Master [pg1]:
Candidate ['pg2', 'pg3'] []: pg3
When should the switchover take place (e.g. 2020-01-09T22:04 )  [now]:
Current cluster topology
+---------+--------+----------------+--------+---------+----+-----------+
| Cluster | Member |      Host      |  Role  |  State  | TL | Lag in MB |
+---------+--------+----------------+--------+---------+----+-----------+
|   otus  |  pg1   | 192.168.11.121 | Leader | running |  3 |           |
|   otus  |  pg2   | 192.168.11.122 |        | running |  3 |       0.0 |
|   otus  |  pg3   | 192.168.11.123 |        | running |  3 |       0.0 |
+---------+--------+----------------+--------+---------+----+-----------+
Are you sure you want to switchover cluster otus, demoting current master pg1? [y/N]: y
2020-01-09 21:04:46.65476 Successfully switched over to "pg3"
+---------+--------+----------------+--------+---------+----+-----------+
| Cluster | Member |      Host      |  Role  |  State  | TL | Lag in MB |
+---------+--------+----------------+--------+---------+----+-----------+
|   otus  |  pg1   | 192.168.11.121 |        | stopped |    |   unknown |
|   otus  |  pg2   | 192.168.11.122 |        | running |  3 |       0.0 |
|   otus  |  pg3   | 192.168.11.123 | Leader | running |  3 |           |
+---------+--------+----------------+--------+---------+----+-----------+

root@pg2:~# patronictl list otus
+---------+--------+----------------+--------+---------+----+-----------+
| Cluster | Member |      Host      |  Role  |  State  | TL | Lag in MB |
+---------+--------+----------------+--------+---------+----+-----------+
|   otus  |  pg1   | 192.168.11.121 |        | stopped |    |   unknown |
|   otus  |  pg2   | 192.168.11.122 |        | running |    |   unknown |
|   otus  |  pg3   | 192.168.11.123 | Leader | running |  4 |           |
+---------+--------+----------------+--------+---------+----+-----------+
```

Ждем еще несколько секунд, и кластер приходит в норму

```bash
root@pg2:~# patronictl list otus
+---------+--------+----------------+--------+---------+----+-----------+
| Cluster | Member |      Host      |  Role  |  State  | TL | Lag in MB |
+---------+--------+----------------+--------+---------+----+-----------+
|   otus  |  pg1   | 192.168.11.121 |        | running |  4 |       0.0 |
|   otus  |  pg2   | 192.168.11.122 |        | running |  4 |       0.0 |
|   otus  |  pg3   | 192.168.11.123 | Leader | running |  4 |           |
+---------+--------+----------------+--------+---------+----+-----------+
root@pg2:~#
```

Попробуем внести изменение в конфигурацию, которое требует рестарта кластера, например поменяем число max_connections

```bash
root@pg2:~# patronictl -c /etc/patroni/patroni.yml edit-config
---
+++
@@ -7,7 +7,7 @@
       archive-push -B /var/backup --instance dbdc2 --wal-file-path=%p --wal-file-name=%f
       --remote-host=10.23.1.185
     archive_mode: 'on'
-    max_connections: 100
+    max_connections: 200
     max_parallel_workers: 8
     max_wal_senders: 5
     max_wal_size: 2GB

Apply these changes? [y/N]: y
Configuration changed
root@pg2:~# patronictl -c /etc/patroni/patroni.yml list otus
+---------+--------+----------------+--------+---------+----+-----------+
| Cluster | Member |      Host      |  Role  |  State  | TL | Lag in MB |
+---------+--------+----------------+--------+---------+----+-----------+
|   otus  |  pg1   | 192.168.11.121 |        | running |  4 |       0.0 |
|   otus  |  pg2   | 192.168.11.122 |        | running |  4 |       0.0 |
|   otus  |  pg3   | 192.168.11.123 | Leader | running |  4 |           |
+---------+--------+----------------+--------+---------+----+-----------+
root@pg2:~# patronictl list otus
+---------+--------+----------------+--------+---------+----+-----------+-----------------+
| Cluster | Member |      Host      |  Role  |  State  | TL | Lag in MB | Pending restart |
+---------+--------+----------------+--------+---------+----+-----------+-----------------+
|   otus  |  pg1   | 192.168.11.121 |        | running |  4 |       0.0 |        *        |
|   otus  |  pg2   | 192.168.11.122 |        | running |  4 |       0.0 |        *        |
|   otus  |  pg3   | 192.168.11.123 | Leader | running |  4 |           |        *        |
+---------+--------+----------------+--------+---------+----+-----------+-----------------+
```
В последней колонке наблюдаем, что кластер требьует рестарта. Выполняем рестарт

```bash
root@pg2:~# patronictl restart otus
+---------+--------+----------------+--------+---------+----+-----------+-----------------+
| Cluster | Member |      Host      |  Role  |  State  | TL | Lag in MB | Pending restart |
+---------+--------+----------------+--------+---------+----+-----------+-----------------+
|   otus  |  pg1   | 192.168.11.121 |        | running |  4 |       0.0 |        *        |
|   otus  |  pg2   | 192.168.11.122 |        | running |  4 |       0.0 |        *        |
|   otus  |  pg3   | 192.168.11.123 | Leader | running |  4 |           |        *        |
+---------+--------+----------------+--------+---------+----+-----------+-----------------+
When should the restart take place (e.g. 2020-01-09T22:08)  [now]: now
Are you sure you want to restart members pg2, pg3, pg1? [y/N]: y
Restart if the PostgreSQL version is less than provided (e.g. 9.5.2)  []:
Success: restart on member pg2
Success: restart on member pg3
Success: restart on member pg1

root@pg2:~# patronictl list otus
+---------+--------+----------------+--------+---------+----+-----------+
| Cluster | Member |      Host      |  Role  |  State  | TL | Lag in MB |
+---------+--------+----------------+--------+---------+----+-----------+
|   otus  |  pg1   | 192.168.11.121 |        | running |  4 |       0.0 |
|   otus  |  pg2   | 192.168.11.122 |        | running |  4 |       0.0 |
|   otus  |  pg3   | 192.168.11.123 | Leader | running |  4 |           |
+---------+--------+----------------+--------+---------+----+-----------+
root@pg2:~#
```
