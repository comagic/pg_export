create table actor (
  actor_id integer not null default nextval('actor_actor_id_seq'::regclass),
  first_name character varying(45) not null,
  last_name character varying(45) not null,
  last_update timestamp without time zone not null default now()
);

alter table actor add constraint actor_pkey
  primary key (actor_id);

create trigger last_updated
  before update on actor
  for each row execute function last_updated();

create index idx_actor_last_name on actor(last_name);
