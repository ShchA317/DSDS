# Лабораторная работа №2

## Задание

Цель работы - на выделенном узле создать и сконфигурировать новый кластер БД Postgres, саму БД, табличные пространства и новую роль, а также произвести наполнение базы в соответствии с заданием. Отчёт по работе должен содержать все команды по настройке, скрипты, а также измененные строки конфигурационных файлов. Способ подключения к узлу из сети Интернет через helios: ssh -J sXXXXXX@helios.cs.ifmo.ru:2222 postgresY@pgZZZ Способ подключения к узлу из сети факультета: ssh postgresY@pgZZZ Номер выделенного узла pgZZZ, а также логин и пароль для подключения Вам выдаст преподаватель.

Обратите внимание, что домашняя директория пользователя /var/postgres/$LOGNAME

### Этап 1. Инициализация кластера БД

    Директория кластера: $HOME/unb63
    Кодировка: ANSI1251
    Локаль: русская
    Параметры инициализации задать через аргументы команды

### Этап 2. Конфигурация и запуск сервера БД

    Способ подключения: сокет TCP/IP, только localhost

    Номер порта: 9144

    Остальные способы подключений запретить.

    Способ аутентификации клиентов: по паролю в открытом виде

    Настроить следующие параметры сервера БД:
       - max_connections
       - shared_buffers
       - temp_buffers
       - work_mem
       - checkpoint_timeout
       - effective_cache_size
       - fsync
       - commit_delay

    Параметры должны быть подобраны в соответствии с аппаратной конфигурацией:

     - оперативная память 2ГБ
     - хранение на твердотельном накопителе (SSD)

    Директория WAL файлов: $HOME/uxc31

    Формат лог-файлов: .log

    Уровень сообщений лога: ERROR

    Дополнительно логировать: попытки подключения и завершение сессий

### Этап 3. Дополнительные табличные пространства и наполнение базы

    Создать новые табличные пространства для различных таблиц: $HOME/tym66, $HOME/fwb3, $HOME/raz87
    На основе template1 создать новую базу: illpinkexam
    Создать новую роль, предоставить необходимые права, разрешить подключение к базе.
    От имени новой роли (не администратора) произвести наполнение ВСЕХ созданных баз тестовыми наборами данных. ВСЕ табличные пространства должны использоваться по - назначению.
    Вывести список всех табличных пространств кластера и содержащиеся в них объекты.

### Вопросы для подготовки к защите

    Способы запуска и остановки сервера PosgreSQL, их отличия.
    Какие параметры локали сервера БД можно настроить? На что они влияют? Как и где их переопределить?
    Конфигурационные файлы сервера. Способы изменения и применения конфигурации.
    Что такое табличное пространство? Зачем нужны дополнительные табличные пространства?
    Зачем нужны template0 и template1?
    OLTP vs OLAP.
    Роли и права доступа.

## Выполнение

### Этап 1:

создание кластера и запуск:

```bash
initdb --locale=ru_RU.CP1251 -D unb63/ --username=postgres1 -E WIN1251
pg_ctl -D /var/db/postgres1/unb63/ -l logfile start
```

### Этап 2:

файл `pg_hba.conf`:

```
# TYPE  DATABASE        USER            ADDRESS                 METHOD

# "local" is for Unix domain socket connections only
# local   all             all                                     trust
# IPv4 local connections:

host    all             all             127.0.0.1/32           password

# IPv6 local connections:
# host    all             all             ::1/128                 trust
# Allow replication connections from localhost, by a user with the
# replication privilege.
#local   replication     all                                     trust
#host    replication     all             127.0.0.1/32            trust
#host    replication     all             ::1/128                 trust

```

все, что явным образом не разрешено, то запрещено. поэтому все способы подключения кроме локального хоста по IPv4 закоменчены

измененные параметры в `postgresql.conf`:

```
listen_addresses = 'localhost'
port = 9144
max_connections = 21

shared_buffers = 512MB 
temp_buffers = 16MB
work_mem = 8MB
checkpoint_timeout = 50min
effective_cache_size = 1GB # 1/2 всего объема
fsync = on # супер-надежный и быстрый ssd
commit_delay = 1 # не много не мало

log_min_messages = error
log_connections = on
log_disconnections = on
```

#### Пояснение по каждому из параметров


- max_connections
    - Определяет максимальное количество одновременных соединений
    - устанавливать в соответсвии с клиентской нагрухкой на БД и лучше выяснять эмпирически
- shared_buffers
    - размер выделенной оперативной памяти для кэширования данных в памяти
    - PostrgesPro [реккомендуют](https://postgrespro.ru/docs/postgrespro/9.5/runtime-config-resource#guc-shared-buffers) ставить 25% - 40% ОЗУ. 
- temp_buffers
    - максимальное число временных буферов для каждого сеанса
    - Если сеанс не задействует временные буферы, то для него хранятся только дескрипторы буферов, которые занимают около 64 байт
    - по умолчанию 8МБ (1024 буффера), но так как мы ограничили нагрузку параметром `max_connections`, можно удвоить этот объем.
- work_mem
    - Объём памяти, для внутренних операций сортировки и хеш-таблиц, до того как будут задействованы временные файлы на диске
    - по умолчанию 4МБ, но так как мы ограничили нагрузку параметром `max_connections`, можно удвоить этот объем.
- checkpoint_timeout
    - Максимальное время между автоматическими контрольными точками в WAL (в секундах)
    - Влияет на скорость восстановления после сбоя.
    - Предположим, что мы можем себе позволить восстанавливаться очень долго и ставим значеие параметра в 10 раз больше значения по умолчанию (10 * 5min = 50min)
- effective_cache_size
    - чем выше это значение, тем больше вероятность, что будет применяться сканирование по индексу, чем ниже, тем более вероятно, что будет выбрано последовательное сканирование.
    - не влияет на размер разделяемой памяти. Используется только в качестве ориентировочной оценки
- fsync
    - сервер PostgreSQL старается добиться, чтобы изменения были записаны на диск физически, выполняя системные вызовы fsync() или другими подобными методами
    - предположим, что у нас супер-крутой SSD и вообще нам нравятся данные на диске, т.к. боимся отключения света
- commit_delay
    - Параметр commit_delay добавляет паузу (в микросекундах) перед собственно выполнением сохранения WAL


### Этап 3:

```
mkdir tym66 fwb3 raz87
createdb -T template1 illpinkexam -p 9144
psql -U postgres1 -d illpinkexam -p 9144 -h 127.0.0.1
```

в psql:

```sql
CREATE TABLESPACE tym66 LOCATION '/var/db/postgres1/tym66';
CREATE TABLESPACE fwb3 LOCATION '/var/db/postgres1/fwb3';
CREATE TABLESPACE raz87 LOCATION '/var/db/postgres1/raz87';

CREATE ROLE illpinkexam1 WITH LOGIN PASSWORD '123456';
GRANT ALL PRIVILEGES ON DATABASE illpinkexam TO illpinkexam1;

GRANT ALL PRIVILEGES ON TABLESPACE tym66 TO illpinkexam1;
GRANT ALL PRIVILEGES ON TABLESPACE fwb3 TO illpinkexam1;
GRANT ALL PRIVILEGES ON TABLESPACE raz87 TO illpinkexam1;
```

залогившись под illpinkexam1: 

```sql
CREATE TABLE tym66_table (id INT, name VARCHAR(255)) TABLESPACE tym66;
CREATE TABLE fwb3_table (id INT, description VARCHAR(255)) TABLESPACE fwb3;
CREATE TABLE raz87_table (id INT, data BYTEA) TABLESPACE raz87;

-- Tym66_table
INSERT INTO tym66_table (id, name) VALUES (1, 'Test 1');
INSERT INTO tym66_table (id, name) VALUES (2, 'Test 2');
INSERT INTO tym66_table (id, name) VALUES (3, 'Test 3');

-- Fwb3_table
INSERT INTO fwb3_table (id, description) VALUES (1, 'Description 1');
INSERT INTO fwb3_table (id, description) VALUES (2, 'Description 2');
INSERT INTO fwb3_table (id, description) VALUES (3, 'Description 3');

-- Raz87_table
INSERT INTO raz87_table (id, data) VALUES (1, E'Data 1');
INSERT INTO raz87_table (id, data) VALUES (2, E'Data 2');
INSERT INTO raz87_table (id, data) VALUES (3, E'Data 3');
```

проверяем, что в данные вставлены: 

```sql
SELECT * FROM tym66_table;
SELECT * FROM fwb3_table;
SELECT * FROM raz87_table;
```

```
 id |  name  
----+--------
  1 | Test 1
  2 | Test 2
  3 | Test 3
(3 строки)

 id |  description  
----+---------------
  1 | Description 1
  2 | Description 2
  3 | Description 3
(3 строки)

 id |      data      
----+----------------
  1 | \x446174612031
  2 | \x446174612032
  3 | \x446174612033

```

вывести таблицы и пользовательские пространства можно при помощи запроса:

```
select pc.relname, spcname
from pg_class pc
    join pg_tablespace pt on pt.oid=pc.reltablespace
where spcname in ('tym66', 'raz87', 'fwb3'); 
```

полученное отношение 

```
       relname        | spcname 
----------------------+---------
 tym66_table          | tym66
 fwb3_table           | fwb3
 pg_toast_16402       | raz87
 pg_toast_16402_index | raz87
 raz87_table          | raz87
```


