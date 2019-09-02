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

Создаем окружение из подготовленного vagrant-файла. Автоматически запустится скрипт провижининга rpm.sh

```bash
$ vagrant up
```

## Работа скрипта rpm.sh
Это скрипт выполнит сборку nginx и создание repo.
```bash
#!/bin/sh


cd /vagrant
# устанавливаем необходимые пакеты
yum install -y mc wget rpmdevtools rpm-build createrepo yum-utils  gcc

# скачиваем исходники nginx
wget http://nginx.org/packages/centos/7/SRPMS/nginx-1.16.1-1.el7.ngx.src.rpm
rpm -ivh ./nginx-1.16.1-1.el7.ngx.src.rpm

# .. и openssl
wget https://www.openssl.org/source/openssl-1.1.1c.tar.gz
mv openssl-1.1.1c.tar.gz ~/rpmbuild/SOURCES/

# копируем подгтовленный SPEC в сборочницу
cp /vagrant/nginx.spec ~/rpmbuild/SPECS/

yum-builddep -y ~/rpmbuild/SPECS/nginx.spec

# Сборка (долгий процесс)
rpmbuild --ba ~/rpmbuild/SPECS/nginx.spec

# Создаем папку для будущего репозитория 
mkdir /vagrant/repo
# собранные пакеты копируем в репо
cp ~/rpmbuild/RPMS/x86_64/*.rpm /vagrant/repo/
createrepo /vagrant/repo/

# Настраиваем конфигурацию нового репо
cp /vagrant/otus.repo /etc/yum.repos.d/

# Устанавливаем собранный nginx (пока из файла напрямую, НЕ из репо, т.к новый репо на этом этапе еще не существует, мы его именно и создаем)
rpm -ivh /vagrant/repo/nginx-1.16.1-1.el7.ngx.x86_64.rpm 
cp /vagrant/default.conf /etc/nginx/conf.d/default.conf
ln -s /vagrant/repo/ /usr/share/nginx/html/repo
systemctl start nginx
systemctl enable nginx
# отключаем SELINUX. с ним у меня возникли проблемы с доступом в nginx
sudo setenforce 0


# А вот теперь репо полностью готов
echo List of REPOs:
yum repolist

echo HOME page:
wget -O- http://localhost/repo 2>/dev/null
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