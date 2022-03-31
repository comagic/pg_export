create or replace function film_not_in_stock(
  p_film_id  integer,
  p_store_id integer,
  OUT        p_film_count integer
) returns SETOF integer as $$
    SELECT inventory_id
    FROM inventory
    WHERE film_id = $1
    AND store_id = $2
    AND NOT inventory_in_stock(inventory_id);
$$ language sql;
