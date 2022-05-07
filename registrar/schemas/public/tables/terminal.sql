create table terminal (
  id serial,
  login character varying(20) not null,
  password character varying(20) not null,
  sip integer,
  profile integer
);

alter table terminal add constraint pk__terminal
  primary key (id);

alter table terminal add constraint fk_terminal_profile_id_profile
  foreign key (profile) references profile(id);

alter table terminal add constraint fk_terminal_sip_id_sip
  foreign key (sip) references sip(id);
