select json_agg(x)
  from (select quote_ident(n.nspname) as schema,
               quote_ident(p.proname) as name,
               a.aggkind as kind,
               ({% include '11/in/function_argument.sql' %}) as arguments,
               a.aggtransfn as sfunc,
               format_type(a.aggtranstype, -1) as stype,
               a.aggtransspace as sspace,
               a.aggfinalfn as finalfunc,
               a.aggfinalextra as finalfunc_extra,
               a.aggfinalmodify as finalfunc_modify,
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
               a.aggmfinalmodify as mfinalfunc_modify,
               quote_literal(a.aggminitval) as minitcond,
               op.oprname as sortop,
               p.proacl as acl,
               quote_literal(d.description) as comment
          from pg_aggregate a
         inner join pg_proc p
                 on p.oid = a.aggfnoid
         inner join pg_namespace n
                 on n.oid = p.pronamespace
          left join pg_operator op
                 on op.oid = a.aggsortop
          left join pg_description d
                 on d.objoid = p.oid
         where n.nspname not in ('pg_catalog', 'pg_toast', 'information_schema')
         order by 1, 2) as x
