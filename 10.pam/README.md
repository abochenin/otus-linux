# Домашнее задание 09.ansible
Домашнее задание

PAM
- Запретить всем пользователям, кроме группы admin логин в выходные(суббота и воскресенье), без учета праздников
- Дать конкретному пользователю права рута 

---


## Подготовка к запуску

Создаем окружение из подготовленного vagrant-файла
```bash
$ vagrant up
```


## Описание
В запущенной раннее виртуальной машине скрипт провижининга выполнил требуемые действия.
```bash
TASK [pam : PAM.1 | Добавляем правило "account required pam_exec.so" для модуля sshd] ***
changed: [hw10]

TASK [pam : PAM.2 | Добавляем пользователю user право запускать ЛЮБЫЕ команды через sudo без     пароля] ***
changed: [hw10]
```

## Проверки

```bash
$ vagrant ssh
[vagrant@hw10 ~]$ sudo bash
[root@hw10 vagrant]#
```

Устанавливаем дату на рабочий (не выходной) день
```bash
[root@hw10 vagrant]# date 09270000
Sat Sep 27 00:00:00 UTC 2019
```

И проверяем, что пользователь user успешно логинится в систему в разрешенное время.
```bash
[root@hw10 vagrant]# ssh user@localhost "id"
user@localhost's password:
uid=1001(user) gid=1002(user) groups=1002(user) context=unconfined_u:unconfined_r:unconfined_t:s0-s0:c0.c1023
```

Меняем дату на субботний день, и снова проверяем
```bash
[root@hw10 vagrant]# ssh user@localhost "id; date"
user@localhost's password:
/bin/pam_check.sh failed: exit code 1
Authentication failed.
```

Видим, что вход пользователю запрещен, что и требовалось в задаче. В то же время, пользователь admin (входящий в одноименную группу) без проблем регистрируется.
```bash
[root@hw10 vagrant]# ssh admin@localhost "id; date"
admin@localhost's password:
uid=1002(admin) gid=1001(admin) groups=1001(admin) context=unconfined_u:unconfined_r:unconfined_t:s0-s0:c0.c1023
Sat Sep 28 00:00:38 UTC 2019
[root@hw10 vagrant]#
```

Для демонстрации второй части домашнего задания, вернем дату снова на рабочий день
```bash
[root@hw10 vagrant]# date 09270000
Fri Sep 27 00:00:00 UTC 2019
```

И покажем, что пользователю user выдано право запускать через sudo любые команды без запроса пароля, например, просматривать содержимое /etc/shadow
Пароль запрашивается только на SSH сессию.
```bash
[root@hw10 vagrant]# ssh user@localhost "sudo grep admin /etc/shadow"
user@localhost's password:
admin:$6$KfF5wui6VUldSY4R$utUYbkWum7cIpcHTudow8A9.6o6fnWrcus3ur1bygrI0/6FjaW/znnDL2J/kHM1jplic85/.N/uMFIf91EeuR/:18165:0:99999:7:::
```

А ниже для сравнения как выглядит попытка пользователя admin использовать sudo. Видно, что пользователь не привелегирован, и все стандартные ограничения работают.
```bash
[root@hw10 vagrant]# ssh admin@localhost "sudo grep admin /etc/shadow"
admin@localhost's password:

We trust you have received the usual lecture from the local System
Administrator. It usually boils down to these three things:

    #1) Respect the privacy of others.
    #2) Think before you type.
    #3) With great power comes great responsibility.

sudo: no tty present and no askpass program specified
[root@hw10 vagrant]#
```
