create table city (
  city_id integer not null default nextval('city_city_id_seq'::regclass),
  city character varying(50) not null,
  country_id smallint not null,
  last_update timestamp without time zone not null default now()
);

alter table city add constraint city_pkey
  primary key (city_id);

alter table city add constraint fk_city
  foreign key (country_id) references country(country_id);

create trigger last_updated
  before update on city
  for each row execute function last_updated();

create index idx_fk_country_id on city(country_id);
