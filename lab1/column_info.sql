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