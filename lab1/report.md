# Отчет по лабораторной работе №1

выполнил: Щербаков Александр \
группа: P33151 \
преподаватель: Перцев Тимофей

### задание

Используя сведения из системных каталогов получить информацию о любой таблице: Номер по порядку, Имя столбца, Атрибуты (в атрибуты столбца включить тип данных, ограничение типа CHECK).

### полученная функция

```postgresql
CREATE OR REPLACE PROCEDURE table_columns_info(t text, schema text) AS $$
DECLARE
    new_tab CURSOR FOR (
        SELECT tab.relname,
               attr.attrelid,
               attr.attnum,
               attr.attname,
               attr.attnotnull,
               typ.typname,
               des.description,
               attr.atttypmod,
               constr.conname,
               pg_get_constraintdef(constr.oid) AS constraint_definition
        FROM pg_class tab
                 JOIN pg_namespace space on tab.relnamespace = space.oid
                 JOIN pg_attribute attr on attr.attrelid = tab.oid
                 JOIN pg_type typ on attr.atttypid = typ.oid
                 LEFT JOIN pg_catalog.pg_constraint constr ON attr.attrelid = constr.conrelid
            AND attr.attnum = ANY(constr.conkey)
                 LEFT JOIN pg_description des on des.objoid = tab.oid and des.objsubid = attr.attnum
        WHERE tab.relname = t and attnum > 0 and space.nspname = schema
        ORDER BY attnum
    );
    table_count int;
BEGIN
    SELECT COUNT(DISTINCT nspname) INTO table_count FROM pg_class tab JOIN pg_namespace space on tab.relnamespace = space.oid WHERE relname = t and space.nspname = schema;

    IF table_count < 1 THEN
        RAISE EXCEPTION 'Таблица "%" не найдена в схеме "%"!', t, schema;
    ELSE
        RAISE NOTICE ' ';
        RAISE NOTICE 'Таблица: %', t;
        RAISE NOTICE ' ';
        RAISE NOTICE 'No.  Имя столбца      Атрибуты';
        RAISE NOTICE '---  --------------   -------------------------------------------------';

        FOR col in new_tab
            LOOP
                IF col.atttypmod != -1 then
                    RAISE NOTICE '% % Type    :  %',
                        RPAD(col.attnum::text, 5, ' '), RPAD(col.attname, 16, ' '), concat (col.typname, '(', col.atttypmod, ')');
                else
                    RAISE NOTICE '% % Type    :  %',
                        RPAD(col.attnum::text, 5, ' '), RPAD(col.attname, 16, ' '), col.typname;
                end if;
                IF col.description is not null then
                    RAISE NOTICE '% Comment  :  "%"', RPAD('⠀', 22, ' '), col.description;
                end if;
                IF col.attnotnull is true then
                    RAISE NOTICE '% CONSTR  :  NOT_NULL', RPAD('⠀', 22, ' ');
                end if;
                IF col.conname is not null then
                    RAISE NOTICE '% CONSTR  :  "%"', RPAD('⠀', 22, ' '), concat(col.conname, ' ', col.constraint_definition);
                end if;
                RAISE NOTICE ' ';
            END LOOP;
    END IF;
END
$$ LANGUAGE plpgsql;
```

### результаты выполнения: 

```
psql -h pg -d studs
studs=> call table_columns_info('Н_ЛЮДИ', 's335086');

NOTICE:  Таблица: Н_ЛЮДИ
NOTICE:   
NOTICE:  No.  Имя столбца      Атрибуты
NOTICE:  ---  --------------   -------------------------------------------------
NOTICE:  1     ИД               Type    :  int4
NOTICE:  ⠀                      Comment  :  "Уникальный номер человека"
NOTICE:   
NOTICE:  2     ФАМИЛИЯ          Type    :  varchar(29)
NOTICE:  ⠀                      Comment  :  "Фамилия человека"
NOTICE:   
NOTICE:  3     ИМЯ              Type    :  varchar(19)
NOTICE:  ⠀                      Comment  :  "Имя человека"
NOTICE:   
NOTICE:  4     ОТЧЕСТВО         Type    :  varchar(24)
NOTICE:  ⠀                      Comment  :  "Отчество человека"
NOTICE:   
NOTICE:  5     ПИН              Type    :  varchar(24)
NOTICE:  ⠀                      Comment  :  "Номер страхового свидетельства ГПС"
NOTICE:   
NOTICE:  6     ИНН              Type    :  varchar(24)
NOTICE:  ⠀                      Comment  :  "Идентификационный номер налогоплательщика"
NOTICE:   
NOTICE:  7     ДАТА_РОЖДЕНИЯ    Type    :  timestamp
NOTICE:  ⠀                      Comment  :  "Дата рождения человека"
NOTICE:   
NOTICE:  8     ПОЛ              Type    :  bpchar(5)
NOTICE:  ⠀                      Comment  :  "Пол человека"
NOTICE:   
NOTICE:  9     МЕСТО_РОЖДЕНИЯ   Type    :  varchar(204)
NOTICE:  ⠀                      Comment  :  "Сведения из паспорта"
NOTICE:   
NOTICE:  10    ИНОСТРАН         Type    :  varchar(7)
NOTICE:   
NOTICE:  11    КТО_СОЗДАЛ       Type    :  varchar(44)
NOTICE:   
NOTICE:  12    КОГДА_СОЗДАЛ     Type    :  timestamp
NOTICE:   
NOTICE:  13    КТО_ИЗМЕНИЛ      Type    :  varchar(44)
NOTICE:   
NOTICE:  14    КОГДА_ИЗМЕНИЛ    Type    :  timestamp
NOTICE:   
NOTICE:  15    ДАТА_СМЕРТИ      Type    :  timestamp
NOTICE:   
NOTICE:  16    ФИО              Type    :  varchar(84)
NOTICE:   
CALL
studs=> call table_columns_info('Н_ЛЮДИ', 's333583');
NOTICE:   
NOTICE:  Таблица: Н_ЛЮДИ
NOTICE:   
NOTICE:  No.  Имя столбца      Атрибуты
NOTICE:  ---  --------------   -------------------------------------------------
NOTICE:  1     id               Type    :  int4
NOTICE:  ⠀                      CONSTR  :  NOT_NULL
NOTICE:  ⠀                      CONSTR  :  "Н_ЛЮДИ_pkey PRIMARY KEY (id)"
NOTICE:   
NOTICE:  2     ПОЛ              Type    :  varchar(5)
NOTICE:  ⠀                      CONSTR  :  "avcon_378561_ПОЛ_000 CHECK ((("ПОЛ")::text = ANY ((ARRAY['М'::character varying, 'Ж'::character varying])::text[])))"
NOTICE:   
NOTICE:  3     ФАМИЛИЯ          Type    :  varchar(104)
NOTICE:  ⠀                      CONSTR  :  NOT_NULL
NOTICE:   
CALL
```

### Вывод:
В ходе выполнения работы были изучены таблицы в калатоге pg_catalog. 