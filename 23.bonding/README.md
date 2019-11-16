## Домашнее задание 23.bonding
строим бонды и вланы
В Office1 в тестовой подсети появляется сервер с доп. интерфесами и адресами в internal сети testLAN:
- testClient1 - 10.10.10.254
- testClient2 - 10.10.10.254
- testServer1- 10.10.10.1
- testServer2- 10.10.10.1

Изолировать с помощью vlan:
testClient1 <-> testServer1
testClient2 <-> testServer2

Между centralRouter и inetRouter создать 2 линка (общая inernal сеть) и объединить их с помощью bond-интерфейса,
проверить работу c отключением сетевых интерфейсов

Результат ДЗ: vagrant файл с требуемой конфигурацией
Конфигурация должна разворачиваться с помощью ansible

* реализовать teaming вместо bonding'а (проверить работу в active-active)
** реализовать работу интернета с test машин 
---


## Подготовка
Создаем виртуалки, набираемся терпения. Создаются не быстро...
```bash
vagrant up
```
Схема сети

![network](https://github.com/abochenin/otus-linux/blob/master/23.bonding/images/bonding.png)

## Проверки

Для проверки bonding зайдем на centralRouter, и на inetRouter. 

```bash
[root@centralRouter ~]# cat /proc/net/bonding/bond0
Ethernet Channel Bonding Driver: v3.7.1 (April 27, 2011)

Bonding Mode: fault-tolerance (active-backup) (fail_over_mac active)
Primary Slave: None
Currently Active Slave: eth1
MII Status: up
MII Polling Interval (ms): 100
Up Delay (ms): 0
Down Delay (ms): 0

Slave Interface: eth1
MII Status: up
Speed: 1000 Mbps
Duplex: full
Link Failure Count: 0
Permanent HW addr: 08:00:27:b7:53:20
Slave queue ID: 0

Slave Interface: eth2
MII Status: up
Speed: 1000 Mbps
Duplex: full
Link Failure Count: 0
Permanent HW addr: 08:00:27:2a:3e:53
Slave queue ID: 0
```

Поочередное отключение интерфейсов ifcfg down eth1, eth2 не разрывает канал между central и inetRouter.

```bash
[root@centralRouter ~]# ifdown eth1
Device 'eth1' successfully disconnected.

[root@centralRouter ~]# ping -c1 192.168.255.1
PING 192.168.255.1 (192.168.255.1) 56(84) bytes of data.
64 bytes from 192.168.255.1: icmp_seq=1 ttl=64 time=0.904 ms

[root@centralRouter ~]# cat /proc/net/bonding/bond0
Ethernet Channel Bonding Driver: v3.7.1 (April 27, 2011)

Bonding Mode: fault-tolerance (active-backup) (fail_over_mac active)
Primary Slave: None
Currently Active Slave: eth2
MII Status: up
MII Polling Interval (ms): 100
Up Delay (ms): 0
Down Delay (ms): 0

Slave Interface: eth2
MII Status: up
Speed: 1000 Mbps
Duplex: full
Link Failure Count: 0
Permanent HW addr: 08:00:27:2a:3e:53
Slave queue ID: 0

[root@centralRouter ~]# ifup eth1; ifdown eth2
Connection successfully activated (D-Bus active path: /org/freedesktop/NetworkManager/ActiveConnection/12)
Device 'eth2' successfully disconnected.

[root@centralRouter ~]# ping -c1 192.168.255.1
PING 192.168.255.1 (192.168.255.1) 56(84) bytes of data.
64 bytes from 192.168.255.1: icmp_seq=1 ttl=64 time=0.420 ms

[root@centralRouter ~]# ifup eth2
Connection successfully activated (D-Bus active path: /org/freedesktop/NetworkManager/ActiveConnection/13)
```

Проверяем vlan100. 
```bash
[root@testClient1 ~]# ping 10.10.10.1 -c1
PING 10.10.10.1 (10.10.10.1) 56(84) bytes of data.
64 bytes from 10.10.10.1: icmp_seq=1 ttl=64 time=0.641 ms
```

И в другом влане101

```bash
[vagrant@testClient2 ~]$ ping 10.10.10.1
PING 10.10.10.1 (10.10.10.1) 56(84) bytes of data.
64 bytes from 10.10.10.1: icmp_seq=1 ttl=64 time=0.389 ms
64 bytes from 10.10.10.1: icmp_seq=2 ttl=64 time=0.295 ms
```

Общая статистика 

```bash
[root@officeRouter network-scripts]# cat /proc/net/vlan/eth1.100
eth1.100  VID: 100       REORDER_HDR: 1  dev->priv_flags: 1
         total frames received         1031
          total bytes received        84140
      Broadcast/Multicast Rcvd            0

      total frames transmitted         1037
       total bytes transmitted        97802
Device: eth1
INGRESS priority mappings: 0:0  1:0  2:0  3:0  4:0  5:0  6:0 7:0
 EGRESS priority mappings:

[root@officeRouter network-scripts]# cat /proc/net/vlan/eth1.101
eth1.101  VID: 101       REORDER_HDR: 1  dev->priv_flags: 1
         total frames received          776
          total bytes received        35696
      Broadcast/Multicast Rcvd            0

      total frames transmitted           10
       total bytes transmitted          740
Device: eth1
INGRESS priority mappings: 0:0  1:0  2:0  3:0  4:0  5:0  6:0 7:0
 EGRESS priority mappings:
```


# Интернет из тестовых зон. 

Для этого на officeRouter настроен NAT, и добавлены соответствующие правила в iptables.

```bash
[root@testClient1 ~]# ip r
default via 10.10.10.100 dev eth1.100 proto static metric 400
10.0.2.0/24 dev eth0 proto kernel scope link src 10.0.2.15 metric 101
10.10.10.0/24 dev eth1.100 proto kernel scope link src 10.10.10.254 metric 400

[root@testClient1 ~]# ping 8.8.4.4
PING 8.8.4.4 (8.8.4.4) 56(84) bytes of data.
64 bytes from 8.8.4.4: icmp_seq=1 ttl=57 time=45.6 ms
64 bytes from 8.8.4.4: icmp_seq=2 ttl=57 time=45.1 ms
^C

[root@testClient1 ~]# tracepath -n 8.8.4.4
 1?: [LOCALHOST]                                         pmtu 1500
 1:  10.10.10.100                                          0.702ms
 1:  10.10.10.100                                          0.441ms
 2:  192.168.0.33                                          0.717ms
 3:  192.168.255.1                                         1.140ms
...
```

Но добиться работоспособности интернета из _обоих_ vlan не удалось, к сожалению. 

Эксперименты с macvlan к успеху не привели.

