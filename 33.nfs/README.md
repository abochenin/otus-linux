## Домашнее задание 33.nfs
Vagrant стенд для NFS или SAMBA
NFS или SAMBA на выбор:

vagrant up должен поднимать 2 виртуалки: сервер и клиент
на сервер должна быть расшарена директория
на клиента она должна автоматически монтироваться при старте (fstab или autofs)
в шаре должна быть папка upload с правами на запись
- требования для NFS: NFSv3 по UDP, включенный firewall

## Развертываем инфраструктуру

```bash
$ vagrant up
    client: Complete!
==> client: Running provisioner: shell...
    client: Running: inline script
    client: Created symlink from /etc/systemd/system/multi-user.target.wants/nfs-server.service to /usr/lib/systemd/system/nfs-server.service.
    client: Created symlink from /etc/systemd/system/dbus-org.fedoraproject.FirewallD1.service to /usr/lib/systemd/system/firewalld.service.
    client: Created symlink from /etc/systemd/system/multi-user.target.wants/firewalld.service to /usr/lib/systemd/system/firewalld.service.
```

## Проверки

На сервере firewall запущен
```bash
$ vagrant ssh server
[vagrant@server ~]$ sudo su -
[root@server ~]# firewall-cmd --state
running

[root@server ~]# firewall-cmd --list
usage: see firewall-cmd man page
firewall-cmd: error: ambiguous option: --list could match --list-lockdown-whitelist-contexts, --list-all, --list-lockdown-whitelist-uids, --list-ports, --list-source-ports, --list-lockdown-whitelist-users, --list-icmp-blocks, --list-interfaces, --list-rich-rules, --list-forward-ports, --list-services, --list-lockdown-whitelist-commands, --list-all-zones, --list-sources, --list-protocols
[root@server ~]# firewall-cmd --list-all
public (active)
  target: default
  icmp-block-inversion: no
  interfaces: eth0 eth1
  sources:
  services: ssh dhcpv6-client nfs3 mountd rpc-bind
  ports: 662/udp 662/tcp 892/udp 892/tcp 2020/udp 32769/udp 32803/tcp
  protocols:
  masquerade: no
  forward-ports:
  source-ports:
  icmp-blocks:
  rich rules:
```

Для корректной работы NFS совместно с firewalld понадобилось предварительно зафиксировать динамические порты в конфигурации
```bash
[root@server ~]# cat /etc/sysconfig/nfs
LOCKD_TCPPORT=32803
LOCKD_UDPPORT=32769
MOUNTD_PORT=892
STATD_PORT=662
STATD_OUTGOING_PORT=2020
...
```

На клиенте папка смонтирована и доступна на запись

```bash
$ vagrant ssh client
/home/bochenin/.vagrant.d/gems/2.4.9/gems/rubyhacks-0.1.5/lib/rubyhacks.rb:536: warning: constant ::Fixnum is deprecated
Last login: Sun Jan 19 20:37:27 2020 from 10.0.2.2
[vagrant@client ~]$ df -h
Filesystem                    Size  Used Avail Use% Mounted on
/dev/sda1                      40G  3.0G   38G   8% /
devtmpfs                      236M     0  236M   0% /dev
tmpfs                         244M     0  244M   0% /dev/shm
tmpfs                         244M  4.5M  240M   2% /run
tmpfs                         244M     0  244M   0% /sys/fs/cgroup
192.168.11.100:/export/share   40G  3.0G   38G   8% /mnt
tmpfs                          49M     0   49M   0% /run/user/1000
[vagrant@client ~]$ ls -al /mnt
total 0
drwxr-xr-x.  3 root root  20 Jan 19 19:56 .
dr-xr-xr-x. 18 root root 255 Jan 19 19:41 ..
drwxrwxrwx.  2 root root   6 Jan 19 19:56 upload

[vagrant@client ~]$ touch /mnt/upload/otus-test

[vagrant@client ~]$ ls -al /mnt/upload/otus-test
-rw-rw-r--. 1 vagrant vagrant 0 Jan 19 20:44 /mnt/upload/otus-test
[vagrant@client ~]$
```