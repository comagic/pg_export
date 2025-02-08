select coalesce(json_agg(x), '[]')
  from (select quote_ident(a.attname) as name,
               format_type(a.atttypid, a.atttypmod) as type,
               quote_ident(coll.collname) as collate,
               a.attnotnull as not_null,
               pg_get_expr(cd.adbin, cd.adrelid) as default,
               quote_literal(d.description) as comment,
               a.attacl as acl,
               nullif(a.attstattarget, -1) as statistics
          from pg_attribute a
         inner join pg_type ct
                 on ct.oid = a.atttypid
          left join pg_collation coll
                 on coll.oid = a.attcollation and
                    a.attcollation <> ct.typcollation
          left join pg_attrdef cd
                 on cd.adrelid = a.attrelid and
                    cd.adnum = a.attnum
          {% with objid='c.oid', objclass='pg_class', objsubid='a.attnum' -%} {% include 'in/_join_description_as_d.sql' %} {% endwith %}
         where a.attrelid = c.oid and
               a.attnum > 0 and
               not a.attisdropped
         order by a.attnum) as x
