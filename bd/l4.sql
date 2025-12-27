-- в таблицу studen добавить поле yearb
ALTER TABLE student ADD yearb INTEGER

--Заполните записями, для этого примените команду Update Таблица set поле=значение where id=Номер
Update student set yearb = 2006  where id = 1;
Update student set yearb = 2007 where id = 2;
Update student set yearb = 2008  where id = 3;
Update student set yearb = 2009 where id = 4;

--В таблицу project добавьте поле Тип проекта project_type
ALTER TABLE project ADD project_type varchar(50);

--Заполните записями данное поле значениями социальный, информационный, исследовательский, применяя конструкцию:
--update Таблица
--set поле=case
--when целое число от случайного * 3 = 0 then 'социальный' 
--...
--end;

update project 
set project_type = case 
when floor((random() * 3)) = 0 then 'сщциальный'
when floor((random() * 3)) = 1 then 'информационный'
else 'исследовательский'
end
where id = 1;
update project 
set project_type = case 
when floor((random() * 3)) = 0 then 'сщциальный'
when floor((random() * 3)) = 1 then 'информационный'
else 'исследовательский'
end
where id = 2;
update project 
set project_type = case 
when floor((random() * 3)) = 0 then 'сщциальный'
when floor((random() * 3)) = 1 then 'информационный'
else 'исследовательский'
end
where id = 3;
update project 
set project_type = case 
when floor((random() * 3)) = 0 then 'сщциальный'
when floor((random() * 3)) = 1 then 'информационный'
else 'исследовательский'
end
where id = 4;


--Создание простых запросов на языке SQL.
--Выберите все типы проектов из таблицы project без повторений;

select DISTINCT project_type
from project 
where project_type IS NOT NULL

--Выбор из таблицы project записей, название которых начинается или заканчиваются на А;
select * from project where projectname LIKE 'А%' or projectname ILIKE '%А';

--Выбор из списка значений – выбор проектов, типы которых 'исследовательский' или 'информационный';
select * from project where project_type in ('исследовательский', 'информационный');

--Найдите все проекты, которые были начаты между 2022 и 2024 годами;
select * from project where startDate >= '2022-01-01' and  startDate < '2025-01-01'

--Найдите проекты, в описании которых присутствует буквосочетание ‘об’.
select * from project where about  ILIKE'%об%';

--Найдите все задачи проектов, id которых содержит цифру 2 в повторении минимум 2 раза или содержит цифру 3 (используйте поиск по регулярному выражению).
select * from task where id::text LIKE '%22%' or id::text LIKE '%222%' or id::text LIKE '%2222%' or id::text LIKE '%3%';

--Сортировка результатов запроса.
--Выводите проекты, отсортированных по дате старта проекта;
select * from project ORDER BY startDate ASC;  
select * from project ORDER BY startDate DESC; 

--Произведите сортировку записей таблицы Наставник по убыванию фамилий.
select * from mentor ORDER BY lastname DESC;

--Произведите сортировку записей любого запроса из предыдущего задания (3.2) по возрастанию (по убыванию) с ограничением на количество записей (limit) – пропуская первые 2 значения вывести 3 значения.
select * from project where project_type in ('исследовательский', 'информационный') order by projectname asc limit 3 offset 2;
select * from project where project_type in ('исследовательский', 'информационный') order by projectname desc limit 3 offset 2;


--Работа с функциями, при необходимости используем псевдонимы полей.
--Напишите запросы с применением строковых функций (SUBSTRING, INITCAP, REPLACE).

-- INITCAP
select initcap(lastname) from student;

-- REPLACE  
select replace(projectname, ' ', '_') from project;

-- SUBSTRING
select substring(projectname from 1 for 5) from project;


--Придумайте и продемонстрируйте применение всех типов округления.
select round(price) from project; --Округление до ближайшего целого
select floor(price) from project; --Ближайшее целое число, меньшее или равное аргументу
select trunc(price) from project; --Усечение значащих цифр справа с заданной точностью


--Выведите на экран значение полей: Фамилия + Имя студента (с помощью функции CONCAT).
select concat(lastname, ' ', firstname) from student;


--Преобразуйте строку в число, строку в дату.
select to_number('123.45', 'L9G999');
select TO_DATE('20221015','YYYYMMDD');


--Преобразуйте число, дату в строку.
select to_char(2022, '9,999');
select to_char(timestamp '2021-12-31 13:30:15','HH12:MI:SS');


--Выведите названия проектов, которые состоят из более, чем одно слово.
select projectname from project where projectname like '% %';


--Найдите количество месяцев между текущей датой и январём 2025 года.
select extract(year from age('2025-01-01', current_date)) * 12 + extract(month from age('2025-01-01', current_date));


--Найдите количество дней, прошедших от начала года до текущей даты.
select current_date - date_trunc('year', current_date);



--Вывод списка студентов, возраст которых между 20 и 22.
select * from student where extract(year from current_date) - yearb between 20 and 22;



--Найдите количество дней между датой начала работы над проектом и датой окончания работы над проектом.
select enddate - startdate from project;



--Вычислите возраст (в днях) каждого проекта.
select current_date - startdate from project;



--Найдите по каждой команде количество выполненных работ в период от начала года до текущей даты
select 
    count(*) filter(where status = 'завершен' and enddate between date_trunc('year', current_date)::date and current_date) as completed_projects
from project;

--Найти средний год рождения всех студентов;
select avg(yearb) from student;


--Найдите минимальную стоимость проектов каждого типа.
select project_type, min(price) 
from project 
where project_type is not null 
group by project_type;

--Найдите среднюю цену тех проектов, месяц начала работы над которыми март, и год текущий.
select avg(price) 
from project 
where extract(month from startdate) = 3 
  and extract(year from startdate) = extract(year from current_date);

  --(case) Найдём количество проектов, которые по цене в диапазонах от 100 до 500, от 500 до1000, от 1000 до 10000.
select 
    count(case when price between 100 and 500 then 1 end) as "100-500",
    count(case when price between 500 and 1000 then 1 end) as "500-1000",
    count(case when price between 1000 and 1000000 then 1 end) as "1000-10000"
from project;

--(coalesce) Вывести количество проектов у каждой команды и итоговую стоимость всех проектов. Если у проекта нет цены, мы заменим ее на 'бесплатно' с помощью COALESCE.
select 
    idcommand,                 -- id команды
    count(*) as project_count, -- количество проектов
    coalesce(
        sum(price),      -- сумма цен
        'бесплатно'            -- или 'бесплатно' если NULL
    ) as total_price
from project
group by idcommand;           -- группируем по id команды


--(grouping) Найти сколько проектов по типу проекта по каждой команде.
-- Группируем по команде и по типу проекта
select idcommand, project_type, count(*)
from project
where idcommand is not null
group by idcommand, project_type;


--(group by cube) Найти сколько проектов в каждом статусе по каждой команд.
-- Группируем по команде и по статусу
select idcommand, status, count(*)
from project
where idcommand is not null
group by cube(idcommand, status);

--Найти сколько проектов выполняет каждая команда и сколько студентов задействовано в проектах.
-- Проекты по командам
select idcommand, count(*) as projects
from project
where idcommand is not null
group by idcommand;

-- Студенты по командам  
select idcommand, count(*) as students
from student
where idcommand is not null
group by idcommand;