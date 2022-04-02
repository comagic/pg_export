set check_function_bodies to off;
\ir schemas/public/types/mpaa_rating.sql
create domain public.year as integer constraint year_check check (((value >= 1901) and (value <= 2155))); --FIXME

\ir schemas/public/functions/_group_concat.sql
\ir schemas/public/functions/film_in_stock.sql
\ir schemas/public/functions/film_not_in_stock.sql
\ir schemas/public/functions/get_customer_balance.plpgsql
\ir schemas/public/functions/inventory_held_by_customer.plpgsql
\ir schemas/public/functions/inventory_in_stock.plpgsql
\ir schemas/public/functions/last_day.sql
\ir schemas/public/triggers/last_updated.plpgsql
\ir schemas/public/aggregates/group_concat.sql

\ir schemas/public/sequences/actor_actor_id_seq.sql
\ir schemas/public/sequences/address_address_id_seq.sql
\ir schemas/public/sequences/category_category_id_seq.sql
\ir schemas/public/sequences/city_city_id_seq.sql
\ir schemas/public/sequences/country_country_id_seq.sql
\ir schemas/public/sequences/customer_customer_id_seq.sql
\ir schemas/public/sequences/film_film_id_seq.sql
\ir schemas/public/sequences/inventory_inventory_id_seq.sql
\ir schemas/public/sequences/language_language_id_seq.sql
\ir schemas/public/sequences/payment_payment_id_seq.sql
\ir schemas/public/sequences/rental_rental_id_seq.sql
\ir schemas/public/sequences/staff_staff_id_seq.sql
\ir schemas/public/sequences/store_store_id_seq.sql

\ir schemas/public/tables/actor.sql
\ir schemas/public/tables/category.sql
\ir schemas/public/tables/country.sql
\ir schemas/public/tables/city.sql
\ir schemas/public/tables/address.sql
\ir schemas/public/tables/customer.sql
\ir schemas/public/tables/language.sql
\ir schemas/public/tables/film.sql
\ir schemas/public/tables/film_actor.sql
\ir schemas/public/tables/film_category.sql
\ir schemas/public/tables/inventory.sql
\ir schemas/public/tables/staff.sql
\ir schemas/public/tables/rental.sql
\ir schemas/public/tables/payment.sql
\ir schemas/public/tables/store.sql

\ir schemas/public/functions/rewards_report.plpgsql

\ir schemas/public/views/actor_info.sql
\ir schemas/public/views/customer_list.sql
\ir schemas/public/views/film_list.sql
\ir schemas/public/views/nicer_but_slower_film_list.sql
\ir schemas/public/views/sales_by_film_category.sql
\ir schemas/public/views/sales_by_store.sql
\ir schemas/public/views/staff_list.sql
