select coalesce(
         json_agg(
           json_build_object(
             'type', format_type(u.typeoid, -1),
             'name', quote_ident(nullif(p.proargnames[n], '')),
             'mode', coalesce(p.proargmodes[n], 'i'),
             'default', pg_get_function_arg_default(p.oid, n::int))
           order by n) filter (where p.proargmodes is null
                                     or
                                     p.proargmodes[n] in ('i', 'o', 'b', 'v')),
         '[]')::jsonb
  from unnest(coalesce(p.proallargtypes, p.proargtypes)) with ordinality u(typeoid, n)
