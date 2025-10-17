select quote_ident(t.evtname) as name,
       t.evtevent as event,
       t.evttags as tags,
       t.evtenabled as enabled,
       p.proname as function_name,
       pn.nspname as function_schema
  from pg_event_trigger t
 inner join pg_proc p
         on p.oid = t.evtfoid
 inner join pg_namespace pn
         on pn.oid = p.pronamespace
