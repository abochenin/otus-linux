# Домашнее задание 5.processes
Домашнее задание

Реализовать 2 конкурирующих процесса по CPU. пробовать запустить с разными nice
- Результат ДЗ - скрипт запускающий 2 процесса с разными nice и замеряющий время выполнения и лог консоли 

---
## Описание 
Подготовлен vagrant файл и скрипт cpu.sh.

## Подготовка к запуску

Создаем окружение из подготовленного vagrant-файла

```bash
$ vagrant up
$ vagrant ssh
[vagrant@hw5 ~]$ cd /vagrant 
```

Если vagrant запущен в Windows, то понадобится дополнительный шаг
```bash
[vagrant@hw5 ~]$ dos2unix /vagrant/cpu.sh
[vagrant@hw5 ~]$ chmod 755 /vagrant/cpu.sh
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
И эта разница во времени будет расти, если в скрипте увеличивать нагрузку на cpu, например 

