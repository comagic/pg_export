create table alembic_version (
  version_num character varying(32) not null
);

alter table alembic_version add constraint alembic_version_pkc
  primary key (version_num);
