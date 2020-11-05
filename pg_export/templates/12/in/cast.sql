select json_agg(x)
  from (select format_type(c.castsource, -1) as source,
               format_type(c.casttarget, -1) as target,
               quote_literal(d.description) as comment,
               c.castfunc::regprocedure as func,
               c.castcontext as context,
               c.castmethod as method
          from pg_cast c
          {% with objid='c.oid', objclass='pg_cast' -%} {% include '12/in/_join_description_as_d.sql' %} {% endwith %}
         where c.oid > {{ last_builin_oid }} and
               {% with objid='c.oid', objclass='pg_cast' %} {% include '12/in/_not_part_of_extension.sql' %} {% endwith %}
         order by 1, 2) as x
