# Домашнее задание 3. LVM
Домашнее задание. Работа с LVM
на имеющемся образе
/dev/mapper/VolGroup00-LogVol00 38G 738M 37G 2% /

уменьшить том под / до 8G
выделить том под /home
выделить том под /var
/var - сделать в mirror
/home - сделать том для снэпшотов
прописать монтирование в fstab
попробовать с разными опциями и разными файловыми системами ( на выбор)
- сгенерить файлы в /home/
- снять снэпшот
- удалить часть файлов
- восстановится со снэпшота
- залоггировать работу можно с помощью утилиты script

* на нашей куче дисков попробовать поставить btrfs/zfs - с кешем, снэпшотами - разметить здесь каталог /opt

---

## Описание
Готовим временный том для корневого раздела

```console
[root@lvm ~]# pvcreate /dev/sdb
  Physical volume "/dev/sdb" successfully created.

[root@lvm vagrant]# pvs
  PV         VG         Fmt  Attr PSize   PFree
  /dev/sda3  VolGroup00 lvm2 a--  <38.97g     0
  /dev/sdb   VGroot     lvm2 a--  <10.00g <2.00g


[root@lvm vagrant]# vgcreate VGroot /dev/sdb
  Volume group "VGroot" successfully created

[root@lvm vagrant]# lvcreate -n LVroot -L 8G /dev/VGroot
  Logical volume "LVroot" created.

[root@lvm vagrant]# lvs
  LV       VG         Attr       LSize   Pool Origin Data%  Meta%  Move Log Cpy%Sync Convert
  LVroot   VGroot     -wi-a-----   8.00g
  LogVol00 VolGroup00 -wi-ao---- <37.47g
  LogVol01 VolGroup00 -wi-ao----   1.50g

[root@lvm vagrant]# mkfs.xfs /dev/VGroot/LVroot
meta-data=/dev/VGroot/LVroot     isize=512    agcount=4, agsize=524288 blks
         =                       sectsz=512   attr=2, projid32bit=1
         =                       crc=1        finobt=0, sparse=0
data     =                       bsize=4096   blocks=2097152, imaxpct=25
         =                       sunit=0      swidth=0 blks
naming   =version 2              bsize=4096   ascii-ci=0 ftype=1
log      =internal log           bsize=4096   blocks=2560, version=2
         =                       sectsz=512   sunit=0 blks, lazy-count=1
realtime =none                   extsz=4096   blocks=0, rtextents=0
[root@lvm vagrant]# mount /dev/VGroot/LVroot /mnt
```


Устанавливаем xfsdump и копируем корень

```console
[root@lvm vagrant]# yum install xfsdump

[root@lvm vagrant]# xfsdump -J - /dev/VolGroup00/LogVol00 |xfsrestore -J - /mnt/
xfsrestore: using file dump (drive_simple) strategy
...
xfsrestore: Restore Status: SUCCESS
```

Восстанавливаем загрузчик

```console
[root@lvm vagrant]# for a in dev proc sys run boot; do mount --bind /$a /mnt/$a; done
[root@lvm vagrant]# chroot /mnt
[root@lvm vagrant]# grub2-mkconfig -o /boot/grub2/grub.cfg 

[root@lvm vagrant]# cd /boot
[root@lvm boot]# dracut -v initramfs-3.10.0-862.2.3.el7.x86_64.img 3.10.0-862.2.3.el7.x86_64


[root@lvm boot]# vi /boot/grub2/grub.cfg
```

Исправляем в конфиге загрузчика rd.lvm.lv

```console
[root@lvm boot]# grep lvm /boot/grub2/grub.cfg
        linux16 /vmlinuz-3.10.0-862.2.3.el7.x86_64 root=/dev/mapper/VGroot-LVroot ro no_timer_check console=tty0 console=ttyS0,115200n8 net.ifnames=0 biosdevname=0 elevator=noop crashkernel=auto rd.lvm.lv=VGroot/LVroot rhgb quiet


[root@lvm boot]# reboot
```

После перезагрузки корень уже в новом логическом томе

```console
[root@lvm ~]# lsblk
NAME                    MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda                       8:0    0   40G  0 disk
├─sda1                    8:1    0    1M  0 part
├─sda2                    8:2    0    1G  0 part /boot
└─sda3                    8:3    0   39G  0 part
  ├─VolGroup00-LogVol00 253:1    0 37.5G  0 lvm
  └─VolGroup00-LogVol01 253:2    0  1.5G  0 lvm  [SWAP]
sdb                       8:16   0   10G  0 disk
└─VGroot-LVroot         253:0    0    8G  0 lvm  /
sdc                       8:32   0    2G  0 disk
sdd                       8:48   0    1G  0 disk
sde                       8:64   0    1G  0 disk
```

Удаляем старый том, создаем новый объемом 8Гб, размечаем файловую систему и монтируем

```console
[root@lvm ~]# lvremove /dev/VolGroup00/LogVol00
Do you really want to remove active logical volume VolGroup00/LogVol00? [y/n]: y
  Logical volume "LogVol00" successfully removed

[root@lvm ~]# lvcreate -L 8G -n LogVol00 VolGroup00
WARNING: xfs signature detected on /dev/VolGroup00/LogVol00 at offset 0. Wipe it? [y/n]: y
  Wiping xfs signature on /dev/VolGroup00/LogVol00.
  Logical volume "LogVol00" created.

[root@lvm ~]# mkfs.xfs /dev/VolGroup00/LogVol00
meta-data=/dev/VolGroup00/LogVol00 isize=512    agcount=4, agsize=524288 blks
         =                       sectsz=512   attr=2, projid32bit=1
         =                       crc=1        finobt=0, sparse=0
data     =                       bsize=4096   blocks=2097152, imaxpct=25
         =                       sunit=0      swidth=0 blks
naming   =version 2              bsize=4096   ascii-ci=0 ftype=1
log      =internal log           bsize=4096   blocks=2560, version=2
         =                       sectsz=512   sunit=0 blks, lazy-count=1
realtime =none                   extsz=4096   blocks=0, rtextents=0
[root@lvm ~]# mount /dev/VolGroup00/LogVol00 /mnt
```

Переносим корень с использованием xfsdump, и обновляем загрузчик

```console
[root@lvm ~]# xfsdump -J - /dev/VGroot/LVroot |xfsrestore -J - /mnt/
xfsrestore: using file dump (drive_simple) strategy
...
xfsdump: dump size (non-dir files) : 727118216 bytes
xfsdump: dump complete: 11 seconds elapsed
xfsdump: Dump Status: SUCCESS
xfsrestore: restore complete: 12 seconds elapsed
xfsrestore: Restore Status: SUCCESS

[root@lvm vagrant]# for a in dev proc sys run boot; do mount --bind /$a /mnt/$a; done
[root@lvm vagrant]# chroot /mnt
[root@lvm vagrant]# grub2-mkconfig -o /boot/grub2/grub.cfg
Found linux image: /boot/vmlinuz-3.10.0-862.2.3.el7.x86_64
Found initrd image: /boot/initramfs-3.10.0-862.2.3.el7.x86_64.img

[root@lvm vagrant]# cd /boot
[root@lvm boot]# dracut -v initramfs-3.10.0-862.2.3.el7.x86_64.img 3.10.0-862.2.3.el7.x86_64
[root@lvm boot]# vi /boot/grub2/grub.cfg
```

Создаем зеркало на двух одинаковых дисках для раздела /var

```console
[root@lvm /]# lsblk
NAME                    MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda                       8:0    0   40G  0 disk
├─sda1                    8:1    0    1M  0 part
├─sda2                    8:2    0    1G  0 part /boot
└─sda3                    8:3    0   39G  0 part
  ├─VolGroup00-LogVol00 253:1    0    8G  0 lvm  /
  └─VolGroup00-LogVol01 253:2    0  1.5G  0 lvm  [SWAP]
sdb                       8:16   0   10G  0 disk
└─VGroot-LVroot         253:0    0    8G  0 lvm
sdc                       8:32   0    2G  0 disk
sdd                       8:48   0    1G  0 disk
sde                       8:64   0    1G  0 disk

[root@lvm /]# pvcreate /dev/sd{d,e}
  Physical volume "/dev/sdd" successfully created.
  Physical volume "/dev/sde" successfully created.

[root@lvm /]# vgcreate VGvar /dev/sd{d,e}
  Volume group "VGvar" successfully created

[root@lvm /]# lvcreate -L 1G -m1 -n LVvar VGvar
  Insufficient free space: 514 extents needed, but only 510 available

[root@lvm /]# lvcreate -L 950M -m1 -n LVvar VGvar
  Rounding up size to full physical extent 952.00 MiB
  Logical volume "LVvar" created.

[root@lvm /]# lvs
  LV       VG         Attr       LSize   Pool Origin Data%  Meta%  Move Log Cpy%Sync Convert
  LVroot   VGroot     -wi-ao----   8.00g
  LVvar    VGvar      rwi-a-r--- 952.00m                                    100.00
  LogVol00 VolGroup00 -wi-ao----   8.00g
  LogVol01 VolGroup00 -wi-ao----   1.50g

[root@lvm /]# mkfs.ext4 /dev/VGvar/LVvar
mke2fs 1.42.9 (28-Dec-2013)
Filesystem label=
OS type: Linux
Block size=4096 (log=2)
Fragment size=4096 (log=2)
Stride=0 blocks, Stripe width=0 blocks
60928 inodes, 243712 blocks
12185 blocks (5.00%) reserved for the super user
First data block=0
Maximum filesystem blocks=249561088
8 block groups
32768 blocks per group, 32768 fragments per group
7616 inodes per group
Superblock backups stored on blocks:
        32768, 98304, 163840, 229376

Allocating group tables: done
Writing inode tables: done
Creating journal (4096 blocks): done
Writing superblocks and filesystem accounting information: done

[root@lvm /]# mount /dev/VGvar/LVvar /mnt
```

... и переносим данные на подготовленный раздел

```console
[root@lvm /]# rsync -PavHxXAS /var/ /mnt/

[root@lvm /]# mkdir /tmp/var; mv /var/* /tmp/var/
[root@lvm /]# ls /var
[root@lvm /]# umount /mnt
[root@lvm /]# mount /dev/VGvar/LVvar /var
[root@lvm /]# blkid|grep var
/dev/mapper/VGvar-LVvar_rimage_0: UUID="a423403e-f90b-42ad-98fc-9e0c8282ae85" TYPE="ext4"
/dev/mapper/VGvar-LVvar_rimage_1: UUID="a423403e-f90b-42ad-98fc-9e0c8282ae85" TYPE="ext4"
/dev/mapper/VGvar-LVvar: UUID="a423403e-f90b-42ad-98fc-9e0c8282ae85" TYPE="ext4"

[root@lvm /]# vi /etc/fstab
[root@lvm /]# grep var /etc/fstab
UUID="a423403e-f90b-42ad-98fc-9e0c8282ae85" 	/var 	ext4 	defaults 0 0
```

[root@lvm /]# reboot

Проверяем результат. Корень усечен до 8Гб, var в зеркале.

```console
[root@lvm vagrant]# lsblk
NAME                    MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda                       8:0    0   40G  0 disk
├─sda1                    8:1    0    1M  0 part
├─sda2                    8:2    0    1G  0 part /boot
└─sda3                    8:3    0   39G  0 part
  ├─VolGroup00-LogVol00 253:0    0    8G  0 lvm  /
  └─VolGroup00-LogVol01 253:1    0  1.5G  0 lvm  [SWAP]
sdb                       8:16   0   10G  0 disk
└─VGroot-LVroot         253:7    0    8G  0 lvm
sdc                       8:32   0    2G  0 disk
sdd                       8:48   0    1G  0 disk
├─VGvar-LVvar_rmeta_0   253:2    0    4M  0 lvm
│ └─VGvar-LVvar         253:6    0  952M  0 lvm  /var
└─VGvar-LVvar_rimage_0  253:3    0  952M  0 lvm
  └─VGvar-LVvar         253:6    0  952M  0 lvm  /var
sde                       8:64   0    1G  0 disk
├─VGvar-LVvar_rmeta_1   253:4    0    4M  0 lvm
│ └─VGvar-LVvar         253:6    0  952M  0 lvm  /var
└─VGvar-LVvar_rimage_1  253:5    0  952M  0 lvm
  └─VGvar-LVvar         253:6    0  952M  0 lvm  /var
```

Осталось удалить ненужную группу томов и логический том

```console
[root@lvm vagrant]# lvremove /dev/VGroot/LVroot
Do you really want to remove active logical volume VGroot/LVroot? [y/n]: y
  Logical volume "LVroot" successfully removed

[root@lvm vagrant]# vgs
  VG         #PV #LV #SN Attr   VSize   VFree
  VGroot       1   0   0 wz--n- <10.00g <10.00g
  VGvar        2   1   0 wz--n-   1.99g 128.00m
  VolGroup00   1   2   0 wz--n- <38.97g <29.47g

[root@lvm vagrant]# vgremove /dev/VGroot
  Volume group "VGroot" successfully removed

[root@lvm vagrant]# pvremove /dev/sdb
  Labels on physical volume "/dev/sdb" successfully wiped.
```
Переносим /home на логический том

```console
[root@lvm vagrant]# lvcreate -L 2G -n LVhome VolGroup00
  Logical volume "LVhome" created.

[root@lvm vagrant]# mkfs.xfs /dev/VolGroup00/L
LogVol00  LogVol01  LVhome

[root@lvm vagrant]# mkfs.xfs /dev/VolGroup00/LVhome
meta-data=/dev/VolGroup00/LVhome isize=512    agcount=4, agsize=131072 blks
         =                       sectsz=512   attr=2, projid32bit=1
         =                       crc=1        finobt=0, sparse=0
data     =                       bsize=4096   blocks=524288, imaxpct=25
         =                       sunit=0      swidth=0 blks
naming   =version 2              bsize=4096   ascii-ci=0 ftype=1
log      =internal log           bsize=4096   blocks=2560, version=2
         =                       sectsz=512   sunit=0 blks, lazy-count=1
realtime =none                   extsz=4096   blocks=0, rtextents=0

[root@lvm vagrant]# mount /dev/VolGroup00/LVhome /mnt

[root@lvm vagrant]# cp -aR /home/* /mnt/

[root@lvm vagrant]# rm -rf /home/*

[root@lvm vagrant]# umount /mnt

[root@lvm vagrant]# mount /dev/VolGroup00/LVhome /home

[root@lvm vagrant]# echo "`blkid | grep home | awk '{print $2}'` /home xfs defaults 0 0" >> /etc/fstab
```

Демонстрация работы со снепшотами

```console
[root@lvm vagrant]# ls /home
vagrant

[root@lvm vagrant]# touch /home/file{1..20}

[root@lvm vagrant]# lvcreate -L 100MB -s -n home_snap /dev/VolGroup00/LVhome
  Rounding up size to full physical extent 128.00 MiB
  Logical volume "home_snap" created.

[root@lvm vagrant]# rm -f /home/file{11..20}

[root@lvm vagrant]# ls /home
file1  file10  file2  file3  file4  file5  file6  file7  file8  file9  vagrant

[root@lvm vagrant]# umount /home

[root@lvm vagrant]# lvconvert --merge /dev/VolGroup00/home_snap
  Merging of volume VolGroup00/home_snap started.
  VolGroup00/LVhome: Merged: 100.00%

[root@lvm vagrant]# mount /home

[root@lvm vagrant]# ls /home
file1   file11  file13  file15  file17  file19  file20  file4  file6  file8  vagrant
file10  file12  file14  file16  file18  file2   file3   file5  file7  file9
```

# Эксперименты с zfs

yum -y install http://download.zfsonlinux.org/epel/zfs-release.el7_5.noarch.rpm

Отключаем репо zfs, и включаем zfs-kmod (enabled=*)

```console
[root@lvm vagrant]# cat /etc/yum.repos.d/zfs.repo
[zfs]
name=ZFS on Linux for EL7 - dkms
baseurl=http://download.zfsonlinux.org/epel/7.5/$basearch/
enabled=0
metadata_expire=7d
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-zfsonlinux

[zfs-kmod]
name=ZFS on Linux for EL7 - kmod
baseurl=http://download.zfsonlinux.org/epel/7.5/kmod/$basearch/
enabled=1
metadata_expire=7d
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-zfsonlinux

[root@lvm vagrant]# yum -y install kernel-devel zfs 
[root@lvm vagrant]# echo zfs > /etc/modules.d/zfs.conf
[root@lvm vagrant]# reboot
```

Проверяем наличие загруженного модуля после перезагрузки

```console
[root@lvm vagrant]# lsmod|grep zfs
zfs                  3564468  0
zunicode              331170  1 zfs
zavl                   15236  1 zfs
icp                   270148  1 zfs
zcommon                73440  1 zfs
znvpair                89131  2 zfs,zcommon
spl                   102412  4 icp,zfs,zcommon,znvpair
```

Допустим, /dev/sdb1 - это флеш ssd для ускорения записи. 
/dev/sdb2 - это cache для улучшения чтения, 
/dev/sdb3 и /dev/sdc - это диски под данные.
Разметим /dev/sdb под нашу задачу.

```console
[root@lvm vagrant]# fdisk /dev/sdb
Disk /dev/sdb: 10.7 GB, 10737418240 bytes, 20971520 sectors
Units = sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
Disk label type: gpt
Disk identifier: 37338002-95F9-B24C-9F67-2D8DD54F5831

#         Start          End    Size  Type            Name
 1         2048      2099199      1G  Linux filesyste
 2      2099200      4196351      1G  Linux filesyste
 3      4196352     20971486      8G  Linux filesyste


[root@lvm vagrant]# lsblk
NAME                    MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda                       8:0    0   40G  0 disk
├─sda1                    8:1    0    1M  0 part
├─sda2                    8:2    0    1G  0 part /boot
└─sda3                    8:3    0   39G  0 part
  ├─VolGroup00-LogVol00 253:0    0    8G  0 lvm  /
  ├─VolGroup00-LogVol01 253:1    0  1.5G  0 lvm  [SWAP]
  └─VolGroup00-LVhome   253:2    0    2G  0 lvm  /home
sdb                       8:16   0   10G  0 disk
├─sdb1                    8:17   0    1G  0 part
├─sdb2                    8:18   0    1G  0 part
└─sdb3                    8:19   0    8G  0 part
sdc                       8:32   0    2G  0 disk
sdd                       8:48   0    1G  0 disk
├─VGvar-LVvar_rmeta_0   253:3    0    4M  0 lvm
│ └─VGvar-LVvar         253:7    0  952M  0 lvm  /var
└─VGvar-LVvar_rimage_0  253:4    0  952M  0 lvm
  └─VGvar-LVvar         253:7    0  952M  0 lvm  /var
sde                       8:64   0    1G  0 disk
├─VGvar-LVvar_rmeta_1   253:5    0    4M  0 lvm
│ └─VGvar-LVvar         253:7    0  952M  0 lvm  /var
└─VGvar-LVvar_rimage_1  253:6    0  952M  0 lvm
  └─VGvar-LVvar         253:7    0  952M  0 lvm  /var
```

Создаем пул zpool под данные

```console
[root@lvm vagrant]# zpool create zpool /dev/sdb3 /dev/sdc -f
```

Добавляем к пулу log и cache устройства

```console
[root@lvm vagrant]# zpool add zpool log /dev/sdb1
[root@lvm vagrant]# zpool add zpool cache /dev/sdb2
[root@lvm vagrant]# zpool status
  pool: zpool
 state: ONLINE
  scan: none requested
config:

        NAME        STATE     READ WRITE CKSUM
        zpool       ONLINE       0     0     0
          sdb3      ONLINE       0     0     0
          sdc       ONLINE       0     0     0
        logs
          sdb1      ONLINE       0     0     0
        cache
          sdb2      ONLINE       0     0     0

errors: No known data errors
[root@lvm vagrant]#
```
Создаем файловую систему с набором полезных опций

```console
[root@lvm vagrant]# zfs create -o utf8only=on -o compression=lz4 -o atime=off -o relatime=on zpool/opt
[root@lvm vagrant]# zfs list
NAME        USED  AVAIL  REFER  MOUNTPOINT
zpool       118K  9.61G    24K  /zpool
zpool/opt    24K  9.61G    24K  /zpool/opt
```
Можно монтировать через механизм legacy, если указать дополнительную опцию

```console
[root@lvm vagrant]# mount -t zfs zpool/opt /opt
filesystem 'zpool/opt' cannot be mounted using 'mount'.
Use 'zfs set mountpoint=legacy' or 'zfs mount zpool/opt'.
See zfs(8) for more information.

[root@lvm vagrant]# zfs set mountpoint=legacy zpool/opt
[root@lvm vagrant]# mount -t zfs zpool/opt /opt
[root@lvm vagrant]# df -h
Filesystem                       Size  Used Avail Use% Mounted on
/dev/mapper/VolGroup00-LogVol00  8.0G  901M  7.2G  12% /
devtmpfs                         110M     0  110M   0% /dev
tmpfs                            118M     0  118M   0% /dev/shm
tmpfs                            118M  4.7M  114M   4% /run
tmpfs                            118M     0  118M   0% /sys/fs/cgroup
/dev/sda2                       1014M   61M  954M   6% /boot
/dev/mapper/VolGroup00-LVhome    2.0G   33M  2.0G   2% /home
/dev/mapper/VGvar-LVvar          922M  161M  698M  19% /var
tmpfs                             24M     0   24M   0% /run/user/1000
zpool                            9.7G  128K  9.7G   1% /zpool
tmpfs                             24M     0   24M   0% /run/user/0
zpool/opt                        9.7G  128K  9.7G   1% /opt

[root@lvm vagrant]# touch /opt/file{1..20}
[root@lvm vagrant]# ls /opt
file1  file10  file11  file12  file13  file14  file15  file16  file17  file18  file19  file2  file20  file3  file4  file5  file6  file7  file8  file9
[root@lvm vagrant]# umount /opt
```
А можно монтировать и внутренним механизмом zfs, так и настроим. Заодно и квоту на файловую систему установим

```console
[root@lvm vagrant]# zfs set quota=300M zpool/opt
[root@lvm vagrant]# zfs set mountpoint=/opt zpool/opt
[root@lvm vagrant]# zfs mount
zpool                           /zpool
zpool/opt                       /opt
[root@lvm vagrant]# ls /opt
file1  file10  file11  file12  file13  file14  file15  file16  file17  file18  file19  file2  file20  file3  file4  file5  file6  file7  file8  file9
[root@lvm vagrant]# umount /opt
[root@lvm vagrant]# ls /opt
[root@lvm vagrant]# zfs mount
zpool                           /zpool
[root@lvm vagrant]# zfs mount zpool/opt
[root@lvm vagrant]# ls /opt
file1  file10  file11  file12  file13  file14  file15  file16  file17  file18  file19  file2  file20  file3  file4  file5  file6  file7  file8  file9

[root@lvm vagrant]# df -h
Filesystem                       Size  Used Avail Use% Mounted on
/dev/mapper/VolGroup00-LogVol00  8.0G  901M  7.2G  12% /
devtmpfs                         110M     0  110M   0% /dev
tmpfs                            118M     0  118M   0% /dev/shm
tmpfs                            118M  4.6M  114M   4% /run
tmpfs                            118M     0  118M   0% /sys/fs/cgroup
/dev/sda2                       1014M   61M  954M   6% /boot
/dev/mapper/VolGroup00-LVhome    2.0G   33M  2.0G   2% /home
/dev/mapper/VGvar-LVvar          922M  161M  698M  19% /var
tmpfs                             24M     0   24M   0% /run/user/1000
zpool                            9.7G     0  9.7G   0% /zpool
zpool/opt                        300M  128K  300M   1% /opt
```
Тестируем создание снапшота, удаление некторых файлов и откат на сделанный снапшот

```console
[root@lvm vagrant]# zfs snapshot zpool/opt@test
[root@lvm vagrant]# zfs list -t snapshot
NAME             USED  AVAIL  REFER  MOUNTPOINT
zpool/opt@test     0B      -    28K  -
[root@lvm vagrant]# rm -f /opt/file{11..20}
[root@lvm vagrant]# ls /opt
file1  file10  file2  file3  file4  file5  file6  file7  file8  file9

[root@lvm vagrant]# zfs rollback zpool/opt@test
[root@lvm vagrant]# ls /opt
file1  file10  file11  file12  file13  file14  file15  file16  file17  file18  file19  file2  file20  file3  file4  file5  file6  file7  file8  file9
[root@lvm vagrant]#
```


