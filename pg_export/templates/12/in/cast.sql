select json_agg(x)
  from (select format_type(castsource, -1) as source,
               format_type(casttarget, -1) as target,
               castfunc::regprocedure as func,
               castcontext as context,
               castmethod as method
          from pg_cast с
         where с.oid > {{ last_builin_oid }}
         order by 1, 2) as x
