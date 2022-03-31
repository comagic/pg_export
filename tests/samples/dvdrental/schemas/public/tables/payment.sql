create table payment (
  payment_id integer not null default nextval('payment_payment_id_seq'::regclass),
  customer_id smallint not null,
  staff_id smallint not null,
  rental_id integer not null,
  amount numeric(5,2) not null,
  payment_date timestamp without time zone not null
);

alter table payment add constraint payment_pkey
  primary key (payment_id);

alter table payment add constraint payment_customer_id_fkey
  foreign key (customer_id) references customer(customer_id) on update cascade on delete restrict;

alter table payment add constraint payment_rental_id_fkey
  foreign key (rental_id) references rental(rental_id) on update cascade on delete set null;

alter table payment add constraint payment_staff_id_fkey
  foreign key (staff_id) references staff(staff_id) on update cascade on delete restrict;

create index idx_fk_customer_id on payment(customer_id);

create index idx_fk_rental_id on payment(rental_id);

create index idx_fk_staff_id on payment(staff_id);
