## Домашнее задание 24.openvpn
VPN
1. Между двумя виртуалками поднять vpn в режимах
- tun
- tap
Прочуствовать разницу.

2. Поднять RAS на базе OpenVPN с клиентскими сертификатами, подключиться с локальной машины на виртуалку
---

## Материалы
Работа выполнялась по приложенной методичке OTUS__VPN.pdf

## TAP
Подготовка окружения. 
```bash
$ rm Vagrantfile
$ ln -s tap-Vagrantfile Vagrantfile
$ vagrant up
```

Виртуальные машины создаются, настраивается vpn, и в конце запускается тест скорости. Результаты представлены ниже
```bash
    client: [  4] local 10.10.10.2 port 47794 connected to 10.10.10.1 port 5201
    client: [ ID] Interval           Transfer     Bandwidth       Retr  Cwnd
    client: [  4]   0.00-5.00   sec  73.6 MBytes   123 Mbits/sec   10    329 KBytes
    client: [  4]   5.00-10.00  sec  73.5 MBytes   123 Mbits/sec   52    261 KBytes
    client: [  4]  10.00-15.01  sec  73.8 MBytes   124 Mbits/sec   59    205 KBytes
    client: [  4]  15.01-20.00  sec  73.5 MBytes   123 Mbits/sec   18    338 KBytes
    client: [  4]  20.00-25.01  sec  74.6 MBytes   125 Mbits/sec   68    332 KBytes
    client: [  4]  25.01-30.01  sec  73.7 MBytes   124 Mbits/sec   41    284 KBytes
    client: [  4]  30.01-35.01  sec  73.6 MBytes   124 Mbits/sec  152    266 KBytes
    client: [  4]  35.01-40.00  sec  73.8 MBytes   124 Mbits/sec   10    347 KBytes
    client: - - - - - - - - - - - - - - - - - - - - - - - - -
    client: [ ID] Interval           Transfer     Bandwidth       Retr
    client: [  4]   0.00-40.00  sec   590 MBytes   124 Mbits/sec  410             sender
    client: [  4]   0.00-40.00  sec   589 MBytes   124 Mbits/sec                  receiver
    client:
    client: iperf Done.
```

## TUN
Подготовка окружения. Для этогот теста подготовлен другой vagrantfile 
```bash
$ rm Vagrantfile
$ ln -s tun-Vagrantfile Vagrantfile
$ vagrant up
```

Виртуальные машины создаются, настраивается vpn, и в конце запускается тест скорости. Результаты представлены ниже

```bash
    client: [  4] local 10.10.10.2 port 38692 connected to 10.10.10.1 port 5201
    client: [ ID] Interval           Transfer     Bandwidth       Retr  Cwnd
    client: [  4]   0.00-5.01   sec  72.3 MBytes   121 Mbits/sec   13    328 KBytes
    client: [  4]   5.01-10.01  sec  70.9 MBytes   119 Mbits/sec   10    369 KBytes
    client: [  4]  10.01-15.00  sec  71.1 MBytes   119 Mbits/sec  103    210 KBytes
    client: [  4]  15.00-20.01  sec  74.0 MBytes   124 Mbits/sec   17    352 KBytes
    client: [  4]  20.01-25.00  sec  73.9 MBytes   124 Mbits/sec   43    316 KBytes
    client: [  4]  25.00-30.00  sec  74.4 MBytes   125 Mbits/sec   59    272 KBytes
    client: [  4]  30.00-35.00  sec  73.9 MBytes   124 Mbits/sec   73    284 KBytes
    client: [  4]  35.00-40.00  sec  74.5 MBytes   125 Mbits/sec    3    328 KBytes
    client: - - - - - - - - - - - - - - - - - - - - - - - - -
    client: [ ID] Interval           Transfer     Bandwidth       Retr
    client: [  4]   0.00-40.00  sec   585 MBytes   123 Mbits/sec  321             sender
    client: [  4]   0.00-40.00  sec   584 MBytes   122 Mbits/sec                  receiver
    client:
    client: iperf Done.
```
Как можно видеть, скорость TUN практически одинаковая по сравнению с TAP. Теоретически, tun должен быть быстрее 
за счет меньших накладных расходов на заголовки пакетов, но в тестовой среде это почти не заметно.

## OpenVPN
Подготовка окружения. Для этого теста подготовлен другой vagrantfile 
Для работы также понадобится vagrant-plugin scp. Установить его можно так:
```bash
$ vagrant plugin install vagrant-scp
Installing the 'vagrant-scp' plugin. This can take a few minutes...
Fetching: vagrant-scp-0.5.7.gem (100%)
Installed the plugin 'vagrant-scp (0.5.7)'!
```

Разворачиваем окружение. Подготовлен скрипт vpn.sh, который делает необходимое
```bash
#!/bin/bash

rm -rf pki
vagrant destroy -f
rm Vagrantfile
ln -s openvpn-Vagrantfile Vagrantfile

vagrant up server
vagrant scp  server:/vagrant/pki/ ./pki/
vagrant up client --no-provision
vagrant provision client
```

Запускаем его. 

```bash
$ sh vpn.sh
```
В результате создаются и настраиваются виртуальные машины server и client, и в качестве итогового 
проверочного теста с клиента пингуется сервер по установленному vpn каналу


В процессе будут появляться в большом количестве сообщения вроде таких
```bash
    server: ..
    server: ..+
    server: .
    server: ...
```
Такое поведение - нормально, так выглядит генерация ключа Diffie–Hellman, и этот процесс очень долгий, займет несколько минут.


```bash
    client: Thu Nov 21 11:00:00 2019 /sbin/ip addr add dev tun0 local 10.10.10.6 peer 10.10.10.5
    client: Thu Nov 21 11:00:00 2019 /sbin/ip route add 10.10.10.0/24 via 10.10.10.5
    client: Thu Nov 21 11:00:00 2019 WARNING: this configuration may cache passwords in memory -- use the auth-nocache option to prevent this
    client: Thu Nov 21 11:00:00 2019 Initialization Sequence Completed
    client: PING 10.10.10.1 (10.10.10.1) 56(84) bytes of data.
    client: 64 bytes from 10.10.10.1: icmp_seq=1 ttl=64 time=0.830 ms
    client: 64 bytes from 10.10.10.1: icmp_seq=2 ttl=64 time=0.945 ms
    client: 64 bytes from 10.10.10.1: icmp_seq=3 ttl=64 time=0.617 ms
    client: 64 bytes from 10.10.10.1: icmp_seq=4 ttl=64 time=0.880 ms
```

По успешному пингу видим, что vpn работает.
