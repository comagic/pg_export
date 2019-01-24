select json_agg(x)
  from (select n.nspname as schema,
               p.proname as name,
               l.lanname as language,
               p.proacl as acl,
               p.prosrc as body,
               p.proretset as setof,
               format_type(p.prorettype, -1) as returns_type_name,
               tn.nspname as returns_type_schema,
               p.proiswindow as window,
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
                         'name', p.proargnames[n],
                         'mode', coalesce(p.proargmodes[n], 'i'),
                         'default', pg_get_function_arg_default(p.oid, n::int))
                        order by n) filter (where p.proargmodes is null or p.proargmodes[n] in ('i', 'o')), '[]')
                  from unnest(coalesce(p.proallargtypes, p.proargtypes)) with ordinality u(typeoid, n)
               ) as arguments,
               (select coalesce(json_agg(json_build_object(
                         'type', format_type(u.typeoid, -1),
                         'name', p.proargnames[n])
                        order by n) filter (where p.proargmodes[n] = 't'), '[]')
                  from unnest(coalesce(p.proallargtypes, p.proargtypes)) with ordinality u(typeoid, n)
               ) as columns,
               d.description as comment
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
               not p.proisagg
         order by 1, 2) as x
