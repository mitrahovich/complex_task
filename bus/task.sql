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
  id             serial not null,
  bus_id         integer not null,
  name        character varying(255) not null,

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
  departure      timestamp,
  arrival        timestamp,

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
  weight     smallint,         -- номер остановки

  constraint pk_bus_line_tree primary key (ancestor, descendant),

  constraint fk_bus_line_ancestor foreign key (ancestor)
    references bus.bus_line (id) match simple,

  constraint fk_bus_line_descendant foreign key (descendant)
    references bus.bus_line (id) match simple
);


-- Написать запрос, получающий список всех рейсов с городом отправления, городом прибытия и общим временем в пути.

select
  bus.name as bus_name,
  line_from.city_id,
  line_to.city_id,
  (line_from.departure + line_to.arrival) as total_time
from
  bus.bus bus -- рейс
  join bus.bus_line line_from on line_from.bus_id = bus.id -- начальная точка
    and line_from.id = (
      select
         ancestor
       from
         bus.bus_line_tree tree_from
       where
         weight = 0
    )
  join dict.city city_from on city_from.id = line_from.city_id
  join bus.bus_line line_to on line_to.bus_id = bus.id -- конечная точка
    and line_to.id = (
      select
        max(descendant)
      from bus.bus_line_tree tree_to
        where weight > 0
        and ancestor = line_from.id
    )
  join dict.city city_to on city_to.id = line_from.city_id;

--Написать запрос, который по заданной дате, городу отправления и городу прибытия выведет список возможных рейсов, количество остановок и общее время между этими городами

select
  bus.name,
  (line_from.weight - 1) as line_count, -- кол-во остановок, не считая крайние точки.
  (line_from.arrival + line_to.departure) as total_time
from
  bus.bus bus -- рейс
  join bus.bus_line line_from on line_from.bus_id = bus.id -- начальная точка
    and line_from.id = (
      select
         ancestor
       from
         bus.bus_line_tree tree_from
    )
  join bus.bus_line line_to on line_to.bus_id = bus.id -- конечная точка
    and line_to.id = (
      select
        descendant
      from bus.bus_line_tree tree_to
        where weight > 0
        and ancestor = line_from.id
    )
where
  :date between line_from.departure and line_from.arrival
  and :city_from = line_from.city_id
  and :city_to = line_to.city_id;

--Написать запрос, которые по заданной дате, городу отправления и городу прибытия выведет нумерованный список промежуточных городов: № остановки, город, время прибытия, время отбытия (включая конечную и начальную точки).

select
  tree.weight as line_number,
  city.name as city_name,
  line.departure,
  line.arrival,
from
  bus.bus_line line
  join bus.bus_line_tree tree on tree.descendant = line.id
    and tree.ancestor = :city_from and tree.descendant in (select ancestor from bus.bus_line_tree tree where tree.descendant = city_to)
  join dict.city city on city.id = line.city_id
where
  :date between line.departure and line.arrival;