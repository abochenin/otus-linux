#!/bin/sh

source=./big_nginx_log
destination=./nginx_log

. ./log_maker_daemon.conf

while true; do
  partlen=$((30+$RANDOM*70/32767))
#  echo skiplines=$skiplines, partlen=$partlen

  cat $source| tail -n +$skiplines | head -$partlen |tee -a $destination

  skiplines=$(($skiplines+$partlen))
  echo skiplines=$skiplines>log_maker_daemon.conf

  sleep 5
done


