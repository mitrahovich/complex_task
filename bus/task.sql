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
  departure      timestamp,
  arrival        timestamp,
  departure_city integer not null,
  arrival_city   integer not null,

  constraint bus_bus_fk_dict_bus foreign key (bus_id)
    references dict.bus (id) match simple
      on delete restrict,

  constraint bus_bus_fk_dict_departure_city foreign key (departure_city)
    references dict.city (id) match simple
      on delete restrict,

  constraint bus_bus_fk_dict_arrival_city foreign key (arrival_city)
    references dict.city (id) match simple
      on delete restrict,

  constraint pk_bus_bus primary key (id),
  constraint check_bus_bus_date check (departure < arrival)
);

CREATE TABLE bus.bus_line
(
  id             serial not null,
  bus_id         integer not null,
  city_id        integer not null,
  departure      timestamp,
  arrival        timestamp,
  weight         smallint, -- номер остановки

  constraint pk_bus_bus_line primary key (id),
  constraint unique_bus_line_bus_id_stop_number unique (bus_id, weight),
  constraint check_bus_bus_line_date check (departure < arrival),
  constraint check_bus_bus_stop_number check (weight > 0),

  constraint bus_bus_line_fk_dict_bus foreign key (bus_id)
    references dict.bus (id) match simple
      on delete cascade,

  constraint bus_bus_fk_dict_city foreign key (city_id)
    references dict.city (id) match simple
      on delete restrict
);
