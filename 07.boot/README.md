# Домашнее задание 07.boot
Домашнее задание

Работа с загрузчиком
Цель: Зайти в систему без пароля рута - базовая задача сисадмина ( ну и одно из заданий на любой линуксовой сертификации). Так же нужно уметь управлять поведением загрузчика. Это и будем учиться делать в ДЗ
1. Попасть в систему без пароля несколькими способами
2. Установить систему с LVM, после чего переименовать VG
3. Добавить модуль в initrd

---

## Подготовка к запуску

Создаем окружение из подготовленного vagrant-файла. 
```bash
$ vagrant up
```

## Способ 1.1
При загрузке виртуальной машины жмём E для входа в grub, и в строке параметров загрузки ядра меняем: 
стираем все опции console=** (иначе загрузка виртуалки виснет), 
стираем quiet для подробного лога, 
добавляем в опции init=/sysroot/bin/sh, 
добавляем enforcing=0 для временного отключения selinux.

Жмем Ctrl+X для продолжения загрузки, попадаем в шелл.
```bash
mount -o remount,rw /sysroot
chroot /sysroot
passwd root #меняем пароль на новый
reboot -f
```

Снова заходим в grub, добавляем enforcing=0 для временного отключения selinux, продолжаем загрузку и заходим в систему новым паролем root.

## Способ 1.2
При загрузке виртуальной машины жмём E для входа в grub, и в строке параметров загрузки ядра меняем: 
добавляем в опции init=/sysroot/bin/sh, 
стираем все опции console=** (иначе загрузка виртуалки виснет), 
стираем quiet для подробного лога, 
добавляем в опции rd.break

Жмем Ctrl+X для продолжения загрузки, попадаем в шелл.
```bash
mount -o remount,rw /sysroot
chroot /sysroot
passwd root #меняем пароль на новый
reboot -f
```

Снова заходим в grub, добавляем enforcing=0 для временного отключения selinux, продолжаем загрузку и заходим в систему новым паролем root.

# 2. Установить систему с LVM, после чего переименовать VG
Для второго задания подходит тот же vagrantfile. Исходное имя группы томов - VolGroup00. Её и будем переименовывать.
```bash
[vagrant@hw7 ~]$ sudo bash

[root@hw7 ~]# vgs
  VG         #PV #LV #SN Attr   VSize   VFree
  VolGroup00   1   2   0 wz--n- <38.97g    0

[root@hw7 ~]# lsblk
NAME                    MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda                       8:0    0   40G  0 disk
├─sda1                    8:1    0    1M  0 part
├─sda2                    8:2    0    1G  0 part /boot
└─sda3                    8:3    0   39G  0 part
  ├─VolGroup00-LogVol00 253:0    0 37.5G  0 lvm  /
  └─VolGroup00-LogVol01 253:1    0  1.5G  0 lvm  [SWAP]
```

```bash
[root@hw7 ~]# vgrename VolGroup00 vg
  Volume group "VolGroup00" successfully renamed to "vg"
```

И вносим соотвествующие изменения в конфиги
```bash
[root@hw7 ~]# sed -i "s/VolGroup00/vg/g" /etc/fstab
[root@hw7 ~]# sed -i "s/VolGroup00/vg/g" /etc/default/grub
[root@hw7 ~]# sed -i "s/VolGroup00/vg/g" /boot/grub2/grub.cfg
```

Перегружаемся, снова заходим в grub, добавляем enforcing=0 для временного отключения selinux, 
продолжаем загрузку и после входа в систему, видим что группа томов успешно переименована

```bash
[vagrant@hw7 ~]$ sudo vgs
  VG #PV #LV #SN Attr   VSize   VFree
  vg   1   2   0 wz--n- <38.97g    0

[vagrant@hw7 ~]$ sudo lsblk
NAME            MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda               8:0    0   40G  0 disk
├─sda1            8:1    0    1M  0 part
├─sda2            8:2    0    1G  0 part /boot
└─sda3            8:3    0   39G  0 part
  ├─vg-LogVol00 253:0    0 37.5G  0 lvm  /
  └─vg-LogVol01 253:1    0  1.5G  0 lvm  [SWAP]
```

# 3. Добавить модуль в initrd

Создаем папку для скриптов
```bash
[root@hw7 ~]# mkdir /usr/lib/dracut/modules.d/01test
```
Если vagrant запущен в Windows, то понадобится дополнительный шаг
```bash
[vagrant@hw7 ~]$ dos2unix /vagrant/*.sh
```

Копируем модуль
```bash
[root@hw7 ~]# cp /vagrant/*sh /usr/lib/dracut/modules.d/01test/
[root@hw7 ~]# chmod 755 /usr/lib/dracut/modules.d/01test/*.sh
```

Пересоздаем initrd
```bash
[root@hw7 ~]# dracut -fv
```

И проверяем что модуль попал в образ
```bash
[root@hw7 ~]# lsinitrd -m /boot/initramfs-$(uname -r).img | grep test
```

Отредактировать /etc/grub2.cfg, убрать из опций rhgb и quiet, и добавить enforcing=0 

В процессе загрузки увидим результат работы модуля (рисунок пингвинчика и пауза в 10 секунд)