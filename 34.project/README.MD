### Краткое описание

Построение отказоустойчивого веб. Проект состоит из нескольких виртуальных машин, в соответствии с ролями.
- Кластер GALERA mariadb для предоставления приложениям доступа к БД.
db1
db2
db3

- Фронтенды nginx, объединенные через keepalive с настроенным общим адресом 192.168.34.100
fe1
fe2

- Сервер для хранения резервных копий, и логов rsyslog со всех вышеперечисленных машин
backup

### Запуск стенда

```bash
vagrant destroy -f; vagrant up; ansible-playbook -i hosts provision/playbook.yml
```
Развертывание занимает примерно полчаса.

```bash
RUNNING HANDLER [roles/logclient : restart rsyslog] ****************************************************************************************************************************************************************************************
Wednesday 05 February 2020  14:33:16 +0400 (0:00:01.855)       0:25:29.319 **** 
changed: [fe1]
changed: [fe2]

PLAY RECAP *********************************************************************************************************************************************************************************************************************************
backup                     : ok=19   changed=18   unreachable=0    failed=0   
db1                        : ok=41   changed=39   unreachable=0    failed=0   
db2                        : ok=40   changed=37   unreachable=0    failed=0   
db3                        : ok=42   changed=39   unreachable=0    failed=0   
fe1                        : ok=58   changed=56   unreachable=0    failed=0   
fe2                        : ok=57   changed=55   unreachable=0    failed=0   

Wednesday 05 February 2020  14:33:16 +0400 (0:00:00.730)       0:25:30.049 **** 
=============================================================================== 
roles/galera ---------------------------------------------------------- 438.83s
roles/common ---------------------------------------------------------- 415.97s
roles/wordpress ------------------------------------------------------- 163.31s
roles/logclient ------------------------------------------------------- 122.69s
roles/glusterfs-server ------------------------------------------------ 106.88s
roles/php -------------------------------------------------------------- 94.43s
roles/nginx ------------------------------------------------------------ 62.63s
roles/mysqlrouter ------------------------------------------------------ 40.43s
roles/glusterfs-client ------------------------------------------------- 35.11s
roles/keepalived ------------------------------------------------------- 24.16s
roles/backup ----------------------------------------------------------- 13.82s
setup ------------------------------------------------------------------- 6.73s
roles/logserver --------------------------------------------------------- 4.96s
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ 
total ---------------------------------------------------------------- 1529.94s
Playbook run took 0 days, 0 hours, 25 minutes, 30 seconds
```


### Схема

![project](https://github.com/abochenin/otus-linux/blob/master/34.project/images/project.png)

## База данных

Для базы данных использован galera cluster, развернутый на трех узлах в master-master конфигурации
Для проверки, после развертывания можно посмотреть статус кластера и репликации:

```bash
[root@db1 ~]# mysql -p
Enter password: 
Welcome to the MariaDB monitor.  Commands end with ; or \g.
Your MariaDB connection id is 8
Server version: 10.5.0-MariaDB MariaDB Server

Copyright (c) 2000, 2018, Oracle, MariaDB Corporation Ab and others.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

MariaDB [(none)]> show status like 'wsrep%';
+-------------------------------+------------------------------------------------------------------------------------------------------------------------------------------------+
| Variable_name                 | Value                                                                                                                                          |
+-------------------------------+------------------------------------------------------------------------------------------------------------------------------------------------+
| wsrep_local_state_uuid        | 59b5f253-4800-11ea-964f-4e64aa1c5740                                                                                                           |
| wsrep_protocol_version        | 10                                                                                                                                             |
| wsrep_last_committed          | 2                                                                                                                                              |
| wsrep_replicated              | 0                                                                                                                                              |
| wsrep_replicated_bytes        | 0                                                                                                                                              |
| wsrep_repl_keys               | 0                                                                                                                                              |
| wsrep_repl_keys_bytes         | 0                                                                                                                                              |
| wsrep_repl_data_bytes         | 0                                                                                                                                              |
| wsrep_repl_other_bytes        | 0                                                                                                                                              |
| wsrep_received                | 9                                                                                                                                              |
| wsrep_received_bytes          | 628                                                                                                                                            |
| wsrep_local_commits           | 0                                                                                                                                              |
| wsrep_local_cert_failures     | 0                                                                                                                                              |
| wsrep_local_replays           | 0                                                                                                                                              |
| wsrep_local_send_queue        | 0                                                                                                                                              |
| wsrep_local_send_queue_max    | 1                                                                                                                                              |
| wsrep_local_send_queue_min    | 0                                                                                                                                              |
| wsrep_local_send_queue_avg    | 0                                                                                                                                              |
| wsrep_local_recv_queue        | 0                                                                                                                                              |
| wsrep_local_recv_queue_max    | 2                                                                                                                                              |
| wsrep_local_recv_queue_min    | 0                                                                                                                                              |
| wsrep_local_recv_queue_avg    | 0.111111                                                                                                                                       |
| wsrep_local_cached_downto     | 1                                                                                                                                              |
| wsrep_flow_control_paused_ns  | 0                                                                                                                                              |
| wsrep_flow_control_paused     | 0                                                                                                                                              |
| wsrep_flow_control_sent       | 0                                                                                                                                              |
| wsrep_flow_control_recv       | 0                                                                                                                                              |
| wsrep_cert_deps_distance      | 0                                                                                                                                              |
| wsrep_apply_oooe              | 0                                                                                                                                              |
| wsrep_apply_oool              | 0                                                                                                                                              |
| wsrep_apply_window            | 0                                                                                                                                              |
| wsrep_commit_oooe             | 0                                                                                                                                              |
| wsrep_commit_oool             | 0                                                                                                                                              |
| wsrep_commit_window           | 0                                                                                                                                              |
| wsrep_local_state             | 4                                                                                                                                              |
| wsrep_local_state_comment     | Synced                                                                                                                                         |
| wsrep_cert_index_size         | 0                                                                                                                                              |
| wsrep_causal_reads            | 0                                                                                                                                              |
| wsrep_cert_interval           | 0                                                                                                                                              |
| wsrep_open_transactions       | 0                                                                                                                                              |
| wsrep_open_connections        | 0                                                                                                                                              |
| wsrep_incoming_addresses      | AUTO,AUTO,AUTO                                                                                                                                 |
| wsrep_cluster_weight          | 3                                                                                                                                              |
| wsrep_desync_count            | 0                                                                                                                                              |
| wsrep_evs_delayed             |                                                                                                                                                |
| wsrep_evs_evict_list          |                                                                                                                                                |
| wsrep_evs_repl_latency        | 0/0/0/0/0                                                                                                                                      |
| wsrep_evs_state               | OPERATIONAL                                                                                                                                    |
| wsrep_gcomm_uuid              | 59b30c87-4800-11ea-9ccd-9b62a3612ad7                                                                                                           |
| wsrep_applier_thread_count    | 1                                                                                                                                              |
| wsrep_cluster_capabilities    |                                                                                                                                                |
| wsrep_cluster_conf_id         | 18446744073709551615                                                                                                                           |
| wsrep_cluster_size            | 3                                                                                                                                              |
| wsrep_cluster_state_uuid      | 59b5f253-4800-11ea-964f-4e64aa1c5740                                                                                                           |
| wsrep_cluster_status          | Primary                                                                                                                                        |
| wsrep_connected               | ON                                                                                                                                             |
| wsrep_local_bf_aborts         | 0                                                                                                                                              |
| wsrep_local_index             | 2                                                                                                                                              |
| wsrep_provider_capabilities   | :MULTI_MASTER:CERTIFICATION:PARALLEL_APPLYING:TRX_REPLAY:ISOLATION:PAUSE:CAUSAL_READS:INCREMENTAL_WRITESET:UNORDERED:PREORDERED:STREAMING:NBO: |
| wsrep_provider_name           | Galera                                                                                                                                         |
| wsrep_provider_vendor         | Codership Oy <info@codership.com>                                                                                                              |
| wsrep_provider_version        | 26.4.3(r4535)                                                                                                                                  |
| wsrep_ready                   | ON                                                                                                                                             |
| wsrep_rollbacker_thread_count | 1                                                                                                                                              |
| wsrep_thread_count            | 2                                                                                                                                              |
+-------------------------------+------------------------------------------------------------------------------------------------------------------------------------------------+
65 rows in set (0.037 sec)
```
Останов любой ноды не влияет на общую работоспособность galera кластера. В случае, если все ноды будут выключены в одно и тоже время, MariaDB не поднимется сама.
Необходимо будет выбрать наиболее актуальную ноду, и запустить сервис с опцией --wsrep-new-cluster, чтобы остальные ноды смогли прореплицировать с нее информацию.


Пример вывода состояния кластера с остановленной нодой db1. Можно заметить. что число узлов равно 2.

```bash
[root@db3 ~]# mysql -uroot -e "SHOW GLOBAL STATUS LIKE 'wsrep_cluster%';"
+----------------------------+--------------------------------------+
| Variable_name              | Value                                |
+----------------------------+--------------------------------------+
| wsrep_cluster_weight       | 2                                    |
| wsrep_cluster_capabilities |                                      |
| wsrep_cluster_conf_id      | 18446744073709551615                 |
| wsrep_cluster_size         | 2                                    |
| wsrep_cluster_state_uuid   | 1f4b799b-496b-11ea-a940-37386e86d1cc |
| wsrep_cluster_status       | Primary                              |
```
После поднятия ноды DB1 кластер приходит в норму.


Пакетный фильтр настроен в соответствии с развернутыми сервисами (см. ниже GlusetrFS)

```bash
[root@db1 ~]# firewall-cmd --list-all
public (active)
  target: default
  icmp-block-inversion: no
  interfaces: eth0 eth1
  sources: 
  services: ssh dhcpv6-client mysql
  ports: 4567/tcp 4567/udp 4568/tcp 4444/tcp 24007/tcp 111/tcp 111/udp 49152/tcp 49153/tcp
  protocols: 
  masquerade: no
  forward-ports: 
  source-ports: 
  icmp-blocks: 
  rich rules: 
```

### GlusterFS

Для экономии ресурсов (еще +3 виртуальные машины мой хост уже не тянет), для GlusterFS использованы те же виртуалки: db1, db2, db3
После развертывания состояние gluster можно проверить командами:

```bash
[root@db1 ~]# gluster peer status
Number of Peers: 2

Hostname: db3
Uuid: 42075f0f-18e0-4469-8496-df176949b17f
State: Peer in Cluster (Connected)

Hostname: db2
Uuid: 2e6da611-3884-4bc3-9ecb-b8c9f155b4dc
State: Peer in Cluster (Connected)
```

```bash
[root@db1 ~]# gluster pool list
UUID					Hostname 	State
42075f0f-18e0-4469-8496-df176949b17f	db3      	Connected 
2e6da611-3884-4bc3-9ecb-b8c9f155b4dc	db2      	Connected 
7fcbcde8-8976-4622-97ad-d9d9b1a33533	localhost	Connected 
[root@db1 ~]# gluster volume info
 
Volume Name: gluster
Type: Disperse
Volume ID: 94a51a5e-8061-4d22-8272-45a99c31af4e
Status: Started
Snapshot Count: 0
Number of Bricks: 1 x (2 + 1) = 3
Transport-type: tcp
Bricks:
Brick1: db1:/srv/gluster/brick
Brick2: db2:/srv/gluster/brick
Brick3: db3:/srv/gluster/brick
Options Reconfigured:
network.ping-timeout: 5
transport.address-family: inet
storage.fips-mode-rchecksum: on
nfs.disable: on
```

```bash
[root@db1 ~]# gluster volume status
Status of volume: gluster
Gluster process                             TCP Port  RDMA Port  Online  Pid
------------------------------------------------------------------------------
Brick db1:/srv/gluster/brick                49152     0          Y       12075
Brick db2:/srv/gluster/brick                49152     0          Y       10726
Brick db3:/srv/gluster/brick                49152     0          Y       10912
Self-heal Daemon on localhost               N/A       N/A        Y       12096
Self-heal Daemon on db3                     N/A       N/A        Y       10933
Self-heal Daemon on db2                     N/A       N/A        Y       10747
 
Task Status of Volume gluster
------------------------------------------------------------------------------
There are no active volume tasks
```

На клиентах FE1, FE2 смонтирован разделяемый ресурс 
```bash
[vagrant@fe2 ~]$ cat /etc/fstab |grep gluster
db1,db2,db3:gluster /var/www glusterfs defaults,_netdev 0 0

[vagrant@fe2 ~]$ df -h /var/www
Filesystem      Size  Used Avail Use% Mounted on
db1:gluster      80G  7.9G   73G  10% /var/www
```

### Фронтенды

На виртуалках FE1, FE2 установлен nginx+php. Для обеспечения отказоустойчивости, настроен keepalived и виртуальный адрес 
192.168.34.100 для обеспечения доступности для клиентов.

### Тестирование WEB и keepalived

Сайт отвечает

```bash
$ curl -I http://192.168.34.100/
HTTP/1.1 302 Found
Server: nginx/1.16.1
Date: Thu, 06 Feb 2020 04:28:42 GMT
Content-Type: text/html; charset=UTF-8
Connection: keep-alive
X-Powered-By: PHP/7.2.27
Expires: Wed, 11 Jan 1984 05:00:00 GMT
Cache-Control: no-cache, must-revalidate, max-age=0
X-Redirect-By: WordPress
Location: http://192.168.34.100/wp-admin/install.php
```

И предлагает настроить и сконфигурировать wordpress при первом запуске

```bash
$ curl -I http://192.168.34.100/wp-admin/install.php
HTTP/1.1 200 OK
Server: nginx/1.16.1
Date: Thu, 06 Feb 2020 04:30:24 GMT
Content-Type: text/html; charset=utf-8
Connection: keep-alive
X-Powered-By: PHP/7.2.27
Expires: Wed, 11 Jan 1984 05:00:00 GMT
Cache-Control: no-cache, must-revalidate, max-age=0
```

### Работа keepalived

Для проверки создадим маленькую web-страничку, которая в браузере возвращает имя хоста, который обработал запрос:

```bash
[root@fe1 ~]# cat /var/www/html/wordpress/i.php
<?php
echo("Hello from ".gethostname()." !\n");
?>
```

Запускаем для проверки скрипт, который каждые пару секунд запрашивает тестовую страничку, и пишет имя сервера, который обработал запрос.

```bash
[host ~]$ while true; do echo -n `date`" " ; curl http://192.168.34.100/i.php; sleep 2; done
Чт фев 6 02:02:25 +04 2020 Hello from fe1 !
Чт фев 6 02:02:27 +04 2020 Hello from fe1 !
Чт фев 6 02:02:29 +04 2020 Hello from fe1 !
Чт фев 6 02:02:31 +04 2020 Hello from fe1 !
Чт фев 6 02:02:33 +04 2020 Hello from fe1 !
```

В другой консоли имитируем сбой интерфейса на 30 секунд. (или просто перегрузить или выключить ноду)

```bash
[root@fe1 ~]# ip link set eth1 down; sleep 30; ip link set eth1 up
```

```bash
Чт фев 6 02:02:35 +04 2020 Hello from fe1 !
Чт фев 6 02:02:37 +04 2020 Hello from fe1 !
Чт фев 6 02:02:39 +04 2020 Hello from fe1 !
```
Виден момент переключения на вторую ноду

```bash
Чт фев 6 02:02:41 +04 2020 Hello from fe2 !
Чт фев 6 02:02:50 +04 2020 Hello from fe2 !
Чт фев 6 02:02:52 +04 2020 Hello from fe2 !
...
Чт фев 6 02:03:10 +04 2020 Hello from fe2 !
```

И возвращение виртуального адреса на первую ноду, как только она стала доступна

```bash
Чт фев 6 02:03:12 +04 2020 Hello from fe1 !
```
### Резервное копирование и логирование

Логи со всех машин собираются на сервере backup:/var/logs/remote

Резервное копирование осуществляется по расписанию (базы данных формируют mysqldump, а фронтенды архивируют веб-каталог) и 
затем копируется на предназначенный для этого сервер backup@backup:/home/backup/


### Литература

Настройка Galera кластера на MariaDB с Master-Master репликацией
https://bogachev.biz/2016/03/29/nastroika-galera-klastera-na-mariadb-s-master-master-replikaciei/

Настройка отказоустойчивого кластера MySQL с синхронной мульти-master репликацией с помощью Galera в Ubuntu, Debian и CentOS Linux
https://netpoint-dc.com/blog/mariadb-galera-3-node-cluster/

«Идеальный» www кластер. Часть 1. Frontend: NGINX + Keepalived (vrrp) на CentOS
https://habr.com/ru/company/acronis/blog/198934/


