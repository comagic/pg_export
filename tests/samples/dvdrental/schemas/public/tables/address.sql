create table address (
  address_id integer not null default nextval('address_address_id_seq'::regclass),
  address character varying(50) not null,
  address2 character varying(50),
  district character varying(20) not null,
  city_id smallint not null,
  postal_code character varying(10),
  phone character varying(20) not null,
  last_update timestamp without time zone not null default now()
);

alter table address add constraint address_pkey
  primary key (address_id);

alter table address add constraint fk_address_city
  foreign key (city_id) references city(city_id);

create trigger last_updated
  before update on address
  for each row execute function last_updated();

create index idx_fk_city_id on address(city_id);
