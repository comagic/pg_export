select quote_ident(n.nspname) as schema,
       quote_ident(c.relname) as name,
       quote_literal(d.description) as comment,
       c.relacl::text[] as acl,
       nullif(seqstart, 1) as start,
       nullif(seqincrement, 1) as increment,
       nullif(seqmin, 1) as min,
       nullif(nullif(seqmax, 2^31-1), 2^63-1)::bigint as max,
       nullif(seqcache, 1) as cache,
       seqcycle as cycle
  from pg_sequence s
 inner join pg_class c
         on c.oid = s.seqrelid
 inner join pg_namespace n
         on n.oid = c.relnamespace
  {% with objid='c.oid', objclass='pg_class' -%} {% include 'in/_join_description_as_d.sql' %} {% endwith %}
 where n.nspname not in ('pg_catalog', 'pg_toast', 'information_schema') and
       not exists (select *
                     from pg_depend dep
                    where dep.objid = c.oid and
                          dep.classid = 'pg_class'::regclass and
                          dep.deptype in ('a', 'e'))
