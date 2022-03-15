create table registration (
  id serial,
  kind character varying(10) not null,
  host character varying(20) not null,
  port integer not null,
  expire integer not null,
  terminal integer
);

alter table registration add constraint pk__registration
  primary key (id);

alter table registration add constraint fk_registration_terminal_id_terminal
  foreign key (terminal) references terminal(id);
