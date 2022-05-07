create or replace function _group_concat(text, text) returns text as $$
SELECT CASE
  WHEN $2 IS NULL THEN $1
  WHEN $1 IS NULL THEN $2
  ELSE $1 || ', ' || $2
END
$$ language sql immutable;
