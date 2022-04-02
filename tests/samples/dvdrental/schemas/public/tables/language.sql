create table language (
  language_id integer not null default nextval('language_language_id_seq'::regclass),
  name character(20) not null,
  last_update timestamp without time zone not null default now()
);

alter table language add constraint language_pkey
  primary key (language_id);

create trigger last_updated
  before update on language
  for each row execute function last_updated();
