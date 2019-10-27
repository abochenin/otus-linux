## Домашнее задание 19.ldap
LDAP
1. Установить FreeIPA
2. Написать playbook для конфигурации клиента
3*. Настроить авторизацию по ssh-ключам

В git - результирующий playbook 

---

yum install ipa-server ipa-server-dns
echo "192.168.50.10 ipa.otus.lan ipa" >> /etc/hosts
поменять в /etc/hosts 127.0.0.1 на 192.168.50.10 ipa.otus.lan ipa
yum install -y ipa-server-trust-ad bind bind-dyndb-ldap

ipa-server-install  --realm=OTUS.LAN --domain=otus.lan --hostname=ipa.otus.lan --ds-password=admin123 --admin-password=admin123 --mkhomedir --ssh-trust-dns --setup-dns --unattended --auto-forwarders --auto-reverse --no-host-dns --no-dnssec-validation

CLIENT
yum install ipa-client -y
поменять в /etc/hosts 127.0.0.1 на 192.168.50.11 client.otus.lan ipa
добавить 192.168.50.10 ipa.otus.lan
ipa-client-install --unattend --mkhomedir --enable-dns-updates --principal=admin --password=admin123 --domain=otus.lan --server=ipa.otus.lan --realm=OTUS.LAN

## Подготовка
Создаем виртуалки, набираемся терпения. Шаг установки сервера FreeIPA выполянется долго, минут 5-10...
```bash
vagrant up
```

## Проверки

Заходим на сервер ipa, и создаем первую клиентскую учетную запись 
```bash
$ vagrant ssh ipa
Password:
[vagrant@ipa ~]$ sudo su -
[root@ipa ~]#

[root@ipa ~]# kinit admin
Password for admin@OTUS.LAN:
[root@ipa ~]#
[root@ipa ~]# klist
Ticket cache: KEYRING:persistent:0:0
Default principal: admin@OTUS.LAN

Valid starting       Expires              Service principal
10/25/2019 20:43:57  10/26/2019 20:43:52  krbtgt/OTUS.LAN@OTUS.LAN
```

Создаем пользователя jbond

```bash
[root@ipa ~]# ipa user-add --first="User"  --last="Otus" --cn="User Otus" user
-----------------
Added user "user"
-----------------
  User login: user
  First name: User
  Last name: Otus
  Full name: User Otus
  Display name: User Otus
  Initials: UO
  Home directory: /home/user
  GECOS: User Otus
  Login shell: /bin/sh
  Principal name: user@OTUS.LAN
  Principal alias: user@OTUS.LAN
  Email address: user@otus.lan
  UID: 171400001
  GID: 171400001
  Password: False
  Member of groups: ipausers
  Kerberos keys available: False
```

И задаем ему пароль и ключ SSH

```bash
[root@ipa ~]# ipa user-mod user --password
Password:
Enter Password again to verify:

[root@ipa ~]# ipa user-mod client1 --sshpubkey="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDPo1y8bnxD71PLiuUjAh4zkRrwuZKUrbhitYApSzr6iP7Gn+zUcFCeeGMulQzp3mCOHs5B/HDh1LU7QCrIyz13gnAtKywkuxD1TI2zBq6bnfJRPXwWrDX0x7t+3Ghr6wv4F3G6hGGw9s1nZVu1OPlzjK6kBElyavrTkLV1Zp0Gr0ybT25FzTohOLn1/Tqfqndoc6qXZD34h8eD+0DVekaprRpX6TemscggxUAe6DeWeY8Ii6jdKq3vbUP3/eo8Aii0V/bwK9Vbn/M3OusckXeTbDyYNTK9Reo5S2lJJebTnQ4qRaTEjvffBrwj4LJBH2B5Q8csazv4LWJ//QzCi4kKFkjNsCzVrevN2GpZEmRCS5XuIUuRHwW3xS+DQI3+ShcixJ0Et+HoUF0rSI0KHVWJ3IvNvKs36EiD4c7ObHJEpCMpiluUiW/idAvvIIcIibGvtO5bIL6ISUXS7zRcmG+QrrYn87OzAVOdwSxVmZdpVmVTn3Kn+g4Ycmm6iL61CW/idrC4QdjFB+BP5AfJUpr3SFYK2Nd936J9rd1hTGwZensdIjz1Xt1IfY+gVjO1/MnD0A8gx+h9EYh5vEey7Lo6PgKiE4I+OvDhtTrY5B9c/rNvvdCAgu1l30b64D0s0jrIZJQ/tCPvwjmuw/V8buEMAKsSp+cucUQPqWFtAKnVgw== abochenin"
```

Пробуем зайти по ключу с клиента на сервер

```bash
[vagrant@client ~]$ ssh -i ~/.ssh/id_rsa user@ipa.otus.lan
Enter passphrase for key '/home/vagrant/.ssh/id_rsa':
Creating home directory for user.
-sh-4.2$
-sh-4.2$ uname -a
Linux ipa.otus.lan 3.10.0-957.12.2.el7.x86_64 #1 SMP Tue May 14 21:24:32 UTC 2019 x86_64 x86_64 x86_64 GNU/Linux
-sh-4.2$ id
uid=171400001(user) gid=171400001(user) groups=171400001(user) context=unconfined_u:unconfined_r:unconfined_t:s0-s0:c0.c1023
-sh-4.2$
```
