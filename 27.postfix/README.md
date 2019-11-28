## Домашнее задание 27.postfix
установка почтового сервера
1. Установить в виртуалке postfix+dovecot для приёма почты на виртуальный домен любым обсужденным на семинаре способом
2. Отправить почту телнетом с хоста на виртуалку
3. Принять почту на хост почтовым клиентом

Результат
1. Полученное письмо со всеми заголовками
2. Конфиги postfix и dovecot

Всё это сложить в git, ссылку прислать в "чат с преподавателем" 


## Конфигурация postfix
```bash
[root@server postfix]# cat main.cf |grep -v ^#|grep .
queue_directory = /var/spool/postfix
command_directory = /usr/sbin
daemon_directory = /usr/libexec/postfix
data_directory = /var/lib/postfix
mail_owner = postfix
inet_interfaces = all
inet_protocols = all
mydestination = $myhostname, localhost.$mydomain, localhost
unknown_local_recipient_reject_code = 550
mynetworks = 192.168.0.0/16, 127.0.0.0/8
relay_domains = example.com
virtual_mailbox_domains = example.com
virtual_mailbox_base = /var/mail/example.com
virtual_mailbox_maps = hash:/etc/postfix/vmailbox
virtual_minimum_uid = 100
virtual_uid_maps = static:1000
virtual_gid_maps = static:1000
virtual_alias_maps = hash:/etc/postfix/virtual
alias_maps = hash:/etc/aliases
alias_database = hash:/etc/aliases

debug_peer_level = 2
debugger_command =
         PATH=/bin:/usr/bin:/usr/local/bin:/usr/X11R6/bin
         ddd $daemon_directory/$process_name $process_id & sleep 5
sendmail_path = /usr/sbin/sendmail.postfix
newaliases_path = /usr/bin/newaliases.postfix
mailq_path = /usr/bin/mailq.postfix
setgid_group = postdrop
html_directory = no
manpage_directory = /usr/share/man
sample_directory = /usr/share/doc/postfix-2.10.1/samples
readme_directory = /usr/share/doc/postfix-2.10.1/README_FILES
```

```bash
[root@server postfix]# cat vmailbox |grep -v ^#|grep .
info@example.com    info/Maildir
sales@example.com   sales/Maildir
@example.com      catchall/Maildir
```

```bash
[root@server postfix]# cat virtual |grep -v ^#|grep .
postmaster@example.com  postmaster
```

## Конфигурация Dovecot
```bash
[root@server dovecot]# cat dovecot.conf |grep -v ^#|grep .
dict {
  #quota = mysql:/etc/dovecot/dovecot-dict-sql.conf.ext
  #expire = sqlite:/etc/dovecot/dovecot-dict-sql.conf.ext
}
!include conf.d/*.conf
!include_try local.conf
```

```bash
[root@server dovecot]# cat users
info@example.com:{PLAIN}password:1000:1000::/var/spool/mail/example.com/info::
sales@example.com:{CRAM-MD5}9186d855e11eba527a7a52ca82b313e180d62234f0acc9051b527243d41e2740:1000:1000::::
```




## Проверки

Организуем временный проброс портов для взаимодействия с postfix и dovecot виртуалки
```bash
$ ssh -L 8025:localhost:25 -L 8110:localhost:110 root@localhost:2222
```

В другом терминале проверяем отправку почты

```bash
$ netcat -v localhost 8025
Connection to localhost 8025 port [tcp/*] succeeded!
220 server.localdomain ESMTP Postfix
HELO ms.com
250 server.localdomain
MAIL FROM: <bg@ms.com>
250 2.1.0 Ok
RCPT TO: <info@example.com>
DATA
250 2.1.5 Ok
354 End data with <CR><LF>.<CR><LF>

test
.
quit250 2.0.0 Ok: queued as B4FEA5DD0

221 2.0.0 Bye
```

И получение почты

```bash
$ netcat -v localhost 8110
Connection to localhost 8110 port [tcp/*] succeeded!
+OK Dovecot ready.
user info@example.com
+OK
pass password
+OK Logged in.
top 1 2
From bg@ms.com  Thu Nov 28 21:53:46 2019
Return-Path: <bg@ms.com>
X-Original-To: info@example.com
Delivered-To: info@example.com
Received: from ms.com (localhost [IPv6:::1])
        by server.localdomain (Postfix) with SMTP id B4FEA5DD0
        for <info@example.com>; Thu, 28 Nov 2019 21:53:46 +0000 (UTC)
Message-Id: <20191128215346.B4FEA5DD0@server.localdomain>
Date: Thu, 28 Nov 2019 21:53:46 +0000 (UTC)
From: bg@ms.com

test


quit
+OK Logging out.
```