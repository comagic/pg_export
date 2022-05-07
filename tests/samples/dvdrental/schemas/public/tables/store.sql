create table store (
  store_id integer not null default nextval('store_store_id_seq'::regclass),
  manager_staff_id smallint not null,
  address_id smallint not null,
  last_update timestamp without time zone not null default now()
);

alter table store add constraint store_pkey
  primary key (store_id);

alter table store add constraint store_address_id_fkey
  foreign key (address_id) references address(address_id) on update cascade on delete restrict;

alter table store add constraint store_manager_staff_id_fkey
  foreign key (manager_staff_id) references staff(staff_id) on update cascade on delete restrict;

create trigger last_updated
  before update on store
  for each row execute function last_updated();

create unique index idx_unq_manager_staff_id on store(manager_staff_id);
