# Домашнее задание 09.ansible
Домашнее задание


Первые шаги с Ansible
Подготовить стенд на Vagrant как минимум с одним сервером. На этом сервере используя Ansible необходимо развернуть nginx со следующими условиями:
- необходимо использовать модуль yum/apt
- конфигурационные файлы должны быть взяты из шаблона jinja2 с перемененными
- после установки nginx должен быть в режиме enabled в systemd
- должен быть использован notify для старта nginx после установки
- сайт должен слушать на нестандартном порту - 8080, для этого использовать переменные в Ansible
* Сделать все это с использованием Ansible роли

---


## Подготовка к запуску

Создаем окружение из подготовленного vagrant-файла
```bash
$ vagrant up --no-provision
...
==> nginx: Machine not provisioned because `--no-provision` is specified.
```

*Замечание*

Ключ --no-provision был использован для проверки, что новая вагрант-машина не будет конфликтовать
по номеру порта доступа SSH с другими запущеными в памяти вагрант-машинами (если таковые есть)


Проверим, какой порт используется для доступа
```bash
$ vagrant ssh-config
Host nginx
  HostName 127.0.0.1
  User vagrant
  Port 2222
```

Если порт не 2222, то внесем соответствующие изменения в файл
```bash
$ cat inventories/staging/hosts
[web]
nginx ansible_host=127.0.0.1 ansible_port=2222 ansible_private_key_file=.vagrant/machines/nginx/virtualbox/private_key
```

И запускаем provision
```bash
$ vagrant provision
...
nginx                      : ok=6    changed=5    unreachable=0    failed=0
```


## Описание
В запущенной раннее виртуальной машине скрипт провижининга выполнил требуемые действия.

Проверяем, что порт 8080 прослушивается nginx
```bash
$ vagrant ssh
[vagrant@nginx ~]$ sudo ss -tulnp|grep 8080
tcp    LISTEN  0  128  *:8080  *:*   users:(("nginx",pid=6174,fd=6),("nginx",pid=6099,fd=6))
```

А также, что сервис nginx в состоянии enabled (vendor preset: disabled)
```bash
[vagrant@nginx ~]$ sudo systemctl status nginx
● nginx.service - The nginx HTTP and reverse proxy server
   Loaded: loaded (/usr/lib/systemd/system/nginx.service; enabled; vendor preset: disabled)
   Active: active (running) since Sun 2019-09-15 16:34:20 UTC; 3min 52s ago
  Process: 6173 ExecReload=/bin/kill -s HUP $MAINPID (code=exited, status=0/SUCCESS)
  Process: 6097 ExecStart=/usr/sbin/nginx (code=exited, status=0/SUCCESS)
  Process: 6095 ExecStartPre=/usr/sbin/nginx -t (code=exited, status=0/SUCCESS)
  Process: 6094 ExecStartPre=/usr/bin/rm -f /run/nginx.pid (code=exited, status=0/SUCCESS)
 Main PID: 6099 (nginx)
   CGroup: /system.slice/nginx.service
           ├─6099 nginx: master process /usr/sbin/nginx
           └─6174 nginx: worker process

Sep 15 16:34:20 nginx systemd[1]: Starting The nginx HTTP and reverse proxy server...
Sep 15 16:34:20 nginx nginx[6095]: nginx: the configuration file /etc/nginx/nginx.conf sy...s ok
Sep 15 16:34:20 nginx nginx[6095]: nginx: configuration file /etc/nginx/nginx.conf test i...sful
Sep 15 16:34:20 nginx systemd[1]: Failed to read PID from file /run/nginx.pid: Invalid argument
Sep 15 16:34:20 nginx systemd[1]: Started The nginx HTTP and reverse proxy server.
Sep 15 16:34:21 nginx systemd[1]: Reloading The nginx HTTP and reverse proxy server.
Sep 15 16:34:21 nginx systemd[1]: Reloaded The nginx HTTP and reverse proxy server.
Hint: Some lines were ellipsized, use -l to show in full.
```

