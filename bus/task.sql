CREATE SCHEMA dict
  AUTHORIZATION postgres;

CREATE SCHEMA bus
  AUTHORIZATION postgres;


CREATE TABLE dict.bus
(
  id          serial not null,
  name        character varying(255) not null,
  place_count smallint default 0, -- кол-во мест

  constraint pk_dict_bus primary key (id),
  constraint check_dict_place_count check (place_count >= 0)
);

CREATE TABLE dict.city
(
  id serial   not null,
  name        character varying(255) not null,

  constraint pk_dict_city primary key (id)
);

CREATE TABLE bus.bus
(
  id          serial not null,
  bus_id      integer not null,
  name        character varying(255) not null,
  start       date,
  stop        date,
  constraint bus_bus_fk_dict_bus foreign key (bus_id)
    references dict.bus (id) match simple
      on delete restrict,

  constraint pk_bus_bus primary key (id)
);

CREATE TABLE bus.bus_line
(
  id             serial not null,
  bus_id         integer not null,
  city_id        integer not null,
  departure      time,
  arrival        time,
  day_in         integer,

  constraint pk_bus_bus_line primary key (id),
  constraint check_bus_bus_line_date check (departure < arrival),

  constraint bus_bus_line_fk_dict_bus foreign key (bus_id)
    references dict.bus (id) match simple
      on delete cascade,

  constraint bus_bus_fk_dict_city foreign key (city_id)
    references dict.city (id) match simple
      on delete restrict
);

CREATE TABLE bus.bus_line_tree
(
  ancestor   integer not null, -- предок
  descendant integer not null, -- потомок
  bus_id     integer not null,         -- номер остановки

  constraint pk_bus_line_tree primary key (ancestor, descendant, bus_id),

  constraint fk_bus_line_ancestor foreign key (ancestor)
    references bus.bus_line (id) match simple,

  constraint fk_bus_line_descendant foreign key (descendant)
    references bus.bus_line (id) match simple,

  constraint fk_bus_line_bus foreign key (bus_id)
    references bus.bus (id) match simple
);


insert into dict.bus
values (1, 'Модель 1', 25),(2, 'Модель 2', 50);

insert into dict.city
values (1, 'Москва'), (2, 'Спб'), (3, 'Новгород'), (4, 'Киев'), (5, 'Минск'), (6, 'Владивосток'), (7, 'Екат');

insert into bus.bus
values (1,1, 'Рейс 1', '2012-09-01', '2012-12-01'),(2,2, 'Рейс 2', '2012-09-01', '2012-12-01');

insert into bus.bus_line values
(1, 1, 1, null, '01:05:00', 0),
(2, 1, 3, '01:00:00' , '01:05:00', 1),
(3, 1, 4, '01:00:00' , '01:05:00', 2),
(4, 1, 5, '01:00:00' , '01:05:00', 3),
(5, 1, 7, '01:00:00' , null, 4),
(6, 2, 2, null , '10:05:00', 0),
(7, 2, 3, '10:00:00' , '10:05:00', 1),
(8, 2, 4, '10:00:00' , '10:05:00', 2),
(9, 2, 5, '10:00:00' , '10:05:00', 3),
(10, 2, 6, '10:00:00' , null, 4);

insert into bus.bus_line_tree values
(1,1,1),
(1,3,1),
(1,4,1),
(1,5,1),
(1,7,1),
(3,3,1),
(3,4,1),
(3,5,1),
(3,7,1),
(4,4,1),
(4,5,1),
(4,7,1),
(5,5,1),
(5,7,1),
(7,7,1),
(2,2,2),
(2,3,2),
(2,4,2),
(2,5,2),
(2,6,2),
(3,3,2),
(3,4,2),
(3,5,2),
(3,6,2),
(4,4,2),
(4,5,2),
(4,6,2),
(5,5,2),
(5,6,2),
(6,6,2);
-- Написать запрос, получающий список всех рейсов с городом отправления, городом прибытия и общим временем в пути.

select
  b.id,
  (24 * lt.day_in) * '1 day'::interval + (lt.departure - lf.arrival) as total_time,
  cf.name as from_name,
  ct.name as to_name
from bus.bus b
join bus.bus_line lf on lf.bus_id = b.id
join bus.bus_line lt on lt.bus_id = b.id
join dict.city cf on cf.id = lf.city_id
join dict.city ct on ct.id = lt.city_id
where
  lf.departure is null
  and lt.arrival is null;
--Написать запрос, который по заданной дате, городу отправления и городу прибытия выведет список возможных рейсов, количество остановок и общее время между этими городами

select
  b.name,
  (24 * (lt.day_in - lf.day_in)) * '1 day'::interval + (lt.departure - lf.arrival) as total_time,
  (
    select count(*) - 2 -- отсекаем конечные точки
    from
      bus.bus_line_tree t1, bus.bus_line_tree t2
    where
      t1.ancestor = lf.city_id
      and t2.descendant = lt.city_id
      and t1.descendant = t2.ancestor
      and t1.bus_id = b.id and t2.bus_id = b.id
  ) as stop_count
from
  bus.bus b
  join bus.bus_line lf on lf.bus_id = b.id
  join bus.bus_line lt on lt.bus_id = b.id
where
  '2012-10-20' between b.start and b.stop
  and lf.city_id = 3
  and lt.city_id = 5;

--Написать запрос, которые по заданной дате, городу отправления и городу прибытия выведет нумерованный список промежуточных городов: № остановки, город, время прибытия, время отбытия (включая конечную и начальную точки).

with stops as (
 select t1.descendant, t1.bus_id
 from
   bus.bus_line_tree t1, bus.bus_line_tree t2
 where
   and t1.descendant = t2.ancestor
   and t1.bus_id = t2.bus_id
)
select * from stops s
join bus.bus_line l on l.id = descendant
join bus.bus b on b.id = s.bus_id
where '2012-10-20' between b.start and b.stop
order by s.bus_id;