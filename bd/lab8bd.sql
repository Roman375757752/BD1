-- =============================================
-- ЛАБОРАТОРНАЯ РАБОТА №8: ПРЕДСТАВЛЕНИЯ. ПРАВИЛА
-- =============================================

-- 1. ИЗМЕНЕНИЕ СТРУКТУРЫ ДАННЫХ И ОБНОВЛЕНИЕ ЗАПИСЕЙ
-- ==================================================

-- 1.1. Добавление поля about в таблицу project
ALTER TABLE project ADD COLUMN about TEXT;

-- Пример обновления данных в новом поле
UPDATE project SET about = 'Краткое описание проекта ' || projectname WHERE about IS NULL;

-- 1.2. Добавление поля категория в таблицу student
ALTER TABLE student ADD COLUMN категория VARCHAR(15) DEFAULT 'студент';

-- 1.3. Добавление полей result и project_deadline в таблицу project
ALTER TABLE project ADD COLUMN result REAL;
ALTER TABLE project ADD COLUMN project_deadline INTEGER DEFAULT 30;


-- 2. СОЗДАНИЕ ПРЕДСТАВЛЕНИЙ ДЛЯ ВЫБОРКИ ДАННЫХ
-- =============================================

-- 2.1. Простое представление
CREATE VIEW view_project AS
SELECT projectname, price FROM project;

-- Запрос на выборку всех записей представления
SELECT * FROM view_project;

-- 2.2. Представление WITH CHECK OPTION
CREATE VIEW project_type AS
SELECT project_type, projectname, project_deadline
FROM project
WHERE project_deadline > 15
WITH CHECK OPTION;

-- Вставка записи, УДОВЛЕТВОРЯЮЩЕЙ условию (project_deadline > 15)
INSERT INTO project_type (project_type, projectname, project_deadline)
VALUES ('учебный', 'Новый учебный проект', 20);
-- Запись добавится и в представление, и в базовую таблицу

-- Вставка записи, НЕ удовлетворяющей условию (project_deadline <= 15)
INSERT INTO project_type (project_type, projectname, project_deadline)
VALUES ('учебный', 'Другой учебный проект', 10);
-- ОШИБКА: новая запись нарушает условие ограничения для представления "project_type"

-- 2.3. Представление about с логикой в зависимости от шифра проекта
CREATE VIEW about AS
SELECT 
    id,
    projectname,
    CASE 
        WHEN id % 2 = 0 THEN 'Чётный проект'
        ELSE 'Нечётный проект'
    END AS тип_проекта_логика
FROM project;

-- 2.4. Представление project_dl с проверкой задолженности
CREATE VIEW project_dl AS
SELECT 
    projectname,
    startdate,
    enddate,
    project_deadline,
    CASE 
        WHEN (enddate - startdate) <= project_deadline THEN 'Премия будет'
        ELSE 'Премии не будет'
    END AS премия
FROM project;

-- 2.5. Представление max_z со студентами с наибольшим количеством несданных вовремя проектов
-- (Предположим, что есть поле status в project, где 'просрочен' означает несдачу)
CREATE VIEW max_z AS
SELECT 
    s.id,
    s.lastname,
    s.firstname,
    COUNT(p.id) AS количество_просроченных
FROM student s
JOIN command c ON s.idcommand = c.id
JOIN project p ON c.id = p.idcommand
WHERE p.status = 'просрочен'
GROUP BY s.id, s.lastname, s.firstname
HAVING COUNT(p.id) = (
    SELECT MAX(просрочки) 
    FROM (
        SELECT COUNT(p2.id) AS просрочки
        FROM student s2
        JOIN command c2 ON s2.idcommand = c2.id
        JOIN project p2 ON c2.id = p2.idcommand
        WHERE p2.status = 'просрочен'
        GROUP BY s2.id
    ) AS max_count
);

-- 2.6. Представление с агрегированной информацией по категориям студентов
CREATE VIEW student_categories AS
SELECT 
    COALESCE(категория, 'без категории') AS категория,
    COUNT(*) AS количество,
    AVG(EXTRACT(YEAR FROM CURRENT_DATE) - yearb) AS средний_возраст
FROM student
GROUP BY ROLLUP(категория);


-- 3. РАБОТА С СИСТЕМНЫМИ ПРЕДСТАВЛЕНИЯМИ
-- =======================================

-- 3.1. Информация о таблицах в схеме
SELECT table_name, table_type 
FROM information_schema.tables 
WHERE table_schema = 'public'
ORDER BY table_name;

-- 3.2. Полная информация о столбцах таблицы student
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_schema = 'public' AND table_name = 'student'
ORDER BY ordinal_position;

-- 3.3. Ограничения для таблицы project
SELECT constraint_name, constraint_type
FROM information_schema.table_constraints 
WHERE table_schema = 'public' AND table_name = 'project';

-- Количество ограничений по каждому типу
SELECT constraint_type, COUNT(*)
FROM information_schema.table_constraints 
WHERE table_schema = 'public' AND table_name = 'project'
GROUP BY constraint_type;

-- 3.4. Дополнительная информация о внешних ключах
SELECT 
    tc.table_name,
    kcu.column_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
WHERE tc.constraint_type = 'FOREIGN KEY' AND tc.table_name = 'project';

-- 3.5. Представление database_structure_report
CREATE VIEW database_structure_report AS
SELECT 
    t.table_name,
    COUNT(DISTINCT c.column_name) AS количество_столбцов,
    COUNT(DISTINCT tc.constraint_name) AS количество_ограничений,
    (SELECT COUNT(*) FROM public." || t.table_name || ") AS количество_записей,
    NULL AS дата_последнего_изменения -- В PostgreSQL нет простого способа получить эту информацию
FROM information_schema.tables t
LEFT JOIN information_schema.columns c ON t.table_name = c.table_name AND t.table_schema = c.table_schema
LEFT JOIN information_schema.table_constraints tc ON t.table_name = tc.table_name AND t.table_schema = tc.table_schema
WHERE t.table_schema = 'public' AND t.table_type = 'BASE TABLE'
GROUP BY t.table_name;

-- 3.6. Информация о добавленных полях (из задания 1)
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name IN ('project', 'student')
AND column_name IN ('about', 'категория', 'result', 'project_deadline');


-- 4. СОЗДАНИЕ ПРАВИЛ SELECT ДЛЯ ПРЕДСТАВЛЕНИЙ
-- ===========================================

-- 4.1. Представление student_command (исправлено: это ПРЕДСТАВЛЕНИЕ, а не таблица)
CREATE VIEW student_command AS
SELECT 
    s.id,
    s.lastname || ' ' || s.firstname AS студент,
    c.command AS команда,
    (p.price / COUNT(s.id) OVER (PARTITION BY c.id)) AS выплата
FROM student s
JOIN command c ON s.idcommand = c.id
JOIN project p ON c.id = p.idcommand;

-- 4.2. Представление student_com на основании student_command
CREATE VIEW student_com AS
SELECT 
    команда,
    COUNT(*) AS количество_студентов
FROM student_command
GROUP BY команда;

-- 4.3. Представление project_analysis с проверкой дедлайна
CREATE VIEW project_analysis AS
SELECT 
    projectname,
    startdate,
    enddate,
    project_deadline,
    CASE 
        WHEN (enddate - startdate) > project_deadline THEN 'дедлайн превышен'
        ELSE 'дедлайн соблюден'
    END AS статус_дедлайна
FROM project;


-- 5. СОЗДАНИЕ ПРАВИЛ INSERT ДЛЯ ПРЕДСТАВЛЕНИЙ
-- ============================================

-- 5.1. Правила INSERT/DELETE для представления student_command

-- Создадим функцию для обработки INSERT в представление student_command
CREATE OR REPLACE FUNCTION insert_student_command()
RETURNS TRIGGER AS $$
DECLARE
    command_id INTEGER;
    student_id INTEGER;
BEGIN
    -- Проверяем существование команды
    SELECT id INTO command_id FROM command WHERE command = NEW.команда;
    
    IF command_id IS NULL THEN
        -- Если команды нет, добавляем её
        INSERT INTO command (command) VALUES (NEW.команда) RETURNING id INTO command_id;
    END IF;
    
    -- Добавляем студента
    INSERT INTO student (lastname, firstname, idcommand)
    VALUES (
        SPLIT_PART(NEW.студент, ' ', 1), -- lastname
        SPLIT_PART(NEW.студент, ' ', 2), -- firstname
        command_id
    );
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Создаём триггер вместо правила (в современных версиях PostgreSQL правила для INSERT сложны в использовании)
CREATE TRIGGER student_command_insert_trigger
INSTEAD OF INSERT ON student_command
FOR EACH ROW EXECUTE FUNCTION insert_student_command();

-- Функция для обработки DELETE из представления student_command
CREATE OR REPLACE FUNCTION delete_student_command()
RETURNS TRIGGER AS $$
BEGIN
    -- Удаляем студентов указанной команды
    DELETE FROM student 
    WHERE idcommand IN (SELECT id FROM command WHERE command = OLD.команда);
    
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

-- Триггер для DELETE
CREATE TRIGGER student_command_delete_trigger
INSTEAD OF DELETE ON student_command
FOR EACH ROW EXECUTE FUNCTION delete_student_command();

-- 5.2. Представление tek_project и правило UPDATE
CREATE VIEW tek_project AS
SELECT 
    p.id,
    p.projectname,
    p.enddate,
    c.command AS команда
FROM project p
JOIN command c ON p.idcommand = c.id
WHERE p.enddate > CURRENT_DATE;

-- Функция для обработки UPDATE в представлении tek_project
CREATE OR REPLACE FUNCTION update_tek_project()
RETURNS TRIGGER AS $$
BEGIN
    -- Обновляем команду проекта
    IF NEW.команда IS NOT NULL AND NEW.команда != OLD.команда THEN
        UPDATE command SET command = NEW.команда WHERE id = (
            SELECT idcommand FROM project WHERE id = OLD.id
        );
    END IF;
    
    -- Обновляем дату окончания
    IF NEW.enddate IS NOT NULL AND NEW.enddate != OLD.enddate THEN
        UPDATE project SET enddate = NEW.enddate WHERE id = OLD.id;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Триггер для UPDATE
CREATE TRIGGER tek_project_update_trigger
INSTEAD OF UPDATE ON tek_project
FOR EACH ROW EXECUTE FUNCTION update_tek_project();

-- 5.3. Создание логов
-- 5.3.1. Таблица log_student
CREATE TABLE log_student (
    id SERIAL PRIMARY KEY,
    пользователь VARCHAR(100) DEFAULT CURRENT_USER,
    текущая_дата TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    операция VARCHAR(10)
);

-- 5.3.2. Функция и триггер для ведения логов
CREATE OR REPLACE FUNCTION log_student_changes()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO log_student (операция) VALUES ('INSERT');
        RETURN NEW;
    ELSIF TG_OP = 'UPDATE' THEN
        INSERT INTO log_student (операция) VALUES ('UPDATE');
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO log_student (операция) VALUES ('DELETE');
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER student_log_trigger
AFTER INSERT OR UPDATE OR DELETE ON student
FOR EACH ROW EXECUTE FUNCTION log_student_changes();

-- 5.3.3. Тестирование операций
INSERT INTO student (lastname, firstname, groupname) VALUES ('Иванов', 'Петр', '3091');
UPDATE student SET groupname = '3092' WHERE lastname = 'Иванов' AND firstname = 'Петр';
DELETE FROM student WHERE lastname = 'Иванов' AND firstname = 'Петр';

-- 5.3.4. Проверка записей в логе
SELECT * FROM log_student;


-- 6. СОЗДАНИЕ МАТЕРИАЛИЗОВАННЫХ ПРЕДСТАВЛЕНИЙ
-- ============================================

-- 6.1. Материализованное представление project_student
CREATE MATERIALIZED VIEW project_student AS
SELECT 
    s.lastname || ' ' || s.firstname AS студент,
    p.projectname AS проект,
    p.startdate AS дата_начала,
    p.enddate AS дата_окончания,
    t.task AS задача
FROM student s
JOIN command c ON s.idcommand = c.id
JOIN project p ON c.id = p.idcommand
JOIN task t ON p.id = t.idproject;

-- Добавление тестовых данных
INSERT INTO project (projectname, startdate, enddate, idcommand) 
VALUES ('Тестовый проект', '2024-01-01', '2024-06-01', 1);

INSERT INTO student (lastname, firstname, idcommand) 
VALUES ('Петров', 'Сергей', 1);

INSERT INTO task (task, idproject) VALUES ('Задача 1', 1);
INSERT INTO task (task, idproject) VALUES ('Задача 2', 1);

-- Просмотр данных из материализованного представления (данные могут быть устаревшими)
SELECT * FROM project_student;

-- Обновление материализованного представления
REFRESH MATERIALIZED VIEW project_student;

-- Просмотр обновленных данных
SELECT * FROM project_student;

-- Анализ плана запроса
EXPLAIN ANALYZE SELECT * FROM project_student;

-- Сравнение с выполнением исходного запроса
EXPLAIN ANALYZE
SELECT 
    s.lastname || ' ' || s.firstname AS студент,
    p.projectname AS проект,
    p.startdate AS дата_начала,
    p.enddate AS дата_окончания,
    t.task AS задача
FROM student s
JOIN command c ON s.idcommand = c.id
JOIN project p ON c.id = p.idcommand
JOIN task t ON p.id = t.idproject;

-- 6.2. Создание индекса для материализованного представления
CREATE INDEX idx_project_student_projekt ON project_student (проект);

-- Анализ плана запроса с индексом
EXPLAIN ANALYZE SELECT * FROM project_student WHERE проект = 'Тестовый проект';

-- 6.3. Материализованное представление с агрегированной информацией по типам проектов
CREATE MATERIALIZED VIEW project_type_stats AS
SELECT 
    project_type,
    COUNT(*) AS всего_проектов,
    COUNT(CASE WHEN status = 'завершен' THEN 1 END) AS завершенные,
    COUNT(CASE WHEN status != 'завершен' THEN 1 END) AS незавершенные
FROM project
GROUP BY project_type;


-- 7. НАСЛЕДОВАНИЕ И ПРАВИЛА
-- =========================

-- 7.1. Создание таблиц-наследников
CREATE TABLE student3091 () INHERITS (student);
CREATE TABLE student3092 () INHERITS (student);
CREATE TABLE student3093 () INHERITS (student);

-- 7.2. Правило для автоматического распределения студентов при вставке
CREATE OR REPLACE FUNCTION distribute_student()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.groupname = '3091' THEN
        INSERT INTO student3091 VALUES (NEW.*);
    ELSIF NEW.groupname = '3092' THEN
        INSERT INTO student3092 VALUES (NEW.*);
    ELSIF NEW.groupname = '3093' THEN
        INSERT INTO student3093 VALUES (NEW.*);
    ELSE
        INSERT INTO student VALUES (NEW.*);
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER student_distribution_trigger
BEFORE INSERT ON student
FOR EACH ROW EXECUTE FUNCTION distribute_student();

-- 7.3. Тестирование работы правил
INSERT INTO student (lastname, firstname, groupname) VALUES ('Сидоров', 'Алексей', '3091');
INSERT INTO student (lastname, firstname, groupname) VALUES ('Козлова', 'Мария', '3092');
INSERT INTO student (lastname, firstname, groupname) VALUES ('Никитин', 'Дмитрий', '3093');

-- Проверка распределения
SELECT 'student3091' AS таблица, COUNT(*) FROM student3091
UNION ALL
SELECT 'student3092' AS таблица, COUNT(*) FROM student3092
UNION ALL
SELECT 'student3093' AS таблица, COUNT(*) FROM student3093;

-- 7.4. Правило для распределения студентов по категориям (дополнительная логика)
-- Создадим таблицы для категорий
CREATE TABLE student_отличник () INHERITS (student);
CREATE TABLE student_хорошист () INHERITS (student);
CREATE TABLE student_ударник () INHERITS (student);

-- Функция для распределения по категориям
CREATE OR REPLACE FUNCTION distribute_student_by_category()
RETURNS TRIGGER AS $$
BEGIN
    -- Здесь можно добавить логику определения категории на основе других полей
    -- В данном примере используем поле "категория"
    IF NEW.категория = 'отличник' THEN
        INSERT INTO student_отличник VALUES (NEW.*);
    ELSIF NEW.категория = 'хорошист' THEN
        INSERT INTO student_хорошист VALUES (NEW.*);
    ELSIF NEW.категория = 'ударник' THEN
        INSERT INTO student_ударник VALUES (NEW.*);
    ELSE
        INSERT INTO student VALUES (NEW.*);
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Триггер для распределения по категориям
CREATE TRIGGER student_category_distribution_trigger
BEFORE INSERT ON student
FOR EACH ROW EXECUTE FUNCTION distribute_student_by_category();