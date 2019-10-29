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
Проверяем открыт ли порт ssh на inetRouter, убеждаемся что порт закрыт
# netcat -v 192.168.255.1 22

Стучимся, заходим после стука
# /vagrant/knock.sh 192.168.255.1 8881 7777 9991
# ssh vagrant@192.168.255.1

# tracepath -n 8.8.8.8


# проверка curl 192.168.254.1:8080, должна быть веб-страница


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

