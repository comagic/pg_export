create table profile (
  id serial,
  name character varying(20) not null,
  codecs json not null
);

alter table profile add constraint pk__profile
  primary key (id);

alter table profile add constraint uq__profile__name
  unique (name);
