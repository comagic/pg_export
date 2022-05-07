select quote_ident(s.srvname) as name,
       quote_ident(w.fdwname) as wrapper,
       quote_literal(d.description) as comment,
       s.srvacl::text[] as acl,
       quote_literal(s.srvtype) as type,
       quote_literal(s.srvversion) as version,
       (select coalesce(
                 json_agg(
                   json_build_object(
                     'name', quote_ident(sp.name),
                     'value', quote_literal(ss.value))),
                 '[]')
          from unnest(s.srvoptions) u(str)
         cross join split_part(u.str, '=', 1) sp(name)
         cross join substr(u.str, length(sp.name) + 2) ss(value)) as options,
       (select coalesce(
                 json_agg(
                   json_build_object(
                     'role', quote_ident(a.rolname),
                     'options', (select coalesce(
                                          json_agg(
                                            json_build_object(
                                              'name', quote_ident(sp.name),
                                              'value', quote_literal(ss.value))),
                                          '[]')
                                   from unnest(m.umoptions) u(str)
                                  cross join split_part(u.str, '=', 1) sp(name)
                                  cross join substr(u.str, length(sp.name) + 2) ss(value))) order by a.rolname nulls last),
                 '[]')
          from pg_user_mappings m
          left join pg_authid a
                 on a.oid = m.umuser
         where m.srvid = s.oid) as user_mappings
  from pg_foreign_server s
  {% with objid='s.oid', objclass='pg_foreign_server' -%} {% include 'in/_join_description_as_d.sql' %} {% endwith %}
 inner join pg_foreign_data_wrapper w
         on w.oid = s.srvfdw
 order by 1
