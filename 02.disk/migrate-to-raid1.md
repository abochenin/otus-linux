# ������ �� raid1 centos7


#����� ���䨣���� � ��砫쭮� ���ﭨ�
[root@otuslinux vagrant]# lsblk
NAME   MAJ:MIN RM SIZE RO TYPE MOUNTPOINT
sda      8:0    0  40G  0 disk
??sda1   8:1    0  40G  0 part /
sdb      8:16   0  40G  0 disk

[root@otuslinux vagrant]# lshw -short|grep disk
/0/100/1.1/0.0.0    /dev/sda   disk        42GB VBOX HARDDISK
/0/100/1.1/0.1.0    /dev/sdb   disk        42GB VBOX HARDDISK


# �����砥� /dev/sdb
[root@otuslinux vagrant]# sfdisk -d /dev/sda |sfdisk /dev/sdb


# ���塞 ⨯ ࠧ���� �� FD, linux raid � ������� fdisk ��� parted
Disk /dev/sdb: 42.9 GB, 42949672960 bytes, 83886080 sectors
Units = sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
Disk label type: dos
Disk identifier: 0x00000000

   Device Boot      Start         End      Blocks   Id  System
/dev/sdb1   *        2048    83886079    41942016   fd  Linux raid autodetect

Command (m for help): w
The partition table has been altered!


# ������� ��ઠ�� ��� ������ ����� (missing)
[root@otuslinux vagrant]# mdadm --create /dev/md0 --level=1 --raid-devices=2 missing /dev/sdb1
mdadm: Note: this array has metadata at the start and
    may not be suitable as a boot device.  If you plan to
    store '/boot' on this device please ensure that
    your boot-loader understands md/v1.x metadata, or use
    --metadata=0.90
Continue creating array? y
mdadm: Defaulting to version 1.2 metadata
mdadm: array /dev/md0 started.


# � ࠧ��砥� 䠩����� ��⥬�
[root@otuslinux vagrant]# mkfs.xfs /dev/md0
meta-data=/dev/md0               isize=512    agcount=4, agsize=2619264 blks
         =                       sectsz=512   attr=2, projid32bit=1
         =                       crc=1        finobt=0, sparse=0
data     =                       bsize=4096   blocks=10477056, imaxpct=25
         =                       sunit=0      swidth=0 blks
naming   =version 2              bsize=4096   ascii-ci=0 ftype=1
log      =internal log           bsize=4096   blocks=5115, version=2
         =                       sectsz=512   sunit=0 blks, lazy-count=1
realtime =none                   extsz=4096   blocks=0, rtextents=0

# �����㥬 � �����㥬
[root@otuslinux vagrant]# mount /dev/md0 /mnt
[root@otuslinux vagrant]# rsync -PavHxAX --exclude /dev --exclude /proc --exclude /sys --exclude /run --exclude /mnt / /mnt
...
sent 2,969,242,396 bytes  received 810,129 bytes  77,144,221.43 bytes/sec
total size is 2,978,195,530  speedup is 1.00


# ᮧ���� �ய�饭�� ��४�ਨ
[root@otuslinux vagrant]# for a in dev sys proc run mnt; do mkdir /mnt/$a; done


# �����㥬 ᯥ樠��� 䠩����  ��⥬� � ���⨬��
[root@otuslinux vagrant]# for a in dev sys proc ; do mount --bind /$a /mnt/$a; done
[root@otuslinux vagrant]# chroot /mnt

# �ࠢ�� /etc/fsta, �⮡� ��७� ��뫫�� �� �ࢨ��� uuid
[root@otuslinux /]# blkid
/dev/sda1: UUID="8ac075e3-1124-4bb6-bef7-a6811bf8b870" TYPE="xfs"
/dev/sdb1: UUID="ef4c7b73-73bf-4089-cd28-645a0cc68564" UUID_SUB="58cd6d36-2490-0976-65b3-4f5a3c7f493e" LABEL="otuslinux:0" TYPE="linux_raid_member"
/dev/md0: UUID="121bcded-cac4-4076-a720-4e5daf5b1cb3" TYPE="xfs"
[root@otuslinux /]# grep xfs /etc/fstab
UUID=121bcded-cac4-4076-a720-4e5daf5b1cb3 /                       xfs     defaults        0 0


# ᮧ���� ���䨣���� mdadm
[root@otuslinux /]# mdadm --detail --scan
ARRAY /dev/md0 metadata=1.2 name=otuslinux:0 UUID=ef4c7b73:73bf4089:cd28645a:0cc68564
[root@otuslinux /]# mdadm --detail --scan > /etc/mdadm.conf

# ������� ���� � ᮧ���� ���� ����ࠬ��, �஢��塞 �� ����� mdraid ����� � ��ࠧ
[root@otuslinux /]# ls /boot/init*
/boot/initramfs-3.10.0-957.12.2.el7.x86_64.img
[root@otuslinux /]# cp /boot/initramfs-3.10.0-957.12.2.el7.x86_64.img /boot/initramfs-3.10.0-957.12.2.el7.x86_64.img.backup
[root@otuslinux /]# dracut --force -M
bash
nss-softokn
i18n
kernel-modules
mdraid
qemu
rootfs-block
terminfo
udev-rules
biosdevname
systemd
usrmount
base
fs-lib
shutdown


# ������塞 rd.auto=1 � ��ࠬ���� ����᪠ �����稪�
[root@otuslinux /]# vi /etc/default/grub
GRUB_CMDLINE_LINUX="no_timer_check console=tty0 console=ttyS0,115200n8 net.ifnames=0 biosdevname=0 elevator=noop cr
ashkernel=auto rd.auto=1"


# ������塞 ���䨣���� grub
[root@otuslinux /]# grub2-mkconfig -o /boot/grub2/grub.cfg
Generating grub configuration file ...
/usr/sbin/grub2-probe: warning: Couldn't find physical volume `(null)'. Some modules may be missing from core image..
Found linux image: /boot/vmlinuz-3.10.0-957.12.2.el7.x86_64
Found initrd image: /boot/initramfs-3.10.0-957.12.2.el7.x86_64.img
/usr/sbin/grub2-probe: warning: Couldn't find physical volume `(null)'. Some modules may be missing from core image..
/usr/sbin/grub2-probe: warning: Couldn't find physical volume `(null)'. Some modules may be missing from core image..
/usr/sbin/grub2-probe: warning: Couldn't find physical volume `(null)'. Some modules may be missing from core image..
/usr/sbin/grub2-probe: warning: Couldn't find physical volume `(null)'. Some modules may be missing from core image..
done

# � ���⠫��㥬 �����稪 �� ��ன ���
[root@otuslinux /]# grub2-install /dev/sdb
Installing for i386-pc platform.
grub2-install: warning: Couldn't find physical volume `(null)'. Some modules may be missing from core image..
grub2-install: warning: Couldn't find physical volume `(null)'. Some modules may be missing from core image..
Installation finished. No error reported.

# �����! ��� � ����� ����� �६���. �᫨ ��ॣ�㧨���� ᥩ�� � ����㧨�� ����㠫�� � ��ண� ��᪠, �
# �� ��㧨���, ��⥬� ���� ������� �ਣ�襭�� login:, �� ���ਧ��� ��� ���짮��⥫�� �㤥� ��㤠筮�
# ���� �� ssh ����������, � ⮬ �᫥ �� ���砬. ��稭� ��������� � SELINUX, ���⮬�

# �⪫�砥� selinux
[root@otuslinux /]# grep SELINUX= /etc/selinux/config
# SELINUX= can take one of these three values:
SELINUX=disabled


#  � ⥯��� ��ॣ�㦠�� ����㠫��, ��ࠢ � virtualbox ����㧪� � Slave ��᪠.
# ��᫥ �ᯥ譮� ����㧪� �த������.  ��� ��᪠ /dev/sda ���塞 ��� ⨯ �� FD raid autodetect
#
[root@otuslinux vagrant]# fdisk /dev/sda
   Device Boot      Start         End      Blocks   Id  System
/dev/sda1   *        2048    83886079    41942016   fd  Linux raid autodetect


# ������塞 ���� ���, ��� ����� ��ઠ��
[root@otuslinux vagrant]# mdadm --manage /dev/md0 --add /dev/sda1
mdadm: added /dev/sda1


# � ������ ��� ���� ����� ᨭ�஭���樨
[root@otuslinux vagrant]# cat /proc/mdstat
Personalities : [raid1]
md0 : active raid1 sda1[2] sdb1[1]
      41908224 blocks super 1.2 [2/1] [_U]
      [>....................]  recovery =  2.7% (1142400/41908224) finish=2.9min speed=228480K/sec

unused devices: <none>
[root@otuslinux vagrant]#

# ��⠫��� ��⠭����� �����稪
[root@otuslinux vagrant]# grub2-install /dev/sda
Installing for i386-pc platform.
grub2-install: warning: Couldn't find physical volume `(null)'. Some modules may be missing from core image..
grub2-install: warning: Couldn't find physical volume `(null)'. Some modules may be missing from core image..
Installation finished. No error reported.


# � ����� �襭�. �⮣���� ���ﭨ�
[root@otuslinux vagrant]# lsblk
NAME    MAJ:MIN RM SIZE RO TYPE  MOUNTPOINT
sda       8:0    0  40G  0 disk
??sda1    8:1    0  40G  0 part
  ??md0   9:0    0  40G  0 raid1 /
sdb       8:16   0  40G  0 disk
??sdb1    8:17   0  40G  0 part
  ??md0   9:0    0  40G  0 raid1 /
[root@otuslinux vagrant]#

