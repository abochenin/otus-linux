## Домашнее задание 22.bind
настраиваем split-dns
взять стенд https://github.com/erlong15/vagrant-bind
добавить еще один сервер client2
завести в зоне dns.lab
имена
web1 - смотрит на клиент1
web2 смотрит на клиент2

завести еще одну зону newdns.lab
завести в ней запись
www - смотрит на обоих клиентов

настроить split-dns
клиент1 - видит обе зоны, но в зоне dns.lab только web1

клиент2 видит только dns.lab

*) настроить все без выключения selinux

---


## Подготовка
Создаем виртуалки
```bash
vagrant up
```

## Проверки
Проверим, что первый клиент видит обе зоны, но в зоне dns.lab только web1
```bash
[vagrant@client ~]$ host www.newdns.lab.
www.newdns.lab has address 192.168.60.16
www.newdns.lab has address 192.168.50.15

[vagrant@client ~]$ host web1.dns.lab.
web1.dns.lab has address 192.168.50.15

[vagrant@client ~]$ host web2.dns.lab.
Host web2.dns.lab. not found: 3(NXDOMAIN)
```

Так и есть.

Теперь проверим второго клиента
```bash
[vagrant@client2 ~]$ host web1.dns.lab
web1.dns.lab has address 192.168.50.15

[vagrant@client2 ~]$ host web2.dns.lab
web2.dns.lab has address 192.168.50.16

[vagrant@client2 ~]$ host www.newdns.lab
Host www.newdns.lab not found: 2(SERVFAIL)
```

Зону newdns.lab он не видит, как и требовалось по условиям задачи.

Трансфер зон работает

```bash
[root@ns02 data]# grep completed /var/named/data/named.run
transfer of 'ddns.lab/IN/view1' from 192.168.50.10#53: Transfer completed: 1 messages, 6 records, 273 bytes, 0.001 secs (273000 bytes/sec)
transfer of 'dns.lab/IN/view1' from 192.168.50.10#53: Transfer completed: 1 messages, 7 records, 279 bytes, 0.006 secs (46500 bytes/sec)
transfer of 'newdns.lab/IN/view1' from 192.168.50.10#53: Transfer completed: 1 messages, 8 records, 297 bytes, 0.006 secs (49500 bytes/sec)
transfer of '50.168.192.in-addr.arpa/IN/view2' from 192.168.50.10#53: Transfer completed: 1 messages, 8 records, 319 bytes, 0.007 secs (45571 bytes/sec)
transfer of '50.168.192.in-addr.arpa/IN/view1' from 192.168.50.10#53: Transfer completed: 1 messages, 7 records, 305 bytes, 0.008 secs (38125 bytes/sec)
transfer of 'dns.lab/IN/view2' from 192.168.50.10#53: Transfer completed: 1 messages, 8 records, 292 bytes, 0.001 secs (292000 bytes/sec)
```


Зоны размещены в соответствии с документацией:
 - мастер в /var/named/, 
 - динамические в /var/named/dynamic/, 
 - вторичные в /var/named/slave/

SELINUX работает на всех узлах в режиме Enforcing.
