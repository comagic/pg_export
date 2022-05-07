create table country (
  country_id integer not null default nextval('country_country_id_seq'::regclass),
  country character varying(50) not null,
  last_update timestamp without time zone not null default now()
);

alter table country add constraint country_pkey
  primary key (country_id);

create trigger last_updated
  before update on country
  for each row execute function last_updated();
