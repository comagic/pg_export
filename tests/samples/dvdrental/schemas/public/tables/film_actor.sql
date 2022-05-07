create table film_actor (
  actor_id smallint not null,
  film_id smallint not null,
  last_update timestamp without time zone not null default now()
);

alter table film_actor add constraint film_actor_pkey
  primary key (actor_id, film_id);

alter table film_actor add constraint film_actor_actor_id_fkey
  foreign key (actor_id) references actor(actor_id) on update cascade on delete restrict;

alter table film_actor add constraint film_actor_film_id_fkey
  foreign key (film_id) references film(film_id) on update cascade on delete restrict;

create trigger last_updated
  before update on film_actor
  for each row execute function last_updated();

create index idx_fk_film_id on film_actor(film_id);
