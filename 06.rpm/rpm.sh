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
