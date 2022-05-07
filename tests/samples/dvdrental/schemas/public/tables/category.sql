create table category (
  category_id integer not null default nextval('category_category_id_seq'::regclass),
  name character varying(25) not null,
  last_update timestamp without time zone not null default now()
);

alter table category add constraint category_pkey
  primary key (category_id);

create trigger last_updated
  before update on category
  for each row execute function last_updated();
