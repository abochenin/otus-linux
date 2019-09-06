# Домашнее задание 08.systemd
Домашнее задание

Цель: Управление автозагрузкой сервисов происходит через systemd. Вместо cron'а тоже используется systemd. И много других возможностей. В ДЗ нужно написать свой systemd-unit.
1. Написать сервис, который будет раз в 30 секунд мониторить лог на предмет наличия ключевого слова. Файл и слово должны задаваться в /etc/sysconfig
2. Из epel установить spawn-fcgi и переписать init-скрипт на unit-файл. Имя сервиса должно так же называться.
3. Дополнить юнит-файл apache httpd возможностьб запустить несколько инстансов сервера с разными конфигами

---

## Подготовка к запуску

Создаем окружение из подготовленного vagrant-файла. 
```bash
$ vagrant up
```

## 1. Написать сервис, который будет раз в 30 секунд мониторить лог на предмет наличия ключевого слова. Файл и слово должны задаваться в /etc/sysconfig
В запущенной раннее виртуальной машине скрипт провижининга создал в systemd таймер и сервис.

Проверяем запущенный таймер
```bash
[root@hw8 vagrant]# systemctl list-timers|grep monitor
Fri 2019-09-06 11:47:56 UTC  62ms ago Fri 2019-09-06 11:47:56 UTC  10ms ago  monitor.timer                monitor.service
```

Описание сервиса
```bash
[root@hw8 vagrant]# systemctl cat monitor.service
# /etc/systemd/system/monitor.service
[Unit]
Description=сервис, который будет раз в 30 секунд мониторить лог на предмет наличия ключевого слова. Файл и слово должны задаваться в /etc/sysconfig

[Service]
Type=oneshot
EnvironmentFile=/etc/sysconfig/monitor.conf
ExecStart=/vagrant/monitor.sh

[Install]
WantedBy=multi-user.target
```

Описание таймера
```bash
[root@hw8 vagrant]# systemctl cat monitor.timer
# /etc/systemd/system/monitor.timer
[Unit]
Description=сервис, который будет раз в 30 секунд мониторить лог на предмет наличия ключевого слова. Файл и слово должны задаваться в /etc/sysconfig

[Timer]
OnBootSec=1
OnActiveSec=1
OnUnitActiveSec=10
Unit=monitor.service
#Persistent=true

[Install]
WantedBy=timers.target
```


Проверить работу можно, например, записав в наблюдаемый лог ключевое слово:
```bash
[root@hw8 vagrant]# logger ERROR trapped
```

При этом в системном логе через некоторое время ожидаем увидеть реакцию от таймера в виде сообщения "Ключевое слово найдено!"
```bash
Sep  6 11:50:56 localhost systemd: Starting сервис, который будет раз в 30 секунд мониторить лог на предмет наличия ключевого слова. Файл и слово должны задаваться в /etc/sysconfig...
Sep  6 11:50:56 localhost monitor.sh: Начинаем со строки 1272, добавилось строк 3
Sep  6 11:50:56 localhost systemd: Started сервис, который будет раз в 30 секунд мониторить лог на предмет наличия ключевого слова. Файл и слово должны задаваться в /etc/sysconfig.
Sep  6 11:51:56 localhost systemd: Starting сервис, который будет раз в 30 секунд мониторить лог на предмет наличия ключевого слова. Файл и слово должны задаваться в /etc/sysconfig...
Sep  6 11:51:56 localhost monitor.sh: Начинаем со строки 1275, добавилось строк 3
Sep  6 11:51:56 localhost systemd: Started сервис, который будет раз в 30 секунд мониторить лог на предмет наличия ключевого слова. Файл и слово должны задаваться в /etc/sysconfig.
Sep  6 11:52:18 localhost vagrant: ERROR trapped
Sep  6 11:52:56 localhost systemd: Starting сервис, который будет раз в 30 секунд мониторить лог на предмет наличия ключевого слова. Файл и слово должны задаваться в /etc/sysconfig...
Sep  6 11:52:56 localhost root: Ключевое слово найдено!
Sep  6 11:52:56 localhost monitor.sh: Начинаем со строки 1278, добавилось строк 4
Sep  6 11:52:56 localhost systemd: Started сервис, который будет раз в 30 секунд мониторить лог на предмет наличия ключевого слова. Файл и слово должны задаваться в /etc/sysconfig.
```
Скрипт monitor.sh написан таким образом, что запоминает проанализированные сроки (позицию в файле) и при следующем запуске ищет ключевое слово только в добавившейся со времени последнего запуска порции данных.
Что и требовалось получить.

## 2. Из epel установить spawn-fcgi и переписать init-скрипт на unit-файл. Имя сервиса должно так же называться.
Скрипт провижининга уже установил необходимые компоненты.

Описание сервиса:
[root@hw8 system]# systemctl cat  spawn-fcgi.service
```bash
# /etc/systemd/system/spawn-fcgi.service
[Unit]
Description=Spawn FastCGI scripts to be used by web servers
After=network.target

[Service]
Type=simple
PidFile=/var/run/spawn-fcgi.pid
EnvironmentFile=/etc/sysconfig/spawn-fcgi
ExecStart=/usr/bin/spawn-fcgi -n $OPTIONS
KillMode=process

[Install]
WantedBy=multi-user.target
```

Статус, показывающий что сервер успешно работает
```bash
[root@hw8 system]# systemctl status spawn-fcgi.service
● spawn-fcgi.service - Spawn FastCGI scripts to be used by web servers
   Loaded: loaded (/etc/systemd/system/spawn-fcgi.service; disabled; vendor preset: disabled)
   Active: active (running) since Fri 2019-09-06 12:53:40 UTC; 2min 50s ago
 Main PID: 7903 (php-cgi)
   CGroup: /system.slice/spawn-fcgi.service
           ├─7903 /usr/bin/php-cgi
           ├─7904 /usr/bin/php-cgi
           ├─7905 /usr/bin/php-cgi
...
           ├─7934 /usr/bin/php-cgi
           └─7935 /usr/bin/php-cgi

Sep 06 12:53:40 hw8 systemd[1]: Started Spawn FastCGI scripts to be used by web servers.
Sep 06 12:53:40 hw8 systemd[1]: Starting Spawn FastCGI scripts to be used by web servers...
```

## 3. Дополнить юнит-файл apache httpd возможностью запустить несколько инстансов сервера с разными конфигами
Скрипт провижининга уже установил необходимые компоненты.

Описание сервиса. Отличие от дефолтного - в параметре EnvironmentFile
```bash
[root@hw8 vagrant]# systemctl cat httpd@.service
# /etc/systemd/system/httpd@.service
[Unit]
Description=The Apache HTTP Server
After=network.target remote-fs.target nss-lookup.target
Documentation=man:httpd(8)
Documentation=man:apachectl(8)

[Service]
Type=notify
EnvironmentFile=/etc/sysconfig/httpd-%I
ExecStart=/usr/sbin/httpd $OPTIONS -DFOREGROUND
ExecReload=/usr/sbin/httpd $OPTIONS -k graceful
ExecStop=/bin/kill -WINCH ${MAINPID}
# We want systemd to give httpd some time to finish gracefully, but still want
# it to kill httpd after TimeoutStopSec if something went wrong during the
# graceful stop. Normally, Systemd sends SIGTERM signal right after the
# ExecStop, which would kill httpd. We are sending useless SIGCONT here to give
# httpd time to finish.
KillSignal=SIGCONT
PrivateTmp=true

[Install]
WantedBy=multi-user.target
```

Содержимое шаблонов
```bash
[root@hw8 vagrant]# cat httpd-80
OPTIONS="-f conf/httpd.conf"
LANG=C

[root@hw8 vagrant]# cat httpd-8080
OPTIONS="-f conf/httpd-8080.conf"
LANG=C
```

И наконец подготовлен файл httpd-8080.conf, содержащий отличия от дефолтного в параметрах Listen и PidFile
[root@hw8 vagrant]# grep -iE "^Listen|^pidfile" httpd-8080.conf 
```bash
Listen 8080
PidFile /var/run/httpd-8080.pid
```

В результате имеем два инстанса сервера с разными конфигами
```bash
[root@hw8 vagrant]# netstat -nap|grep :80
tcp6       0      0 :::8080                 :::*                    LISTEN      9524/httpd          
tcp6       0      0 :::80                   :::*                    LISTEN      9511/httpd  
```
