#!/bin/sh

(time nice -n +19 dd if=/dev/urandom of=/dev/null count=1000 bs=1M >/dev/null 2>&1) >cpu1.log 2>&1 &
echo thread 1 started
(time nice -n -19 dd if=/dev/urandom of=/dev/null count=1000 bs=1M >/dev/null 2>&1) >cpu2.log 2>&1 &
echo thread 2 started

while [ `ps -ef|grep dd\ if|grep -v grep|wc -l` -ne 0 ]; do
  ps -ef|grep dd\ if|grep -v grep
  echo
  sleep 1
done

echo -e "\nПониженный приоритет:"
cat cpu1.log

echo -e "\nПовышенный приоритет:"
cat cpu2.log

rm -f cpu{1,2}.log
