create table staff (
  staff_id integer not null default nextval('staff_staff_id_seq'::regclass),
  first_name character varying(45) not null,
  last_name character varying(45) not null,
  address_id smallint not null,
  email character varying(50),
  store_id smallint not null,
  active boolean not null default true,
  username character varying(16) not null,
  password character varying(40),
  last_update timestamp without time zone not null default now(),
  picture bytea
);

alter table staff add constraint staff_pkey
  primary key (staff_id);

alter table staff add constraint staff_address_id_fkey
  foreign key (address_id) references address(address_id) on update cascade on delete restrict;

create trigger last_updated
  before update on staff
  for each row execute function last_updated();
