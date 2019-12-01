## Домашнее задание 28.mysql
развернуть базу из дампа и настроить репликацию
В материалах приложены ссылки на вагрант для репликации
и дамп базы bet.dmp
базу развернуть на мастере
и настроить чтобы реплицировались таблицы
| bookmaker |
| competition |
| market |
| odds |
| outcome

* Настроить GTID репликацию

варианты которые принимаются к сдаче
- рабочий вагрантафайл
- скрины или логи SHOW TABLES
* конфиги
* пример в логе изменения строки и появления строки на реплике 

## Проверки

Для удобства занесем пароль mysql в файл
```bash
[vagrant@master ~]$ cat ~/.my.cnf
[client]
user=root
password=P@ssw0rd
```

Видно что репликация работает, gtid работает и игнорятся таблички по заданию
```bash
slave mysql> SHOW SLAVE STATUS\G
*************************** 1. row ***************************
               Slave_IO_State: Waiting for master to send event
                  Master_Host: 192.168.11.150
                  Master_User: repl
                  Master_Port: 3306
                Connect_Retry: 60
              Master_Log_File: mysql-bin.000002
          Read_Master_Log_Pos: 593564
               Relay_Log_File: slave-relay-bin.000002
                Relay_Log_Pos: 593777
        Relay_Master_Log_File: mysql-bin.000002
             Slave_IO_Running: Yes
            Slave_SQL_Running: Yes
              Replicate_Do_DB:
          Replicate_Ignore_DB:
           Replicate_Do_Table:
       Replicate_Ignore_Table: bet.events_on_demand,bet.v_same_event
```

Проверим репликацию в действии. На мастере

```bash
master mysql> use bet;
Reading table information for completion of table and column names
You can turn off this feature to get a quicker startup with -A

Database changed
mysql> INSERT INTO bookmaker (id,bookmaker_name) VALUES(1,'1xbet');
Query OK, 1 row affected (0.01 sec)

mysql>  SELECT * FROM bookmaker;
+----+----------------+
| id | bookmaker_name |
+----+----------------+
|  1 | 1xbet          |
|  4 | betway         |
|  5 | bwin           |
|  6 | ladbrokes      |
|  3 | unibet         |
+----+----------------+
5 rows in set (0.00 sec)
```

На слейве:

```bash
slave mysql> SELECT * FROM bookmaker;
+----+----------------+
| id | bookmaker_name |
+----+----------------+
|  1 | 1xbet          |
|  4 | betway         |
|  5 | bwin           |
|  6 | ladbrokes      |
|  3 | unibet         |
+----+----------------+
5 rows in set (0.00 sec)
```


В binlog-ах на cлейве также видно последнее изменение, туда же он пишет информацию о GTID:
(в миднайт командере в режиме просмотра бинарного файла можно увидеть команды)
```bash
..].....u...X.....!.......... .................std.!.!.....bet.bet./*!40000 ALTER TABLE `outcome` ENABLE
KEYS */J......]!....A............У...ꮭRT..............................v.....].....G.........!............
................std.!.!...bet.BEGIN..$b...].....H...(.....!............................std.!.!...bet.COMM
IT.3V....]!....A...i........У...ꮭRT.............................j+.....].....G.........!.................
...........std.!.!...bet.BEGIN,.}....].....H.........!............................std.!.!...bet.COMMIT@5.
5...]!....A...9........У...ꮭRT.............................;.   E...].....G.........!....................
........std.!.!...bet.BEGIN͵J....].....H...ț....!............................std.!.!...bet.COMMIT.Р....]!
....A...        ........У...ꮭRT...............................47...].....G...P.....!.....................
.......std.!.!...bet.BEGIN.......].....H.........!............................std.!.!...bet.COMMIT?^.F...
]!....A..........У...ꮭRT..............................]M....].....G... .....!............................
std.!.!...bet.BEGIN.......].....H...h.....!............................std.!.!...bet.COMMITZ..|...]!....A
............У...ꮭRT.............................x0.....].....I.........$.................. ..U......std..
.......bet.BEGINYg.....].........q.....$.................. ..U......std.........bet.INSERT INTO bookmaker
 (id,bookmaker_name) VALUES(1,'1xbet')G._....].......................:.A.
```

Или специальной утилитой
```bash
[root@slave mysql]# mysqlbinlog ./mysql-bin.000002 |tail -30
# at 564512
#191201 17:18:19 server id 1  end_log_pos 564584 CRC32 0x7cff865a       Query   thread_id=33    exec_time=0      error_code=0
SET TIMESTAMP=1575220699/*!*/;
COMMIT
/*!*/;
# at 564584
#191201 17:27:25 server id 1  end_log_pos 564649 CRC32 0x06873078       GTID    last_committed=181      sequence_number=182      rbr_only=no
SET @@SESSION.GTID_NEXT= 'a1f7d0a3-13b6-11ea-aead-5254008afee6:181'/*!*/;
# at 564649
#191201 17:27:25 server id 1  end_log_pos 564722 CRC32 0xd8806759       Query   thread_id=36    exec_time=0      error_code=0
SET TIMESTAMP=1575221245/*!*/;
SET @@session.foreign_key_checks=1, @@session.unique_checks=1/*!*/;
SET @@session.sql_mode=1436549152/*!*/;
/*!\C latin1 *//*!*/;
SET @@session.character_set_client=8,@@session.collation_connection=8,@@session.collation_server=8/*!*/;
BEGIN
/*!*/;
# at 564722
#191201 17:27:25 server id 1  end_log_pos 564849 CRC32 0xc65fbf47       Query   thread_id=36    exec_time=0      error_code=0
SET TIMESTAMP=1575221245/*!*/;
INSERT INTO bookmaker (id,bookmaker_name) VALUES(1,'1xbet')
/*!*/;
# at 564849
#191201 17:27:25 server id 1  end_log_pos 564880 CRC32 0x8f41d43a       Xid = 235
COMMIT/*!*/;
SET @@SESSION.GTID_NEXT= 'AUTOMATIC' /* added by mysqlbinlog */ /*!*/;
DELIMITER ;
# End of log file
/*!50003 SET COMPLETION_TYPE=@OLD_COMPLETION_TYPE*/;
/*!50530 SET @@SESSION.PSEUDO_SLAVE_MODE=0*/;
```
