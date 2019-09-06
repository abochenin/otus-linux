#!/bin/sh

conf=/etc/sysconfig/monitor.conf
partlen=0

source $conf


printReport()
{
#  echo -e "\n=== Анализируемый период ==="
  echo Начинаем со строки $(($skiplines+1)), добавилось строк $partlen
  if [ "$partlen" -eq 0 ] 
  then 
    echo Нет изменений с момента последнего запуска
    exit 
  fi

  if grep $monitor part.tmp >/dev/null; then
#    echo "*** Ключевое слово найдено! ***"
    logger "Ключевое слово найдено!"
  fi
}

saveConf()
{
  skiplines=$(($skiplines+$partlen))
#  echo skiplines=$skiplines, partlen=$partlen
  sed "s/skiplines=.*/skiplines=$skiplines/g" $conf >$conf.tmp
  mv -f $conf.tmp $conf
}

#=== MAIN ===


cat $log| tail -n +$(($skiplines+1)) >part.tmp
partlen=`cat part.tmp|wc -l`

result=$(
  printReport
)
echo "$result"
saveConf

rm part.tmp

