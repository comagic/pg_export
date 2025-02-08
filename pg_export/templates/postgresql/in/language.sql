select quote_ident(l.lanname) as name,
       lanispl as procedural,
       lanpltrusted as trusted
  from pg_language l
 where l.oid > {{ last_builtin_oid }} and
       {% with objid='l.oid', objclass='pg_language' %} {% include 'in/_not_part_of_extension.sql' %} {% endwith %}
 order by 1
