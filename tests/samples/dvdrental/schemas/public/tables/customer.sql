create table customer (
  customer_id integer not null default nextval('customer_customer_id_seq'::regclass),
  store_id smallint not null,
  first_name character varying(45) not null,
  last_name character varying(45) not null,
  email character varying(50),
  address_id smallint not null,
  activebool boolean not null default true,
  create_date date not null default ('now'::text)::date,
  last_update timestamp without time zone default now(),
  active integer
);

alter table customer add constraint customer_pkey
  primary key (customer_id);

alter table customer add constraint customer_address_id_fkey
  foreign key (address_id) references address(address_id) on update cascade on delete restrict;

create trigger last_updated
  before update on customer
  for each row execute function last_updated();

create index idx_fk_address_id on customer(address_id);

create index idx_fk_store_id on customer(store_id);

create index idx_last_name on customer(last_name);
