#!/bin/bash

source=big-access.log
destination=access.log

. log_maker_daemon.conf

while true; do
  partlen=$((3+$RANDOM*7/32767))
#  echo skiplines=$skiplines, partlen=$partlen

  cat $source| tail -n +$skiplines | head -$partlen |tee -a $destination

  skiplines=$(($skiplines+$partlen))
  echo skiplines=$skiplines>log_maker_daemon.conf

  sleep 5
done


