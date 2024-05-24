# Лабораторная работа №3 (вариант 33146)

доступ на узел 1 (с гелиоса):
`ssh postgres1@pg155` - далее "Основной узел"

доступ на узел 2 (с гелиоса): 
`ssh postgres2@pg192` - далее "Резервный узел"

## Этап 1. Резервное копирование

Настроить резервное копирование с основного узла на резервный следующим образом:
Периодические полные копии с помощью SQL Dump.
По расписанию (cron) раз в сутки, методом SQL Dump с сжатием. 
Созданные архивы должны сразу перемещаться на резервный хост, они не должны храниться на основной системе. 
Срок хранения архивов на резервной системе - 4 недели. 
По истечении срока хранения, старые архивы должны автоматически уничтожаться.

Подсчитать, каков будет объем резервных копий спустя месяц работы системы, исходя из следующих условий:
Средний объем новых данных в БД за сутки: `800МБ`.
Средний объем измененных данных за сутки: `750МБ`.  
Проанализировать результаты.


### Выполнение

убедимся в доступности второго узла с первого:

для этого выполним на оснвном узле (pg155) команду:

```shell
ssh postgres2@pg192
```

а затем закроем ссессию.

сразу сгенерируем ssh-ключ для возможности подключаться без пароля

```shell
ssh-keygen -t rsa
ssh-copy-id -i ~/.ssh/id_rsa.pub postgres2@pg192
```

теперь напишем команду для создания бэкапов, их сжатия и выгрузки полученых архивов на резервный хост:

в файл `scripts/backup.sh`:
```shell
current_date=$(date +"%Y-%m-%d")
current_time=$(date +"%H-%M-%S")
backup_file="/var/db/postgres2/backups/backup_${current_date}_${current_time}.sql.gz"
scp /var/db/postgres1/unb63 postgres2@192:backups
pg_dump -U postgres1 -d illpinkexam -p 9144 | gzip | ssh postgres2@pg192 "cat > $backup_file"
```

в `crontab -e` вставляем строку 

```cronexp
3 4 * * * /var/db/postgres1/scripts/backup.sh
```

а на резервном узле установим в `crontab` следующее:

```cronexp
0 0 * * * find /var/db/postgres2/backups -type f -mtime +28 -exec rm {} \;
```

Средний объём новых данных в БД за сутки: `800 МБ`  
Средний объём изменённых данных за сутки: `750 МБ`  
Размер полной резервной копии: 800 МБ + 750 МБ = `1 550 МБ`

Объём резервных копий за месяц: 1 550 * 30 = `46 500 МБ`


## Этап 2. Резервное копирование

```shell
initdb --locale=ru_RU.CP1251 -D unb63/ --username=postgres2 -E WIN1251
pg_ctl -D ~/unb63/ -l logfile start
latest_backup=$(ls -t /var/db/postgres2/backups/*.sql.gz | head -1)
gunzip -c $latest_backup > ~/script.sql
psql -f script.sql -U postgres2 -d illpinkexam
```


## Этап 3

```shell
scp postgres2@192:backups/unb63 /var/db/postgres1/unb63
ssh postgres2@192
latest_backup=$(ls -t /var/db/postgres2/backups/*.sql.gz | head -1) && exit
scp postgres2@192:latest_backup script.sql.gz
gunzip -c $latest_backup > ~/script.sql
```

## Этап 4

добавим внешние ключи и ненмого данных 

```sql
ALTER TABLE tym66_table ADD COLUMN fwb3_id INT;

-- Updating existing records with appropriate fwb3_id values
UPDATE tym66_table SET fwb3_id = 1 WHERE id = 1;
UPDATE tym66_table SET fwb3_id = 2 WHERE id = 2;
UPDATE tym66_table SET fwb3_id = 3 WHERE id = 3;

-- Adding the foreign key constraint
ALTER TABLE tym66_table 
ADD CONSTRAINT fk_fwb3
FOREIGN KEY (fwb3_id) REFERENCES fwb3_table(id);


INSERT INTO tym66_table (id, name, fwb3_id) VALUES (4, 'Test 4', 1);
INSERT INTO tym66_table (id, name, fwb3_id) VALUES (5, 'Test 5', 2);
INSERT INTO tym66_table (id, name, fwb3_id) VALUES (6, 'Test 6', 3);

INSERT INTO fwb3_table (id, description) VALUES (4, 'Description 4');
INSERT INTO fwb3_table (id, description) VALUES (5, 'Description 5');
INSERT INTO fwb3_table (id, description) VALUES (6, 'Description 6');
```

не дожидаясь отработки крона закидываем бэкап (скрипт из первого этапа), затем "ломаем":

```sql
SELECT NOW() AS current_time;
UPDATE tym66_table SET fwb3_id = 999 WHERE id = 4;
INSERT INTO tym66_table (id, name, fwb3_id) VALUES (7, 'Test 7', 999);
``` 

```                                     
wal_level = replica
archive_mode = on

archive_command = 'scp %p postgres2@pg192:/var/db/postgres2/wal_backup/%f'
```

восстанавливаем бд из резервной копии. в :

```
wal_level = replica
archive_mode = on
archive_command = 'scp %p postgres2@pg192:/var/db/postgres2/wal_backup/%f'
```

