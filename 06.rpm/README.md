# Домашнее задание 06.rpm
Домашнее задание

Размещаем свой RPM в своем репозитории
Цель: Часто в задачи администратора входит не только установка пакетов, но и сборка и поддержка собственного репозитория. Этим и займемся в ДЗ.
1) создать свой RPM (можно взять свое приложение, либо собрать к примеру апач с определенными опциями)
2) создать свой репо и разместить там свой RPM
реализовать это все либо в вагранте, либо развернуть у себя через nginx и дать ссылку на репо

---
## Описание 
Подготовлен vagrant файл и дополнительные файлы. В данной работе будет продемонтрирована сборка nginx с последней версией openssl, и подготовка репозитория с собранным пакетом.

## Подготовка к запуску

Создаем окружение из подготовленного vagrant-файла

```bash
$ vagrant up
$ vagrant ssh
[vagrant@hw5 ~]$ cd /vagrant 
```

Запускаем скрипт rpm.sh, который выполнит сборку nginx и создание repo
```bash
[root@hw6 vagrant]# ./run.sh
```


Результатом работы скрипта будет вывод в консоль списка репозиториев, и пример html страницы из браузера со списком пакетов

```bash
[root@hw6 vagrant]# yum repolist
Loaded plugins: fastestmirror
Loading mirror speeds from cached hostfile
 * base: mirror.yandex.ru
 * extras: mirror.yandex.ru
 * updates: mirror.yandex.ru
repo id                                              repo name                                              status
base/7/x86_64                                        CentOS-7 - Base                                        10,019
extras/7/x86_64                                      CentOS-7 - Extras                                         435
otus                                                 otus-linux                                                  2
updates/7/x86_64                                     CentOS-7 - Updates                                      2,500
repolist: 12,956
```

```bash
[root@hw6 vagrant]# wget -O- http://localhost/repo 2>/dev/null
<html>
<head><title>Index of /repo/</title></head>
<body>
<h1>Index of /repo/</h1><hr><pre><a href="../">../</a>
<a href="repodata/">repodata/</a>                                          02-Sep-2019 12:29                   -
<a href="nginx-1.16.1-1.el7.ngx.x86_64.rpm">nginx-1.16.1-1.el7.ngx.x86_64.rpm</a>                  02-Sep-2019 12:22             3713860
<a href="nginx-debuginfo-1.16.1-1.el7.ngx.x86_64.rpm">nginx-debuginfo-1.16.1-1.el7.ngx.x86_64.rpm</a>        02-Sep-2019 12:22             1960152
</pre><hr></body>
</html>
```








Запуск скрипта
```bash
$ cd /vagrant
$ sudo bash ./cpu.sh
```

Пример работы скрипта приведен ниже.

```bash
[vagrant@hw5 ~]$ sudo ./cpu.sh
thread 1 started
thread 2 started
root     14410 14407  0 20:13 pts/1    00:00:00 dd if=/dev/urandom of=/dev/null count=1000 bs=1M
root     14411 14408 99 20:13 pts/1    00:00:01 dd if=/dev/urandom of=/dev/null count=1000 bs=1M

root     14410 14407  0 20:13 pts/1    00:00:00 dd if=/dev/urandom of=/dev/null count=1000 bs=1M
root     14411 14408 99 20:13 pts/1    00:00:03 dd if=/dev/urandom of=/dev/null count=1000 bs=1M

root     14410 14407  0 20:13 pts/1    00:00:00 dd if=/dev/urandom of=/dev/null count=1000 bs=1M

root     14410 14407 16 20:13 pts/1    00:00:01 dd if=/dev/urandom of=/dev/null count=1000 bs=1M

root     14410 14407 28 20:13 pts/1    00:00:02 dd if=/dev/urandom of=/dev/null count=1000 bs=1M

root     14410 14407 37 20:13 pts/1    00:00:03 dd if=/dev/urandom of=/dev/null count=1000 bs=1M

root     14410 14407 44 20:13 pts/1    00:00:04 dd if=/dev/urandom of=/dev/null count=1000 bs=1M

root     14410 14407 50 20:13 pts/1    00:00:05 dd if=/dev/urandom of=/dev/null count=1000 bs=1M


Пониженный приоритет:

real    0m10.839s
user    0m0.005s
sys     0m5.329s

Повышенный приоритет:

real    0m5.392s
user    0m0.002s
sys     0m5.321s

```

Из отчета видно, что менее приоритетный процесс отрабатывает почти в два раза медленнее, чем высокоприоритетный. 
И эта разница во времени будет расти, если в скрипте увеличивать нагрузку на cpu, например увеличив значение count.

