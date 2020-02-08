select json_agg(x)
  from (select n.nspname as schema,
               quote_ident(p.proname) as name,
               l.lanname as language,
               p.proacl as acl,
               p.prosrc as body,
               p.proretset as setof,
               format_type(p.prorettype, -1) as returns_type_name,
               tn.nspname as returns_type_schema,
               p.prokind as kind,
               p.provolatile as volatile,
               p.proleakproof as leakproof,
               p.proisstrict as strict,
               p.prosecdef as security_definer,
               p.proparallel as parallel,
               p.procost as cost,
               p.prorows as rows,
               p.proconfig as config,
               (select coalesce(json_agg(json_build_object(
                         'type', format_type(u.typeoid, -1),
                         'name', quote_ident(p.proargnames[n]),
                         'mode', coalesce(p.proargmodes[n], 'i'),
                         'default', pg_get_function_arg_default(p.oid, n::int))
                        order by n) filter (where p.proargmodes is null or p.proargmodes[n] in ('i', 'o', 'b', 'v')), '[]')
                  from unnest(coalesce(p.proallargtypes, p.proargtypes)) with ordinality u(typeoid, n)
               ) as arguments,
               (select coalesce(json_agg(json_build_object(
                         'type', format_type(u.typeoid, -1),
                         'name', quote_ident(p.proargnames[n]))
                        order by n) filter (where p.proargmodes[n] = 't'), '[]')
                  from unnest(coalesce(p.proallargtypes, p.proargtypes)) with ordinality u(typeoid, n)
               ) as columns,
               (select coalesce(json_agg(json_build_object(
                         'schema', dn.nspname,
                         'name', dc.relname) order by dn.nspname, dc.relname), '[]')
                  from pg_depend dd
                 inner join pg_type dt
                         on dt.oid = dd.refobjid
                 inner join pg_class dc
                         on dc.oid = dt.typrelid
                 inner join pg_namespace dn
                         on dn.oid = dc.relnamespace
                where dd.objid = p.oid and
                      dc.relkind='r' and
                      dd.deptype = 'n'
               ) as depend_on_tables,
               p.probin as binary_file,
               quote_literal(d.description) as comment
          from pg_proc p
         inner join pg_namespace n
                 on n.oid = p.pronamespace
         inner join pg_language l
                 on l.oid = p.prolang
         inner join pg_type t
                 on t.oid = p.prorettype
         inner join pg_namespace tn
                 on tn.oid = t.typnamespace
          left join pg_description d
                 on d.objoid = p.oid
         where n.nspname not in ('pg_catalog', 'pg_toast', 'information_schema') and
               p.prokind in ('f', 'p', 'w')
         order by 1, 2, p.proargnames) as x

