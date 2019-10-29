#!/bin/bash
# https://wiki.archlinux.org/index.php/Port_knocking

HOST=$1
shift
for ARG in "$@"
do
  nmap -Pn --host-timeout 100 --max-retries 0 -p $ARG $HOST
done
