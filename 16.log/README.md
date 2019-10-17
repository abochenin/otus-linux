# Домашнее задание 16.log

Настраиваем центральный сервер для сбора логов
в вагранте поднимаем 2 машины web и log
на web поднимаем nginx
на log настраиваем центральный лог сервер на любой системе на выбор
- journald
- rsyslog
- elk
настраиваем аудит следящий за изменением конфигов нжинкса

все критичные логи с web должны собираться и локально и удаленно
все логи с nginx должны уходить на удаленный сервер (локально только критичные)
логи аудита должны также уходить на удаленную систему
---


## Подгототвка
Создаем виртуалки и отдельно выполняем провижн
```bash
vagrant up --no-provision
vagrant provision
```

## Проверки
Заходим на log, и начинаем следить за messages
```bash
vagrant ssh log
$ sudo su -
# tail -f /var/log/messages
```

В другой консоли подключаемся к web и пробуем http-запросы
```bash
vagrant ssh log
$ sudo su -
# curl localhost
# curl -I localhost
HTTP/1.1 200 OK
```

Веб сервис работает, ответ 200. В первой консоли видим, что обращение к nginx 
запротоколировано в логе:
```bash
Oct 17 20:07:29 web nginx: ::1 - - [17/Oct/2019:20:07:29 +0000] "GET / HTTP/1.1" 200 3700 "-" "curl/7.29.0" "-"
Oct 17 20:07:34 web nginx: ::1 - - [17/Oct/2019:20:07:34 +0000] "HEAD / HTTP/1.1" 200 0 "-" "curl/7.29.0" "-"
```

Вторая проверка. error_log также попадает на удаленный сервер

```bash
web# curl http://localhost/error.html

log#
Oct 17 20:12:58 web nginx: 2019/10/17 20:12:58 [error] 7918#0: *8 open() "/usr/share/nginx/html/error.html" failed (2: No such file or directory), client: ::1, server: _, request: "GET /error.html HTTP/1.1", host: "localhost"
Oct 17 20:12:58 web nginx: ::1 - - [17/Oct/2019:20:12:58 +0000] "GET /error.html HTTP/1.1" 404 3650 "-" "curl/7.29.0" "-"
```

Третья проверка. Критические события протоколируются
```bash
web# logger -p crit test-message

log# 
Oct 17 20:15:18 web vagrant: test-message
```


И наконец, события аудита. На лог-сервере запустим
```bash
log# tail -f /var/log/audit/audit.log
```

Затем на web попробуем "изменить" файл nginx.conf
```bash
web# touch /etc/nginx/nginx.con
web# logger -p crit test-crit-message
```

Локально, а также на удаленном сервере log наблюдаем в файле /var/log/audit/audit.log 
записи, содержащие ключевой маркер "web_changed_nginx.conf"
```bash
node=web type=SYSCALL msg=audit(1571343474.577:1808): arch=c000003e syscall=2 success=yes exit=3 a0=7ffd0164a8d2 a1=941 a2=1b6 a3=7ffd01648da0 items=2 ppid=7821 pid=7954 auid=1000 uid=0 gid=0 euid=0 suid=0 fsuid=0 egid=0 sgid=0 fsgid=0 tty=pts1 ses=5 comm="touch" exe="/usr/bin/touch" subj=unconfined_u:unconfined_r:unconfined_t:s0-s0:c0.c1023 key="web_changed_nginx.conf"
```
