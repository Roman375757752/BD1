--Формирование многотабличных запросов
----Выведите фамилию и имена студента, и название команды, в которой он состоит.
 select* student.lastname, student.firstname, command.command from student, command where student.idcommand = command.id;

 --Выведите фамилии студентов, которые выполняют проект по указанной теме (тема ваша, например, исследовательский).
 select DISTINCT student.lastname from student, command, project where student.idcommand = command.id and command.id = project.idcommand and project.project_type = 'исследовательский';
 
--Выберите все проекты команды A&B.
select project.projectname, project.about, project.startdate, project.status from project, command
where project.idcommand = command.id and command.command = 'Команда А';

--Найдите фамилии и имена тех студентов, которые работают над проектами, название которых начинается на указанную букву (например, буква «К») в период от начала года до текущей даты.
select distinct lastname, firstname from student, project
where student.idcommand = project.idcommand and projectname like 'Э%' and startdate >= '2020-01-01' and startdate <= current_date  ;

--Перечислите студентов, которые в команде под руководством Телиной Ирины Сергеевны.

--добавим пока ее
insert into mentor (lastname, firstname, email, idcommand) 
values ('Телина', 'Ирина', 'telina@mail.ru', 1);


select student.lastname, student.firstname from student, command, mentor
where student.idcommand = command.id and command.id = mentor.idcommand and mentor.lastname = 'Телина' and mentor.firstname = 'Ирина';

--Агрегатные функции в многотабличных запросах
--Подсчитайте среднюю стоимость и количество выполняемых ей проектов каждой команды.
select  command.command, count(project.id) as количество_проектов, avg(project.price) as средняя_стоимость from command, project
where command.id = project.idcommand
group by command.id, command.command;

--* (having) Найдите количество работ над проектами, у которых название команды которых начинается на «Р»
select command.command as команда, count(project.id) as количество_работ from command, project
where command.id = project.idcommand and command.command like 'Р%'
group by command.id, command.command
having count(project.id) > 0;

--Решите задачу с применением filter
--Решите задачу с применением filter
-- Пример: посчитаем завершенные и незавершенные проекты для каждой команды

select command.command as команда, count(project.id) filter(where project.status = 'завершен') as завершенные, count(project.id) filter(where project.status = 'в работе') as в_работе, count(project.id) filter(where project.status = 'планируется') as планируется from command, project
where command.id = project.idcommand
group by command.id, command.command;

--Внешние соединения 

--Выполните операцию внешнего соединения таблиц Руководитель и Команда, для получения списка руководителей и название команд.
-- Руководитель = mentor, Команда = command
select mentor.lastname, mentor.firstname, command.command from mentor
left join command on mentor.idcommand = command.id;


--Получите команды, которые не взяли ни одного проекта.
select command.command from command
left join project on command.id = project.idcommand
where project.id is null;


--Получите список групп, в которых нет ни одного студента.
-- Группы = grouplist
select grouplist.groupname from grouplist
left join student on grouplist.groupname = student.groupname
where student.id is null;

--Множественные операции 

--Выведите название команд, которые выполняют проекты, стоимость которых >10000 и <20000 (оператор UNION ALL и UNION). Результаты сравните.
-- С UNION ALL (с дубликатами)
select distinct command.command from command, project
where command.id = project.idcommand and project.price > 10000
union all
select distinct command.command from command, project
where command.id = project.idcommand and project.price < 20000;

-- С UNION (без дубликатов)
select distinct command.command from command, project
where command.id = project.idcommand and project.price > 10000
union
select distinct command.command from command, project
where command.id = project.idcommand and project.price < 20000;


--Выбрать все записи о проектах, стоимость которых больше 1000р. и руководитель Цымбалюк Л.Н. (оператор пересечения).
-- ДОбавим САМОГО ЛУЧШЕГО И ДОБРОГО РУКОВОДИТЕЛЯ 
insert into mentor (lastname, firstname, email, idcommand) 
values ('Цымбалюк', 'Лариса', 'tsymbalyuk@mail.ru', 1);

-- Теперь INTERSECT
select project.id, project.projectname, project.price from project, command, mentor
where project.idcommand = command.id and command.id = mentor.idcommand and project.price > 1000
intersect
select project.id, project.projectname, project.price from project, command, mentor
where project.idcommand = command.id and command.id = mentor.idcommand and mentor.lastname = 'Цымбалюк' and mentor.firstname = 'Лариса';

--Придумайте и реализуйте пример разности.
-- Проекты дороже 50000, но НЕ те, что выполняет команда с id=1
select * from project
where price > 50000
except
select project.* from project, command
where project.idcommand = command.id and command.id = 1;

--Использование подзапросов

--Агрегатные функции в подзапросах: Выведите на экран все проекты, которые имеют стоимость, большую средней стоимости проектов.
select * from project
where price > (select avg(price) from project where price is not null);


--Найдите фамилии и имена тех студентов, которые работают в команде A
select lastname, firstname from student
where idcommand = (select id from command where command = 'Команда А');


--Найдите все проекты, которые имеет стоимость такую же, как стоимость указанного проекта.
-- Например, как у проекта с id=1
select * from project
where price = (select price from project where id = 1) and id != 1;


--(HAVING): Выведите количество проектов каждой команды, у которых фамилия руководителя содержит букву а.\
--оставл только итк комманд  , где хотя бы есть хоть 1 проект 
select command.command, count(project.id) as количество_проектов from command, project, mentor
where command.id = project.idcommand and command.id = mentor.idcommand and mentor.lastname  like '%а%'
group by command.id, command.command
having count(project.id) > 0;


--(Запрос с подзапросом после Select) – найдите название проектов и разницу с стоимости проекта и средней стоимостью всех проектов
select  projectname, price, price - (select avg(price) from project where price is not null) as разница_от_средней
from project
where price is not null;


--Перечислите команды, которые не работали ни с одним проектом типа ‘исследовательский’
select command.command from command
where id not in ( select distinct idcommand  from project where project_type = 'исследовательский');


--Подзапросы с ANY, SOME, ALL

--ANY: Найдите команды, которые реализуют хотя бы один проект.
select command from command
where id = any (select distinct idcommand from project where idcommand is not null);


--*SOME: Напишите запрос для вывода списка студентов, год рождения которых больше года рождения студентов из команды A&B
select lastname, firstname from student
where yearb > some (select yearb from student where idcommand = 1);


--ALL. Найти проекты, стоимость которых больше, чем самый дорогой проект указанного типа.
-- Например, больше чем самый дорогой социальный проект
--подзапрос выводит цены соц. проектов
select * from project
where price > all (select price from project where project_type = 'социальный' and price is not null);


--Подзапросы с EXISTS, NOT EXISTS

--Напишите подзапрос для вывода фамилий студентов из команд, которые реализуют проекты более одного типа.
select lastname, firstname from student
where exists (select 1 from project where project.idcommand = student.idcommand group by project.idcommand having count(distinct project.project_type) > 1
);


--* Напишите запрос для вывода название команд, которые реализуют проекты каждого типа.
select command from command
where exists (select 1 from project where project.idcommand = command.id and project.project_type = 'социальный'
) 
and exists (select 1 from project where project.idcommand = command.id and project.project_type = 'информационный'
)
and exists (select 1 from project where project.idcommand = command.id and project.project_type = 'исследовательский'
);

--Перечислите команды, которые не имеют ни одного проекта с указанным статусом.
-- Например, статус 'завершен'
select command from command
where not exists (select 1 from project where project.idcommand = command.id and project.status = 'завершен'
);


-- 4.8.2. Напишите запрос, который получит набор чисел от 1 до 10 с шагом 0,5
select generate_series(1.0, 10.0, 0.5) as число;


-- 4.8.3. Напишите рекурсивный запрос для получения суммы 10 чисел
with recursive sum_numbers(n, total) as (
    select 1, 1  -- начало: n=1, сумма=1
    union all
    select n + 1, total + (n + 1)  -- следующий шаг: увеличиваем n и добавляем к сумме
    from sum_numbers
    where n < 10  -- останавливаемся на 10
)
select total as сумма_чисел_от_1_до_10 from sum_numbers where n = 10;


-- 4.8.4. Напишите запрос, который сгенерирует даты в диапазоне от сегодняшнего числа + 30 дней.
select current_date + generate_series(0, 30) as дата;


-- 4.8.5. Построение рекурсивного запроса к набору данных

-- Создайте таблицу events, содержащую поля id, predid, postid, descr.
create table events (id bigint primary key, predid bigint, postid bigint, descr text);

-- Напишите запрос на выборку к generate_series(1,10) AS id с полями id*10, (id-1)*10, (id+1)*10, 'Event ' || id*10
select 
    id * 10 as зад1,
    (id - 1) * 10 as зад2,
    (id + 1) * 10 as зад3,
    'Event ' || (id * 10) as зад4
from generate_series(1, 10) as id;

-- Напишите запрос на вставку 10 записей в таблицу events, как результат предыдущего запроса
insert into events (id, predid, postid, descr)
select 
    id * 10,
    (id - 1) * 10,
    (id + 1) * 10,
    'Event ' || (id * 10)
from generate_series(1, 10) as id;

-- Напишите рекурсивный запрос, который найдёт id события от события с id=10
-- Рекурсивно находим всю цепочку событий, начиная с id=10
-- Каждое следующее событие имеет predid = id предыдущего
with recursive event_chain as (
    select id, predid, postid, descr
    from events
    where id = 10  
    union all
    select events.id, events.predid, events.postid, events.descr
    from events 
    join event_chain on events.predid = event_chain.id
)
select * from event_chain;


-- 4.8.6. *В таблицу student добавьте поле уровень, заполните его значениями (от 0 до 2), 
-- найдите список по подчинённым указанного пользователя.

-- Добавляем поле уровень
alter table student add column уровень integer;

-- Заполняем случайными значениями от 0 до 2
update student set уровень = ceil(random() * 2);

-- Находим подчиненных указанного пользователя (например, пользователя с id=1 и уровнем 0)
-- подчиненные имеют уровень > уровня руководителя
select s2.*
from student s1
join student s2 on s1.idcommand = s2.idcommand  -- в одной команде
where s1.id = 1  -- указанный пользователь
  and s2.уровень > s1.уровень;  -- подчиненные имеют больший уровень

  --По каждой группе найдите количество проектов, подвести итоги
-- Группа = groupname в таблице student

select 
    groupname,
    count(distinct project.id) as количество_проектов
from student
left join command on student.idcommand = command.id
left join project on command.id = project.idcommand
where groupname is not null
group by groupname
order by groupname;


--Распределите всех студентов по группам в зависимости от возраста
-- От 7 до 17 – начинающий
-- От 18 до 24 – продвинутый  
-- От 25 до 35 – профессионал
-- От 36 – эксперт

select 
    lastname,
    firstname,
    extract(year from current_date) - yearb as возраст,
    case 
        when extract(year from current_date) - yearb between 7 and 17 then 'начинающий'
        when extract(year from current_date) - yearb between 18 and 24 then 'продвинутый'
        when extract(year from current_date) - yearb between 25 and 35 then 'профессионал'
        when extract(year from current_date) - yearb >= 36 then 'эксперт'
        else 'не определен'
    end as уровень_опыта
from student
where yearb is not null
order by возраст;


--Дополнение в базе данных – закрепление задачи на студентом
-- Добавляем поле для закрепления задачи за студентом
alter table task add column student_id integer references student(id);

-- Закрепляем некоторые задачи за студентами
update task set student_id = 1 where id in (1, 2);
update task set student_id = 2 where id = 3;
update task set student_id = 3 where id = 4;
update task set student_id = 4 where id = 5;
update task set student_id = 5 where id = 6;


--По каждой группе найдите количество выполненных задач
-- (предположим, что выполненные задачи - это задачи со score >= 3)

SELECT 
    student.groupname,
    COUNT(task.id) AS количество_выполненных_задач
FROM student
LEFT JOIN task ON student.id = task.student_id
WHERE task.score >= 3  -- выполненные задачи
  AND student.groupname IS NOT NULL
GROUP BY student.groupname
ORDER BY student.groupname;



