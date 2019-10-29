## Домашнее задание 20.iptables
Сценарии iptables
1) реализовать knocking port
- centralRouter может попасть на ssh inetrRouter через knock скрипт
пример в материалах
2) добавить inetRouter2, который виден(маршрутизируется) с хоста
3) запустить nginx на centralServer
4) пробросить 80й порт на inetRouter2 8080
5) дефолт в инет оставить через inetRouter 

---


## Подготовка
Создаем виртуалки, набираемся терпения. Создаются не быстро...
```bash
vagrant up
```
## Проверки

Используется почти такая же схема сети, как в задании 18.networks, с небольшими изменениями.
В соответствии с заданием, добавлен хост inetRouter2

заходим на centralRouter
```bash
$ vagrant ssh centralRouter
```

Проверяем открыт ли порт ssh на inetRouter, убеждаемся что порт закрыт
```bash
[root@centralRouter ~]# socat - TCP4:192.168.255.1:22
^C
```
Пробуем постучаться
```bash
[root@centralRouter ~]# /vagrant/knock.sh 192.168.255.1 8881 7777 9991
```

И снова тестируем порт. Видим приглашаение SSH к сесии, что значит порт открылся (на короткое время)
```bash
[root@centralRouter ~]# socat - TCP4:192.168.255.1:22
SSH-2.0-OpenSSH_5.3
qwerty
Protocol mismatch.
[root@centralRouter ~]#
```

Внешний мир доступен через inerRouter, что и требовалось
```bash
[root@centralRouter ~]# traceroute -I 8.8.4.4
traceroute to 8.8.4.4 (8.8.4.4), 30 hops max, 60 byte packets
 1  gateway (192.168.255.1)  0.192 ms  0.227 ms  0.199 ms
 2  * * *
 3  * * *
 4  178.34.128.88 (178.34.128.88)  20.739 ms  21.252 ms  22.358 ms
 5  178.34.130.150 (178.34.130.150)  22.322 ms  22.824 ms  23.454 ms
 6  87.226.183.89 (87.226.183.89)  50.581 ms  43.536 ms  43.803 ms
 7  5.143.253.245 (5.143.253.245)  44.294 ms  44.576 ms  45.791 ms
 8  108.170.250.34 (108.170.250.34)  46.361 ms  46.895 ms  47.263 ms
 9  216.239.50.46 (216.239.50.46)  63.257 ms  58.947 ms  58.903 ms
10  216.239.54.50 (216.239.54.50)  56.248 ms  56.465 ms  55.981 ms
11  * * *
12  * * *
13  * * *
14  * * *
15  * * *
16  * * *
17  * * *
18  * * *
19  * * *
20  dns.google (8.8.4.4)  59.939 ms  60.398 ms  60.869 ms
```

Осталось проверить port address translation, доступность nginx через inetRouter2:8080
```bash
[root@centralRouter ~]# curl -I 192.168.254.1:8080
HTTP/1.1 200 OK
Server: nginx/1.16.1
Date: Tue, 29 Oct 2019 20:38:18 GMT
Content-Type: text/html
Content-Length: 4833
Last-Modified: Fri, 16 May 2014 15:12:48 GMT
Connection: keep-alive
ETag: "53762af0-12e1"
Accept-Ranges: bytes
```

## Схема сети
```bash
office1server
 eth1=192.168.2.66/26 ---+
                         |  office1router
                         |   eth1=192.168.2.1/26   o1-dev
                         +-- eth2=192.168.2.65/26  o1-test-servers
                             eth3=192.168.2.129/26 o1-managers
                             eth4=192.168.2.193/26 o1-office-hardware
                             eth5=192.168.255.6/30 router-net    --------+
                                                                         |                                                 inetRouter
                                                                         |   central-router                                 eth0=WAN uplink (nat)
                                                                         |    eth1=192.168.255.2/30  router-net ----------- eth1=192.168.255.1/30
                                                                         |         192.168.254.2/30             ----+
                                                                         +-------  192.168.255.5/30                 |
CENTRAL-SERVER                                                           +-------  192.168.255.9/30                 |      inetRouter2
 eth1=192.168.0.2/28 dir-net --------------------------------------------|--  eth2=192.168.0.1/28    dir-net        |       eth0=WAN uplink (nat)
 eth2=auto                                                               |    eth3=192.168.0.33/28   hw-net         +------ eth1=192.168.254.1/30
 eth3=auto                                                               |    eth4=192.168.0.65/26   mgt-net
                                                                         |
                                                                         |
                           office2router                                 |
office2server               eth1=192.168.1.1/25    o2-dev                |
 eth1=192.168.1.130/26------eth2=192.168.1.129/26  o2-test-servers       |
                            eth3=192.168.1.193/26  o2-ofice-hardware     |
                            eth4=192.168.255.10/30 router-net    --------+
```

