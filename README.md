# РСХД
Distributed Systems of Data Storage. ITMO 

Лабораторные работы по дисциплине 


## Лабораторная работа №1
Используя сведения из системных каталогов получить информацию о любой таблице: Номер по порядку, Имя столбца, Атрибуты (в атрибуты столбца включить тип данных, ограничение типа CHECK).

Пример: 

Таблица: Н_ЛЮДИ
```
No.  Имя столбца         Атрибуты
 --- ------------ ------------------------------------------------------
1   ИД            Type    : NUMBER(9) NOT NULL
Comment : 'Уникальный номер человека'
2   ФАМИЛИЯ       Type    : VARCHAR2(25) NOT NULL
Comment : 'Фамилия человека'
3   ИМЯ           Type    : VARCHAR2(2000) NOT NULL
Comment : 'Имя человека'
4   ОТЧЕСТВО      Type    : VARCHAR2(20)  
Comment : 'Отчество человека'
5   ДАТА_РОЖДЕНИЯ Type    : DATE NOT NULL
Comment : 'Дата рождения человека'
6   ПОЛ           Type    : CHAR(1) NOT NULL
Constr  : "AVCON_378561_ПОЛ_000" CHECK (ПОЛ IN ('М', 'Ж'))
Constr  : "AVCON_388176_ПОЛ_000" CHECK (ПОЛ IN ('М', 'Ж'))
Comment : 'Пол человека'
7   ИНОСТРАН      Type    : VARCHAR2(3) NOT NULL
8   КТО_СОЗДАЛ    Type    : VARCHAR2(40) NOT NULL
9   КОГДА_СОЗДАЛ  Type    : DATE NOT NULL
10  КТО_ИЗМЕНИЛ   Type    : VARCHAR2(40) NOT NULL
11  КОГДА_ИЗМЕНИ  Type    : DATE NOT NULL
12  ДАТА_СМЕРТИ   Type    : DATE  
Comment : 'Дата смерти человека'
13  ПИН           Type    : VARCHAR2(20)  
14  ИНН           Type    : VARCHAR2(20)  
```