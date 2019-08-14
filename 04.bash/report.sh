#!/bin/bash

log=./nginx_log
lockfile=./read.lock
conf=report.conf
partlen=0

. $conf

#77.37.14.35 - - [04/Jun/2015:03:06:06 +0000] "GET /downloads/product_2 HTTP/1.1" 404 336 "-" "Debian APT-HTTP/1.3 (0.9.7.9)"
#192.133.141.16 - - [04/Jun/2015:03:06:55 +0000] "GET /downloads/product_1 HTTP/1.1" 404 332 "-" "Debian APT-HTTP/1.3 (0.9.7.9)"


printReport()
{
  partlen=`cat part|wc -l`
  #echo partlen=$partlen

  timebegin=`head -1 part | awk '{print $4}' | sed s/\\\[//g`
  timeend=`tail -1 part | awk '{print $4}' | sed s/\\\[//g`

  echo -e "\n=== Анализируемый период ==="
  echo Начинаем со строки $(($skiplines+1)), добавилось строк $partlen
  if [ "$partlen" -eq 0 ] 
  then 
    echo Нет изменений с момента последнего запуска
    exit 
  fi
  echo $timebegin
  echo $timeend


  echo -e "\n=== Самые активные клиенты  ==="
  echo "Запросов	IP_Address"
  cat part |awk '{print $1}' |sort |uniq -c |sort -nr |head -5

  echo -e "\n=== Самые часто запрашиваемые URLs ==="
  echo "Запросов	URL"
  cat part |awk '{print $7}' |sort |uniq -c |sort -nr |head -5

  echo -e "\n=== Список всех кодов возврата за период ==="
  echo "  Число Код_возврата"
  cat part |awk '{print $9}' |sort |uniq -c |sort -nr

  echo Выборочный анализ ошибок на примере 403 и 500
  echo -e "\n=== Ошибка 403 и список URL (первых 10 строк)"
  cat part |awk '($9 ~ /403/)' |awk '{print $7}'

  echo -e "\n=== Ошибка 500 и список URL (первых 10 строк)"
  cat part |awk '($9 ~ /500/)' |awk '{print $7}'|head -10
}

saveConf()
{
  skiplines=$(($skiplines+$partlen+1))
  #echo skiplines=$skiplines, partlen=$partlen
  echo skiplines=$skiplines>$conf
}

getTrap() {
  trapname=$1
  case $trapname in
    EXIT)
      echo EXIT trapped
      ;;
    SIGINT)
      echo SIGINT trapped
      ;;
    SIGHUP)
      echo SIGHUP trapped
      ;;
  esac
  rm -f $lockfile
}
#=== MAIN ===

if [[ -f $lockfile ]]; then
  echo "Скрипт уже запущен! Возможность повторного запуска заблокирована по условиям задачи" >&2
  exit 1
fi

touch $lockfile
trap 'getTrap SIGINT' SIGINT
trap 'getTrap SIGHUP' SIGHUP
trap 'getTrap EXIT' EXIT

cat $log| tail -n +$skiplines >part

result=$(
  printReport
)
saveConf
echo "$result"
echo "$result" | mailx -s "Report"  bochenin

#echo sleep 100&& sleep 100

rm -f $lockfile
rm part
