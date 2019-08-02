#!/usr/bin/sh

mdadm --zero-superblock --force /dev/sd{b,c,d,e,f}
mdadm --create --verbose /dev/md1 -l 10 -n 4 /dev/sd{b,c,d,e}
mdadm --add /dev/md1 /dev/sdf
cat /proc/mdstat
mdadm -D /dev/md1

mkdir -p /etc/mdadm
echo "DEVICE partitions" > /etc/mdadm/mdadm.conf
mdadm --detail --scan --verbose | grep ARRAY >> /etc/mdadm/mdadm.conf

