## Домашнее задание 29.mysql_cluster
mysql cluster
развернуть InnoDB кластер в docker
* в docker swarm

в качестве ДЗ принимает репозиторий с docker-compose
который по кнопке разворачивает кластер и выдает порт наружу

## Материалы

Работа выполнялась по статье "Docker Compose Setup for InnoDB Cluster"
https://mysqlrelease.com/2018/03/docker-compose-setup-for-innodb-cluster/

InnoDB cluster
https://github.com/dmitry-lyutenko/innodb-cluster

## Развертываем инфраструктуру

```bash
$ cd innodb-cluster
$ docker-compose up
```

В результате будет настроен кластер InnoDB с помощью официальных контейнеров DoSQL MySQL.
и в итоге мы получим следующие компоненты:

- три контейнера mysql-сервера
- один временный контейнер оболочки mysql (для настройки кластера InnoDB)
- один контейнер mysql-router (для доступа к кластеру)

```bash
$ docker ps
CONTAINER ID        IMAGE                       COMMAND                  CREATED             STATUS                 PORTS                                                    NAMES
d290418c258f        neumayer/dbwebapp           "/dbwebapp"              2 hours ago         Up 2 hours             0.0.0.0:8080->8080/tcp                                   innodb-cluster_dbwebapp_1
d39e6d866ef4        mysql/mysql-router:8.0      "/run.sh mysqlrouter"    2 hours ago         Up 2 hours (healthy)   6447/tcp, 64460/tcp, 0.0.0.0:6446->6446/tcp, 64470/tcp   innodb-cluster_mysql-router_1
96b8b87e43e4        mysql/mysql-server:8.0.12   "/entrypoint.sh mysq…"   2 hours ago         Up 2 hours (healthy)   33060/tcp, 0.0.0.0:3303->3306/tcp                        innodb-cluster_mysql-server-3_1
c90e45f49b4b        mysql/mysql-server:8.0.12   "/entrypoint.sh mysq…"   2 hours ago         Up 2 hours (healthy)   33060/tcp, 0.0.0.0:3301->3306/tcp                        innodb-cluster_mysql-server-1_1
ca5d52cfcef1        mysql/mysql-server:8.0.12   "/entrypoint.sh mysq…"   2 hours ago         Up 2 hours (healthy)   33060/tcp, 0.0.0.0:3302->3306/tcp                        innodb-cluster_mysql-server-2_1
```

Проверяем состояние кластера (пароль mysql)
Обращаем внимание на статус
```bash
"status": "OK",.
"statusText": "Cluster is ONLINE and can tolerate up to ONE failure.",
```

```bash
$ mysqlsh   --uri root@127.0.0.1:6446
MySQL Shell 8.0.18

Copyright (c) 2016, 2019, Oracle and/or its affiliates. All rights reserved.
Oracle is a registered trademark of Oracle Corporation and/or its affiliates.
Other names may be trademarks of their respective owners.

Type '\help' or '\?' for help; '\quit' to exit.
Creating a session to 'root@127.0.0.1:6446'
Fetching schema names for autocompletion... Press ^C to stop.
Your MySQL connection id is 14760
Server version: 8.0.12 MySQL Community Server - GPL
No default schema selected; type \use <schema> to set one.
 MySQL  127.0.0.1:6446 ssl  JS > dba.getCluster().status()
{
    "clusterName": "devCluster", 
    "defaultReplicaSet": {
        "name": "default", 
        "primary": "mysql-server-1:3306", 
        "ssl": "REQUIRED", 
        "status": "OK", 
        "statusText": "Cluster is ONLINE and can tolerate up to ONE failure.", 
        "topology": {
            "mysql-server-1:3306": {
                "address": "mysql-server-1:3306", 
                "mode": "n/a", 
                "readReplicas": {}, 
                "role": "HA", 
                "shellConnectError": "MySQL Error 2005 (HY000): Unknown MySQL server host 'mysql-server-1' (22)", 
                "status": "ONLINE", 
                "version": "8.0.12"
            }, 
            "mysql-server-2:3306": {
                "address": "mysql-server-2:3306", 
                "mode": "n/a", 
                "readReplicas": {}, 
                "role": "HA", 
                "shellConnectError": "MySQL Error 2005 (HY000): Unknown MySQL server host 'mysql-server-2' (22)", 
                "status": "ONLINE", 
                "version": "8.0.12"
            }, 
            "mysql-server-3:3306": {
                "address": "mysql-server-3:3306", 
                "mode": "n/a", 
                "readReplicas": {}, 
                "role": "HA", 
                "shellConnectError": "MySQL Error 2005 (HY000): Unknown MySQL server host 'mysql-server-3' (22)", 
                "status": "ONLINE", 
                "version": "8.0.12"
            }
        }, 
        "topologyMode": "Single-Primary"
    }, 
    "groupInformationSourceMember": "c90e45f49b4b:3306"
}
```