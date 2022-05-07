select quote_ident(n.nspname) as schema,
       quote_ident(p.proname) as name,
       quote_literal(d.description) as comment,
       a.aggkind as kind,
       ({% include 'in/_argument.sql' %}) as arguments,
       a.aggtransfn as sfunc,
       format_type(a.aggtranstype, -1) as stype,
       a.aggtransspace as sspace,
       a.aggfinalfn as finalfunc,
       a.aggfinalextra as finalfunc_extra,
       a.aggcombinefn as combinefunc,
       a.aggserialfn as serialfunc,
       a.aggdeserialfn as deserialfunc,
       quote_literal(a.agginitval) as initcond,
       a.aggmtransfn as msfunc,
       a.aggminvtransfn as minvfunc,
       format_type(a.aggmtranstype, -1) as mstype,
       a.aggmtransspace as msspace,
       a.aggmfinalfn as mfinalfunc,
       a.aggmfinalextra as mfinalfunc_extra,
       quote_literal(a.aggminitval) as minitcond,
       op.oprname as sortop,
       p.proacl as acl
  from pg_aggregate a
 inner join pg_proc p
         on p.oid = a.aggfnoid
 inner join pg_namespace n
         on n.oid = p.pronamespace
  left join pg_operator op
         on op.oid = a.aggsortop
  {% with objid='p.oid', objclass='pg_proc' -%} {% include 'in/_join_description_as_d.sql' %} {% endwith %}
 where n.nspname not in ('pg_catalog', 'pg_toast', 'information_schema') and
       {% with objid='p.oid', objclass='pg_proc' %} {% include 'in/_not_part_of_extension.sql' %} {% endwith %}
 order by 1, 2, arguments
