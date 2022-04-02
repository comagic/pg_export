create table sip (
  id serial,
  name character varying(20) not null,
  channels integer
);

alter table sip add constraint pk__sip
  primary key (id);

alter table sip add constraint uq__sip__name
  unique (name);
