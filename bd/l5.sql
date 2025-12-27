--Работа с агрегатными функциями
-- Для каждого месяца 2024 года выведите количество проектов 

--создали временную табицу, только пока не понимаю зачем из примера\ 
with months as (
	select 'январь' month_nm, 1 month_nus union all 
	select 'февраль' month_nm, 2 month_nus union all 
	select 'март' month_nm, 3 month_nus union all 
	select 'апрель' month_nm, 4 month_nus union all 
	select 'май' month_nm, 5 month_nus union all 
	select 'июнь' month_nm, 6 month_nus union all 
	select 'июль' month_nm, 7 month_nus union all 
	select 'август' month_nm, 8 month_nus union all 
	select 'сентябрь' month_nm, 9 month_nus union all 
	select 'октябрь' month_nm, 10 month_nus union all                           
	select 'ноябрь' month_nm, 11 month_nus union all 
	select 'декабрь' month_nm, 12 month_nus
)
select * from months;

--теперь понимаю) 
--Добавим в sql-запрос выборку полей month_nm и количества выдач книг, соединим данные из построенной таблицы months с данными таблицы project по номеру месяца (из таблицы месяцев это поле month_nus), а для получения значения номера месяца из таблицы project – воспользуйтесь функцией extract.
select month_nm, (select count(*) from project where extract (month  from startdate) = month_nus) as kolvo
from months
order by month_nus;

--Добавьте фильтр к агрегатной функции с условием выборки – дата 2024 (тоже функция extract для получения года из даты).
select month_nm, (select count(*) from project where extract (month  from startdate) = month_nus and extract (year  from startdate) = 2024) as kolvo
from months
order by month_nus;

--Добавьте группировку по полю месяц и номер месяца.
select month_nm, (select count(*) from project where extract (month  from startdate) = month_nus and extract (year  from startdate) = 2024) as kolvo
from months
group by month_nm, month_nus
order by month_nus;

--Добавьте сортировку по полю номер месяца.
select month_nm,month_nus, (select count(*) from project where extract (month  from startdate) = month_nus and extract (year  from startdate) = 2024) as kolvo
from months
group by month_nm, month_nus
order by month_nus desc;

---------------ЗАдание 3.2 
--добавил побольше данных, для проверки рабоы 
insert into project (projectname, about, startdate, enddate, status, price, idcommand, project_type) values
('Мобильное приложение', 'Разработка приложения для iOS и Android', '2024-01-05', '2024-06-30', 'в работе', 200000, 1, 'информационный'),
('Веб-сайт компании', 'Создание корпоративного сайта', '2024-01-12', '2024-03-15', 'завершен', 80000, 2, 'информационный'),
('Соц. опрос', 'Проведение социологического исследования', '2024-01-20', '2024-02-28', 'завершен', 50000, 3, 'социальный'),
('База данных', 'Разработка системы учета', '2024-02-03', '2024-05-20', 'в работе', 120000, 1, 'исследовательский'),
('Маркетинговое исследование', 'Анализ рынка IT-услуг', '2024-02-10', '2024-03-01', 'завершен', 40000, 2, 'исследовательский'),
('Образовательный курс', 'Создание онлайн-курса по SQL', '2024-02-15', '2024-04-30', 'в работе', 90000, 3, 'социальный'),
('Чат-бот', 'Разработка AI-помощника', '2024-03-01', '2024-06-15', 'планируется', 150000, 1, 'информационный'),
('Экологический проект', 'Исследование загрязнения воды', '2024-03-05', '2024-05-10', 'в работе', 70000, 2, 'исследовательский'),
('Волонтерская программа', 'Организация помощи детям', '2024-03-10', '2024-12-31', 'в работе', 0, 3, 'социальный'),
('Аналитика Big Data', 'Обработка больших данных', '2024-03-15', '2024-08-20', 'планируется', 300000, 1, 'исследовательский');

--Воспользуйтесь функцией row_number() с окном по месяцу проекта с сортировкой по дню 
select  projectname, startdate, row_number() over(partition by extract(month from startdate) order by startdate) as nomer from project; 

--Измените данный запрос с применением функций RANK() и DENSE_RANK(), NTILE(). Ответьте, в чём разница между применениями этих функций
select  projectname, startdate, row_number() over(partition by extract(month from startdate) order by startdate) as nomer,
rank() over(partition by extract(month from startdate) order by startdate) as nomer1,
DENSE_RANK() over(partition by extract(month from startdate) order by startdate) as nomer2,
ntile(4) over(partition by extract(month from startdate) order by startdate) as nomer3
 from project; 

 --Напишите аналогичный запросу из п.3.1 с применением оконной функции
 -- Пункт 3.1 был: "Расставьте порядковый номер проекта для каждого дня"
-- Вот аналогичный запрос с оконной функцией:

select projectname, startdate, row_number() over (order by startdate) as номер
from project
order by startdate;

--Напишите оконную функцию для присвоения номера каждому пользователю студенту в группе (с сортировкой по фамилии и имени).
--разделяем студентов по группам и сортируем по фамилии и имени 
select lastname, firstname, groupname, row_number() over (partition by groupname order by lastname, firstname) as nomer
from student;

--Найдем в каждом месяце начало работы над проектами указанной команды.
--Найдем в каждом месяце начало работы над проектами указанной команды.
select extract(month from startdate) as месяц, min(startdate) as начало_работы
from project
where idcommand = 1
group by extract(month from startdate)
order by месяц;

--Найдем разницу между стоимостью проекта и средней стоимостью всех проектов.
select projectname, price,avg(price) over() as средняя_стоимость, price - avg(price) over () as разница_от_средней
from project
where price is not null;																	


--Упорядочьте записи о проектов в порядке убывания/возрастания их стоимости (с применением функций ранжирования и предложения window).
select projectname, price,
    row_number() over (order by price desc) as место_по_убыванию,
    row_number() over (order by price asc) as место_по_возрастанию
from project
where price is not null;


--Найдём накопительную сумму стоимости для каждого статуса проектов.
select projectname, status, price,
    sum(price) over (partition by status order by startdate) as накопительная_сумма
from project
where price is not null;

--накопительная, но студенты не делятся по статусам проекта, а просто сумирует все 
select projectname, status, price,
    sum(price) over (order by startdate) as накопительная_сумма
from project
where price is not null;

--*Найдём количество проектов, над которыми работает наставник с применением функций накопления.
select lastname, firstname,
    (select count(*) from project where idcommand = mentor.idcommand) as проектов_у_наставника
from mentor
where idcommand is not null;
--корочк  тут  считаем количество, сколько раз в таблице project встречается idcommand равная по значению mentor.idcommand? и полученную сумму мы записываем в столбец  проектов_у_наставника 

--* Произведите ранжирование по средней	 оценке студента за последние 3 задачи.	 
with student_grades as (
    select 'Иванов' as фамилия, 'Иван' as имя, 5 as оценка_1, 4 as оценка_2, 5 as оценка_3 union all
    select 'Петров', 'Петр', 4, 3, 4 union all
    select 'Сидорова', 'Мария', 5, 5, 5 union all
    select 'Кузнецов', 'Алексей', 3, 4, 3 union all
    select 'Смирнова', 'Анна', 4, 4, 5
)

select  фамилия, имя, (оценка_1 + оценка_2 + оценка_3) / 3.0 as средняя_оценка,
    rank() over (order by (оценка_1 + оценка_2 + оценка_3) / 3.0 desc) as место
from student_grades
order by место;


--*Найти накопительную сумму цен проектов за последние 3 месяца.
select projectname, startdate, price,
    sum(price) over (order by startdate) as накопительная_сумма
from project
where startdate >= current_date - interval '3 months' and price is not null;
