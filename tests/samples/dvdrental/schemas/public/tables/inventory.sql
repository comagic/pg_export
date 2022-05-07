create table inventory (
  inventory_id integer not null default nextval('inventory_inventory_id_seq'::regclass),
  film_id smallint not null,
  store_id smallint not null,
  last_update timestamp without time zone not null default now()
);

alter table inventory add constraint inventory_pkey
  primary key (inventory_id);

alter table inventory add constraint inventory_film_id_fkey
  foreign key (film_id) references film(film_id) on update cascade on delete restrict;

create trigger last_updated
  before update on inventory
  for each row execute function last_updated();

create index idx_store_id_film_id on inventory(store_id, film_id);
