#!/bin/sh

cp /vagrant/monitor.conf /etc/sysconfig/
cp /vagrant/*.timer /etc/systemd/system/
cp /vagrant/*.service /etc/systemd/system/

systemctl daemon-reload

systemctl start monitor.timer
systemctl status monitor.timer

systemctl list-timers

yum -y install epel-release
yum -y install spawn-fcgi php php-cli mod_fcgid httpd
sed -i 's/#SOCKET/SOCKET/' /etc/sysconfig/spawn-fcgi
sed -i 's/#OPTIONS/OPTIONS/' /etc/sysconfig/spawn-fcgi

systemctl enable --now spawn-fcgi
systemctl status spawn-fcgi


cp /vagrant/httpd-80 /etc/sysconfig/
cp /vagrant/httpd-8080 /etc/sysconfig/
cp /vagrant/httpd-8080.conf /etc/httpd/conf/
systemctl daemon-reload
systemctl start httpd@80
systemctl start httpd@8080

yum -y install net-tools
netstat -nap|grep :80
