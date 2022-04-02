select quote_ident(n.nspname) as schema,
       quote_ident(p.proname) as name,
       quote_ident(l.lanname) as language,
       quote_literal(d.description) as comment,
       p.proacl::text[] as acl,
       p.prosrc as body,
       p.proretset as setof,
       format_type(p.prorettype, -1) as returns_type_name,
       quote_ident(tn.nspname) as returns_type_schema,
       p.prokind as kind,
       p.provolatile as volatile,
       p.proleakproof as leakproof,
       p.proisstrict as strict,
       p.prosecdef as security_definer,
       p.proparallel as parallel,
       p.procost::integer as cost,
       p.prorows::integer as rows,
       p.proconfig as config,
       ({% include 'in/_argument.sql' %}) as arguments,
       p.probin as binary_file,
       (select coalesce(
                 json_agg(
                   json_build_object(
                     'type', format_type(u.typeoid, -1),
                     'name', quote_ident(p.proargnames[n]))
                   order by n) filter (where p.proargmodes[n] = 't'),
                 '[]')
          from unnest(coalesce(p.proallargtypes, p.proargtypes)) with ordinality u(typeoid, n)) as columns
  from pg_proc p
 inner join pg_namespace n
         on n.oid = p.pronamespace
 inner join pg_language l
         on l.oid = p.prolang
 inner join pg_type t
         on t.oid = p.prorettype
 inner join pg_namespace tn
         on tn.oid = t.typnamespace
  {% with objid='p.oid', objclass='pg_proc' -%} {% include 'in/_join_description_as_d.sql' %} {% endwith %}
 where n.nspname not in ('pg_catalog', 'pg_toast', 'information_schema') and
       p.prokind in ('f', 'p', 'w') and
       abs(hashtext(p.proname)) % 4 = {{ chunk }} and
       {% with objid='p.oid', objclass='pg_proc' %} {% include 'in/_not_part_of_extension.sql' %} {% endwith %}
 order by 1, 2, arguments
