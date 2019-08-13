#!/bin/bash

source read.conf
log=./access.log

#77.37.14.35 - - [04/Jun/2015:03:06:06 +0000] "GET /downloads/product_2 HTTP/1.1" 404 336 "-" "Debian APT-HTTP/1.3 (0.9.7.9)"
#192.133.141.16 - - [04/Jun/2015:03:06:55 +0000] "GET /downloads/product_1 HTTP/1.1" 404 332 "-" "Debian APT-HTTP/1.3 (0.9.7.9)"

partlen=0

printReport()
{
partlen=`cat part|wc -l`
#echo partlen=$partlen

timebegin=`head -1 part | awk '{print $4}' | sed s/\\\[//g`
timeend=`tail -1 part | awk '{print $4}' | sed s/\\\[//g`

echo
echo === Анализируемый период ===
echo Начинаем со строки $(($skiplines+1)), добавилось строк $partlen
echo $timebegin
echo $timeend

echo
echo === Самые активные клиенты  ===
echo "Запросов	IP_Address"
cat part |awk '{print $1}' |sort |uniq -c |sort -nr |head -5

echo
echo === Самые часто запрашиваемые URLs ===
echo "Запросов	URL"
cat part |awk '{print $7}' |sort |uniq -c |sort -nr |head -5

echo 
echo === Список всех кодов возврата за период ===
echo "  Число Код_возврата"
cat part |awk '{print $9}' |sort |uniq -c |sort -nr

echo
echo Выборочный анализ ошибок на примере 403 и 500
echo
echo "=== Ошибка 403 и список URL (первых 10 строк)"
cat part |awk '($9 ~ /403/)' |awk '{print $7}'

echo
echo "=== Ошибка 500 и список URL (первых 10 строк)"
cat part |awk '($9 ~ /500/)' |awk '{print $7}'|head -10

}

saveConf()
{
  skiplines=$(($skiplines+$partlen+1))
  #echo skiplines=$skiplines, partlen=$partlen
  echo skiplines=$skiplines>read.conf
}

#MAIN
cat $log| tail -n +$skiplines >part
printReport
saveConf



