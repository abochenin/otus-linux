#!/usr/bin/env bash

if id -Gn $PAM_USER | grep -w admin >/dev/null; then
  exit 0
fi

if [[ `date +%u` -gt 5 ]]; then
  exit 1
else
  exit 0
fi
