select pubname as name,
       puballtables as all_tables,
       pubinsert as insert,
       pubupdate as update,
       pubdelete as delete,
       pubtruncate as truncate,
       false as publish_via_partition_root,
       (select coalesce(
                 array_agg(
                   pr.prrelid::regclass::text
                   order by pr.prrelid::regclass::text),
                 '{}')
          from pg_publication_rel pr
         where pr.prpubid = p.oid) as tables
  from pg_publication p;

