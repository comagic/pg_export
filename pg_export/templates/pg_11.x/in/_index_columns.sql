select json_agg(
         json_build_object(
           'name', pg_get_indexdef(idx.indexrelid, i::int, true),
           'order', format('%s%s',
                           case
                             when (u.option & {{ INDOPTION_DESC }}) <> 0
                               then ' desc'
                           end,
                           case
                             when (u.option & {{ INDOPTION_DESC }}) <> 0 and
                                  not (u.option & {{ INDOPTION_NULLS_FIRST }}) <> 0
                               then ' nulls last'
                             when not (u.option & {{ INDOPTION_DESC }}) <> 0 and
                                  (u.option & {{ INDOPTION_NULLS_FIRST }}) <> 0
                               then ' nulls first'
                           end),
           'collate', quote_ident(coll.collname),
           'opclass', oc.opcname,
           'is_include', u.i > indnkeyatts,
           'operator', op.oprname) order by u.i)
  from unnest(idx.indkey::int[], idx.indcollation, idx.indclass, idx.indoption,
              {% if operators %} {{ operators }} {% else %} null::oid[] {% endif %} ) with ordinality u(key, coll, class, option, op_oid, i)
  left join pg_attribute ia  -- index attribute
         on ia.attrelid = idx.indexrelid and
            ia.attnum = u.i
  left join pg_attribute a  -- table attribute
         on a.attrelid = idx.indrelid and
            a.attnum = u.key
  left join pg_collation coll
         on coll.oid = ia.attcollation and
            coll.collname <> 'default' and
            a.attcollation is distinct from ia.attcollation
  left join pg_opclass oc
         on oc.oid = u.class and
            not oc.opcdefault
  left join pg_operator op
         on op.oid = u.op_oid
