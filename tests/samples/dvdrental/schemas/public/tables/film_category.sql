create table film_category (
  film_id smallint not null,
  category_id smallint not null,
  last_update timestamp without time zone not null default now()
);

alter table film_category add constraint film_category_pkey
  primary key (film_id, category_id);

alter table film_category add constraint film_category_category_id_fkey
  foreign key (category_id) references category(category_id) on update cascade on delete restrict;

alter table film_category add constraint film_category_film_id_fkey
  foreign key (film_id) references film(film_id) on update cascade on delete restrict;

create trigger last_updated
  before update on film_category
  for each row execute function last_updated();
