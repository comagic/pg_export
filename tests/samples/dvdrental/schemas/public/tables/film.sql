create table film (
  film_id integer not null default nextval('film_film_id_seq'::regclass),
  title character varying(255) not null,
  description text,
  release_year year,
  language_id smallint not null,
  rental_duration smallint not null default 3,
  rental_rate numeric(4,2) not null default 4.99,
  length smallint,
  replacement_cost numeric(5,2) not null default 19.99,
  rating mpaa_rating default 'G',
  last_update timestamp without time zone not null default now(),
  special_features text[],
  fulltext tsvector not null
);

alter table film add constraint film_pkey
  primary key (film_id);

alter table film add constraint film_language_id_fkey
  foreign key (language_id) references language(language_id) on update cascade on delete restrict;

create trigger film_fulltext_trigger
  before insert or update on film
  for each row execute function tsvector_update_trigger('fulltext', 'pg_catalog.english', 'title', 'description');

create trigger last_updated
  before update on film
  for each row execute function last_updated();

create index film_fulltext_idx on film
  using gist(fulltext);

create index idx_fk_language_id on film(language_id);

create index idx_title on film(title);
