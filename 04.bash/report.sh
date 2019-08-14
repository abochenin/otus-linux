#!/bin/sh

log=./nginx_log
lockfile=./report.lock
conf=./report.conf
partlen=0

. $conf


printReport()
{
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

  echo Выборочный анализ ошибок на примере 4** и 5**
  echo -e "\n=== Ошибки 400+ и список URL (первых 10 строк)"
  cat part |awk '($9 ~ /4[0-9][0-9]/)' |awk '{print $7}'

  echo -e "\n=== Ошибки 500+ и список URL (первых 10 строк)"
  cat part |awk '($9 ~ /5[0-9][0-9]/)' |awk '{print $7}'|head -10
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
partlen=`cat part|wc -l`

result=$(
  printReport
)
echo "$result"
saveConf
echo "$result" | mailx -s "Report"  root

#echo sleep 100&& sleep 100

rm -f $lockfile
rm part
