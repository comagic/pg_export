create table rental (
  rental_id integer not null default nextval('rental_rental_id_seq'::regclass),
  rental_date timestamp without time zone not null,
  inventory_id integer not null,
  customer_id smallint not null,
  return_date timestamp without time zone,
  staff_id smallint not null,
  last_update timestamp without time zone not null default now()
);

alter table rental add constraint rental_pkey
  primary key (rental_id);

alter table rental add constraint rental_customer_id_fkey
  foreign key (customer_id) references customer(customer_id) on update cascade on delete restrict;

alter table rental add constraint rental_inventory_id_fkey
  foreign key (inventory_id) references inventory(inventory_id) on update cascade on delete restrict;

alter table rental add constraint rental_staff_id_key
  foreign key (staff_id) references staff(staff_id);

create trigger last_updated
  before update on rental
  for each row execute function last_updated();

create unique index idx_unq_rental_rental_date_inventory_id_customer_id on rental(rental_date, inventory_id, customer_id);

create index idx_fk_inventory_id on rental(inventory_id);
