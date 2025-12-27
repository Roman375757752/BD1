-- ЕДИНЫЙ SQL КОД ДЛЯ ПРАКТИЧЕСКОЙ РАБОТЫ №7
-- Методы контроля качества данных. Индексы и оптимизация запросов.

---------------------------------------------------------------------------------------------------
-- ПРОВЕРКА СТРУКТУРЫ ТАБЛИЦ (ЗАДАНИЕ 119)
---------------------------------------------------------------------------------------------------
-- Предполагается, что таблицы уже существуют со следующей структурой:
-- project (id, projectname, about, startdate, enddate, status, price, idcommand, project_type)
-- student (id, lastname, firstname, role, email, yearb, groupname, idcommand)
-- command (id, command)
-- task (id,task, idproject)
-- resource (id, resource, idproject)
-- grouplist (groupname, sp)
-- mentor (id, lastname, firstname, email, idcommand)


---------------------------------------------------------------------------------------------------
-- МЕТОДЫ КОНТРОЛЯ КАЧЕСТВА ДАННЫХ (ЗАДАНИЯ 128-137)
-- (Используем таблицу student для примеров)
---------------------------------------------------------------------------------------------------

-- 131. выполнить поиск с применением функции regexp_match (Найти имя домена, напр. "gmail" в "user@gmail.com")
SELECT
    email,
    regexp_match(email, '@(.*)\.') AS domain_match
FROM student
WHERE email IS NOT NULL
LIMIT 3;

-- 132. выполнить поиск с применением функции regexp_matches (Найти все слова, начинающиеся с 'p'/'П' в имени студента)
SELECT
    firstname,
    regexp_matches(firstname, '\m[Pp]\w+', 'g') AS p_words_match
FROM student
WHERE firstname ~ '\m[Pp]\w+'
LIMIT 3;

-- 133. выполнить поиск с применением regexp_replace (Заменить весь email на анонимизированное имя, оставив только @домен)
SELECT
    email,
    regexp_replace(email, '^.*@', 'anonymous@') AS masked_email
FROM student
WHERE email IS NOT NULL
LIMIT 3;

-- 134. разобраться с функцией regexp_split_to_table (Разбить названия команд на отдельные слова по пробелу)
SELECT
    c.command,
    word
FROM command c,
    regexp_split_to_table(c.command, '\s+') AS word
LIMIT 5;

-- 135. разобраться с функцией split_part (Получить первую часть имени после дефиса, если фамилия двойная)
SELECT
    lastname,
    split_part(lastname, '-', 1) AS first_part_lastname
FROM student
WHERE lastname LIKE '%-%'
LIMIT 3;

-- 136. разобраться с функцией substring (Извлечь 4-х значный год из поля yearb)
SELECT
    yearb,
    SUBSTRING(CAST(yearb AS TEXT) FROM '(\d{4})') AS extracted_year
FROM student
LIMIT 3;

-- 137. разобраться с функцией regexp_substr (Используем аналог - SUBSTRING с регулярным выражением)
SELECT
    email,
    SUBSTRING(email FROM '@(\w+)') AS domain_name
FROM student
LIMIT 3;


---------------------------------------------------------------------------------------------------
-- РАБОТА С РЕГУЛЯРНЫМИ ВЫРАЖЕНИЯМИ (ШАБЛОНЫ) (ЗАДАНИЯ 138-142)
---------------------------------------------------------------------------------------------------

-- 139. Напишите регулярное выражение для поиска HTML-цвета, заданного как #ABCDEF
SELECT '#FF00A0' ~ '^#[0-9A-Fa-f]{6}$' AS is_valid_hex_color;

-- 140. Написать регулярное выражение для выбора IP адресов (v4)
SELECT '192.168.1.10' ~ '^(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])$' AS is_valid_ipv4;

-- 141. Напишите регулярное выражение, которое находит даты в строке. Формат DD.MM.YYYY
SELECT 'Дата проекта 25.10.2025' ~ '\d{2}\.\d{2}\.\d{4}' AS contains_date_format;

-- 142. Напишите регулярное выражение, которое находит цены в тексте (с валютой, разделителями)
SELECT 'Цена: $1,234.50' ~ '[$\u00A3\u20AC]?\d{1,3}(?:[,\s]\d{3})*(?:\.\d{2})?' AS contains_price_pattern;


---------------------------------------------------------------------------------------------------
-- РАБОТА С НЕСТРУКТУРИРОВАННЫМИ ДАННЫМИ (ЗАДАНИЯ 143-152)
---------------------------------------------------------------------------------------------------

-- 144. Создайте временную таблицу tempdata
CREATE TEMP TABLE tempdata (
    data_line TEXT
);

-- Заполнение
INSERT INTO tempdata (data_line) VALUES
('Иванов Петр, 2000, А'),
('Смирнова-Котова Анна, 2002, Б'),
('Сидоров Олег 2004 C'),
('ФамилияБезКатегории 1999, '), -- Случай без категории, но с запятой
('Дефис-Дефисов Иван, 2001, A');


-- 145. Произведите поиск по данным всех фамилий (Слово до первого пробела или запятой)
SELECT
    data_line,
    (regexp_match(data_line, '^([\w\-]+)'))[1] AS lastname
FROM tempdata;

-- 146. Произведите поиск по данным всех годов рождений (4 цифры)
SELECT
    data_line,
    (regexp_match(data_line, '(\d{4})'))[1] AS birth_year
FROM tempdata;

-- 147. Произведите поиск по данным всех категорий (Буква или NULL, в конце строки/после разделителя)
SELECT
    data_line,
    TRIM(TRAILING ',' FROM (regexp_match(data_line, '(\s[A-ЯA-Z]{1,2})$|\s(\w+)[,]*$'))[1]) AS category -- Захват в конце строки
FROM tempdata;


-- 148. Разбейте неструктурированные данные и преобразуйте каждую строку в student. (Демонстрация извлечения, без реальной вставки в student, чтобы не нарушать целостность данных)
-- Используем регулярное выражение для извлечения 4-х полей: (ФамилияИмя) (Год) (Категория)
SELECT
    -- Извлекаем Фамилию, включая двойные (слова до первого пробела/запятой)
    TRIM((regexp_match(data_line, '^([\w-]+)'))[1]) AS lastname_ext,
    -- Извлекаем Имя (слово после первой фамилии)
    TRIM((regexp_match(data_line, '^[\w-]+\s+([\w-]+)'))[1]) AS firstname_ext,
    -- Извлекаем Год (4 цифры)
    (regexp_match(data_line, '(\d{4})'))[1] AS yearb_ext,
    -- Извлекаем Категорию (одно или два слова/буквы в конце, необязательно)
    TRIM(TRAILING ',' FROM (regexp_match(data_line, '[,\s](\w+)$'))[1]) AS category_ext
FROM tempdata;

-- 151. Добавьте в таблицу project поле shifr с check проверкой
ALTER TABLE project
ADD COLUMN shifr VARCHAR(6);

ALTER TABLE project
ADD CONSTRAINT check_shifr_format_pra
CHECK (shifr ~ '^[A-Za-z]{2}\d{4}$'); -- Первые две буквы латинские, потом четыре цифры


-- 152. Заполните таблицу значениями
UPDATE project SET shifr = 'PZ0001' WHERE id = (SELECT id FROM project LIMIT 1 OFFSET 0);
UPDATE project SET shifr = 'PR0002' WHERE id = (SELECT id FROM project LIMIT 1 OFFSET 1);
UPDATE project SET shifr = 'ST9999' WHERE id = (SELECT id FROM project LIMIT 1 OFFSET 2);
-- Добавь больше команд UPDATE, чтобы заполнить больше строк.


---------------------------------------------------------------------------------------------------
-- АНАЛИЗ СТАТИСТИКИ, СОЗДАНИЕ ИНДЕКСОВ (ЗАДАНИЯ 153-165)
---------------------------------------------------------------------------------------------------

-- 154. Напишите инструкцию для просмотра статистики любой таблицы
SELECT * FROM pg_stat_all_tables WHERE relname = 'student';

-- 157. Выведите значение поля seq_scan из предыдущего запроса
SELECT seq_scan FROM pg_stat_all_tables WHERE relname = 'student';

-- 158. Выполните чтение таблицы (Для увеличения счетчика seq_scan)
SELECT * FROM student LIMIT 1;

-- 160. Проверьте значение поля seq_scan после чтения таблицы
SELECT seq_scan FROM pg_stat_all_tables WHERE relname = 'student'; -- Должно увеличиться

-- 161. Создайте таблицу stattable на основании запроса на нахождения количества вставленных и удалённых строк
CREATE TABLE stattable AS
SELECT
    relname AS table_name,
    n_tup_ins AS inserted_tuples,
    n_tup_del AS deleted_tuples
FROM pg_stat_all_tables
WHERE relname IN ('student', 'project');


-- 162. Создайте индекс в таблице mentor – включающий поля lastname и name (предполагаем name = firstname)
CREATE INDEX mentor_ln_fn_idx ON mentor (lastname, firstname);

-- 163. Создайте индекс в таблице project, включающий поле категория (project_type) (по убыванию значения)
CREATE INDEX project_type_desc_idx ON project (project_type DESC);

-- 164. Напишите запрос к таблице project с применением индекса по категории
SELECT *
FROM project
WHERE project_type = 'Research' -- Выбери существующую категорию
ORDER BY project_type DESC
LIMIT 10;

-- 165. Найдите количество сканирований по индексу (idx_scan) и количество строк, отобранных (idx_tup_fetch)
SELECT
    idx_scan,
    idx_tup_fetch
FROM pg_stat_all_tables
WHERE relname = 'project';


---------------------------------------------------------------------------------------------------
-- ПЛАН ВЫПОЛНЕНИЯ ЗАПРОСА (ЗАДАНИЯ 166-178)
---------------------------------------------------------------------------------------------------

-- 167. Постройте план запроса для нахождения данных о проектах указанной команды с сортировкой по дате начала
-- 168. EXPLAIN SQL -запрос
EXPLAIN
SELECT
    p.projectname,
    p.startdate,
    c.command
FROM project p
JOIN command c ON p.idcommand = c.id
WHERE c.command = 'Team Alpha' -- Укажи существующую команду
ORDER BY p.startdate;

-- 171. Просмотрите анализ плана запроса с применением explain analyze select
EXPLAIN ANALYZE
SELECT
    p.projectname,
    p.startdate,
    c.command
FROM project p
JOIN command c ON p.idcommand = c.id
WHERE c.command = 'Team Alpha' -- Укажи существующую команду
ORDER BY p.startdate;


-- 174. Создайте индекс в таблице student, включающий поле категория пользователя (role) (по убыванию значения)
CREATE INDEX student_role_desc_idx ON student (role DESC);

-- Посмотрите план запроса с применением индекса.
EXPLAIN
SELECT *
FROM student
WHERE role = 'Team Lead' -- Укажи существующую роль
ORDER BY role DESC
LIMIT 5;


-- 175. Создайте копию таблицы student. Удалите первичный ключ с поля id в ней.
CREATE TABLE student_copy AS TABLE student;
ALTER TABLE student_copy DROP CONSTRAINT student_pkey; -- Предполагаем, что ключ назван student_pkey

-- 176. Запросите одного пользователя по его коду. Постройте план запроса, определите способ доступа.
EXPLAIN
SELECT * FROM student_copy WHERE id = 12345; -- Укажи существующий ID

-- 177, 178. Выберите всех студентов, которые в текущем году не выполнили ни одного проекта. (Предполагаем, что "текущий год" - 2025)

-- Вариант 1: Через JOIN (LEFT JOIN и проверка NULL)
EXPLAIN ANALYZE -- Сравнение планов
SELECT
    s.lastname,
    s.firstname
FROM student s
LEFT JOIN project p ON s.idcommand = p.idcommand AND p.startdate >= DATE '2025-01-01' AND p.startdate < DATE '2026-01-01'
WHERE p.id IS NULL;

-- Вариант 2: Через подзапрос (NOT IN или NOT EXISTS)
EXPLAIN ANALYZE -- Сравнение планов
SELECT
    lastname,
    firstname
FROM student
WHERE idcommand NOT IN (
    SELECT DISTINCT idcommand
    FROM project
    WHERE startdate >= DATE '2025-01-01' AND startdate < DATE '2026-01-01'
);


-- 179. Выведите список студентов и название команд. С помощью hints добейтесь всех трех способов исполнения соединения. (Hints специфичны для СУБД, в PostgreSQL требуют расширения pg_hint_plan. Ниже приведены стандартные SQL-запросы, которые оптимизатор может выполнить разными способами, или синтаксис hint'ов Oracle-стиля для демонстрации цели)

SELECT s.lastname, c.command -- Без hint (оптимизатор выбирает сам, скорее всего Hash Join)
FROM student s
JOIN command c ON s.idcommand = c.id;

-- Требуется установка pg_hint_plan:
-- SELECT /*+ Leading((s c)) HashJoin(s c) */ s.lastname, c.command ... (Hash Join)
-- SELECT /*+ Leading((s c)) NestLoop(s c) */ s.lastname, c.command ... (Nested Loop)
-- SELECT /*+ Leading((s c)) MergeJoin(s c) */ s.lastname, c.command ... (Sort Merge Join)


---------------------------------------------------------------------------------------------------
-- РАСШИРЕННЫЕ ЗАПРОСЫ, КУРСОРЫ (ЗАДАНИЯ 181-187)
---------------------------------------------------------------------------------------------------

-- 182. Создайте преподготовленный запрос: найдите год рождения студента с указанным номером (id).
PREPARE find_birth_year (INT) AS
SELECT yearb FROM student WHERE id = $1;

-- 183. Выполните запрос с разными значениями входного параметра.
EXECUTE find_birth_year (1); -- Используй реальный ID
EXECUTE find_birth_year (2);

-- 184. Постройте план запросов, сравните стоимость (Без преподготовленного запроса)
EXPLAIN SELECT yearb FROM student WHERE id = 1;

-- 184. Постройте план запросов, сравните стоимость (С преподготовленным запросом)
EXPLAIN EXECUTE find_birth_year (1);


-- 185. Создайте преподготовленный запрос на удаление записи в таблице Project.
PREPARE delete_project (INT) AS
DELETE FROM project WHERE id = $1;

-- Стартуйте транзакцию (begin). Выполните запрос с разными параметрами. Откатите транзакцию (rollback).
BEGIN;
EXECUTE delete_project (101); -- Используй реальный ID для тестирования
EXECUTE delete_project (102);
ROLLBACK;


-- 186. Создайте курсор для выборки данных из таблицы Project указанной команды.
BEGIN;
DECLARE project_cursor CURSOR FOR
SELECT projectname, startdate FROM project WHERE idcommand = (SELECT id FROM command WHERE command = 'Team Alpha' LIMIT 1); -- Укажи существующую команду

-- 187. Используя оператор FETCH NEXT FROM курсор, переберите записи
FETCH NEXT FROM project_cursor;
FETCH NEXT FROM project_cursor;

-- Закройте курсор CLOSE курсор.
CLOSE project_cursor;
COMMIT;


---------------------------------------------------------------------------------------------------
-- СЕКЦИОНИРОВАНИЕ (ЗАДАНИЯ 188-197)
---------------------------------------------------------------------------------------------------

-- 190. Создайте секционированную таблицу secproject по диапазону дат начала работы
CREATE TABLE secproject (
    id INT NOT NULL,
    projectname VARCHAR(255),
    startdate DATE NOT NULL,
    idcommand INT
) PARTITION BY RANGE (startdate);

-- 191. Создайте три секции для разных временных периодов (по годам)
CREATE TABLE secproject_y2023 PARTITION OF secproject
FOR VALUES FROM ('2023-01-01') TO ('2024-01-01');

CREATE TABLE secproject_y2024 PARTITION OF secproject
FOR VALUES FROM ('2024-01-01') TO ('2025-01-01');

CREATE TABLE secproject_y2025 PARTITION OF secproject
FOR VALUES FROM ('2025-01-01') TO ('2026-01-01');

-- 192. Напишите запрос на вставку записей из таблицы Project в созданную таблицу.
INSERT INTO secproject (id, projectname, startdate, idcommand)
SELECT id, projectname, startdate, idcommand FROM project
ON CONFLICT (id) DO NOTHING; -- Добавление ON CONFLICT, если id уже использован


-- 193. Напишите запрос на выборку данных из каждой созданной секции
SELECT * FROM secproject_y2024 LIMIT 3;

-- 194. Удалите одну из секций
ALTER TABLE secproject DETACH PARTITION secproject_y2023;
DROP TABLE secproject_y2023; -- Физическое удаление данных

-- 195, 196. Создайте таблицу users с секционированием по диапазонам годов рождения
CREATE TABLE users_by_year (
    id INT NOT NULL,
    lastname VARCHAR(255),
    yearb INT NOT NULL
) PARTITION BY RANGE (yearb);

-- Создайте секции для разных возрастных групп
CREATE TABLE users_y1998_2000 PARTITION OF users_by_year
FOR VALUES FROM (1998) TO (2001); -- До 2001 не включая

CREATE TABLE users_y2001_2003 PARTITION OF users_by_year
FOR VALUES FROM (2001) TO (2004);

CREATE TABLE users_y2004_2006 PARTITION OF users_by_year
FOR VALUES FROM (2004) TO (2007);

-- Вставка данных для проверки
INSERT INTO users_by_year (id, lastname, yearb)
SELECT id, lastname, yearb FROM student
ON CONFLICT (id) DO NOTHING;

-- 197. Проверьте распределение. (Проверка, что данные попали в нужные секции)
SELECT yearb, lastname FROM users_y1998_2000;
SELECT yearb, lastname FROM users_y2001_2003;


---------------------------------------------------------------------------------------------------
-- НАСЛЕДОВАНИЕ И ПРАВИЛА* (ЗАДАНИЯ 198-201)
---------------------------------------------------------------------------------------------------
-- Для реализации партиционирования с помощью наследования (устаревший метод, но соответствует заданию)

-- Создаем родительскую таблицу
CREATE TABLE student_master (
    id INT,
    lastname VARCHAR(255),
    firstname VARCHAR(255),
    groupname VARCHAR(50)
);

-- 199. Создайте таблицы-наследники по группам student3091, student3092, student3093.
CREATE TABLE student3091 () INHERITS (student_master);
CREATE TABLE student3092 () INHERITS (student_master);
CREATE TABLE student3093 () INHERITS (student_master);

-- Добавляем CHECK-ограничения для направления запросов
ALTER TABLE student3091 ADD CONSTRAINT check_group_3091 CHECK (groupname = '3091');
ALTER TABLE student3092 ADD CONSTRAINT check_group_3092 CHECK (groupname = '3092');
ALTER TABLE student3093 ADD CONSTRAINT check_group_3093 ADD CONSTRAINT check_group_3093 CHECK (groupname = '3093');


-- 200. Напишите правила для автоматического распределения студентов при вставке записей в таблицу student_master.
CREATE OR REPLACE RULE student_insert_3091 AS
    ON INSERT TO student_master WHERE (NEW.groupname = '3091')
    DO INSTEAD INSERT INTO student3091 VALUES (NEW.*);

CREATE OR REPLACE RULE student_insert_3092 AS
    ON INSERT TO student_master WHERE (NEW.groupname = '3092')
    DO INSTEAD INSERT INTO student3092 VALUES (NEW.*);

CREATE OR REPLACE RULE student_insert_3093 AS
    ON INSERT TO student_master WHERE (NEW.groupname = '3093')
    DO INSTEAD INSERT INTO student3093 VALUES (NEW.*);

-- 201. Протестируйте работу правил вставкой записей, проверьте полученный результат.
INSERT INTO student_master (id, lastname, firstname, groupname) VALUES (10, 'Тест1', 'Имя1', '3091');
INSERT INTO student_master (id, lastname, firstname, groupname) VALUES (11, 'Тест2', 'Имя2', '3092');
INSERT INTO student_master (id, lastname, firstname, groupname) VALUES (12, 'Тест3', 'Имя3', '3093');

-- Проверка
SELECT * FROM student3091;
SELECT * FROM student3092;

-- Запрос к родительской таблице покажет данные из всех наследников
SELECT * FROM ONLY student_master; -- Только из родителя
SELECT * FROM student_master; -- Из родителя и всех наследников