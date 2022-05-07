create {%- if unlogged %} unlogged {%- endif %}
       {%- if kind == 'f' %} foreign {%- endif %} table {{ full_name }} (
  {%- include 'out/_attribute.sql' %}
)
{%- if options %}
with ({{ options|join(', ') }})
{%- endif %}
{%- if inherits %}
inherits ({{ inherits|join_attr('table', ', ') }})
{%- endif %}

{%- if distributed_type == 'r' %}
distributed replicated
{%- elif distributed_by %}
distributed by ({{distributed_by|join(', ')}})
{%- elif distributed_type == 'p' %}
distributed randomly
{%- endif %}

{%- if gp_partitions %}
partition by {%- if gp_partition_kind == 'l' %} list
             {%- elif gp_partition_kind == 'r' %} range
             {%- endif %} ({{ gp_partition_columns|join(', ') }})
  {%- if gp_subpartition_template %}
  subpartition by {%- if gp_subpartition_kind == 'l' %} list
                  {%- elif gp_subpartition_kind == 'r' %} range
                  {%- endif %} ({{ gp_subpartition_columns|join(', ') }})
    subpartition template (
      {%- for st in gp_subpartition_template %}
      start ({{ st.start }}) {%- if st.start_inclusive %} inclusive {%- else %} exclusive {%- endif %}
      end ({{ st.end }}) {%- if st.end_inclusive %} inclusive {%- else %} exclusive {%- endif %}
      every ({{ st.every }})
      {%- if not loop.last %},{% endif %}
      {%- endfor %})
  {%- endif %}
  ({% for p in gp_partitions -%}
   start ({{ p.start }}) {%- if p.start_inclusive %} inclusive {%- else %} exclusive {%- endif %}
   end   ({{ p.end }}) {%- if p.end_inclusive %} inclusive {%- else %} exclusive {%- endif %}
   every ({{ p.every }})
   {%- if not loop.last %}{{ ',\n   ' }}{% endif %}
   {%- endfor %})
{%- endif %}

{%- if server %}
server {{ server }}
{%- endif %}
{%- if foreign_options %}
options ({{ foreign_options|join(', ') }})
{%- endif %};

{%- if attach %}

alter table only {{ attach.table }} attach partition {{ full_name }}
  {%- if attach.is_default %} default
  {%- elif attach.in %} for values in ({{ attach.in }})
  {%- elif attach.from %} for values from ({{ attach.from }}) to ({{ attach.to }})
  {%- endif %};
{%- endif %}

{%- if grants or columns|selectattr('grants')|first() %}
{% if grants %}
{{ grants }}
{%- endif %}
{%- for c in columns if c.grants %}
{{ c.grants }}
{%- endfor %}
{%- endif %}

{%- if comment or columns|selectattr('comment')|first() %}
{% if comment %}
comment on table {{ full_name }} is {{ comment }};
{%- endif %}
{%- for c in columns if c.comment %}
comment on column {{ full_name }}.{{ c.name }} is {{ c.comment }};
{%- endfor %}
{%- endif %}

{%- if primary_key %}

alter table {{ full_name }} add constraint {{ primary_key.name }}
  primary key ({{ primary_key.columns|join(', ') }})
  {%- if primary_key.deferrable %} deferrable {%- endif %}
  {%- if primary_key.deferred %} initially deferred {%- endif %};
{%- endif %}

{%- for fk in foreign_keys %}

alter table {{ full_name }} add constraint {{ fk.name }}
  foreign key ({{ fk.columns|join(', ') }}) references {{ fk.ftable }}({{ fk.fcolumns|join(', ') }})
  {%- if fk.match_type == 'f' %} match full {%- endif %}
  {%- if fk.match_type == 'p' %} match partial {%- endif %}
  {%- if fk.on_update == 'r' %} on update restrict {%- endif %}
  {%- if fk.on_update == 'c' %} on update cascade {%- endif %}
  {%- if fk.on_update == 'n' %} on update set null {%- endif %}
  {%- if fk.on_update == 'd' %} on update set default {%- endif %}
  {%- if fk.on_delete == 'r' %} on delete restrict {%- endif %}
  {%- if fk.on_delete == 'c' %} on delete cascade {%- endif %}
  {%- if fk.on_delete == 'n' %} on delete set null {%- endif %}
  {%- if fk.on_delete == 'd' %} on delete set default {%- endif %}
  {%- if fk.deferrable %} deferrable {%- endif %}
  {%- if fk.deferred %} initially deferred {%- endif %}
  {%- if fk.not_valid %} not valid {%- endif %};
{%- endfor %}

{%- for u in uniques %}

alter table {{ full_name }} add constraint {{ u.name }}
  unique ({{ u.columns|join(', ') }})
  {%- if u.deferrable %} deferrable {%- endif %}
  {%- if u.deferred %} initially deferred {%- endif %};
{%- endfor %}

{%- for e in exclusions %}

alter table {{ full_name }} add constraint {{ e.name }}
  exclude using {{ e.access_method }} ({{ e.columns|concat_items(' with ', e.operators)|join(', ') }})
  {%- if e.deferrable %} deferrable {%- endif %}
  {%- if e.deferred %} initially deferred {%- endif %};
{%- endfor %}

{%- for c in checks %}

alter table {{ full_name }} add constraint {{ c.name }}
  check ({{ c.src }})
  {%- if c.not_valid %} not valid {%- endif %};
{%- endfor %}

{%- for t in triggers %}

create {%- if t.constraint %} constraint {%- endif %} trigger {{ t.name }}
  {{ t.type }} {{ t.actions|join(' or ') }} on {{ full_name }}
  {%- if t.ftable %} from {{ t.ftable }} {%- endif %}
  {%- if t.deferrable %} deferrable {%- endif %}
  {%- if t.deferred %} initially deferred {%- endif %}
  {%- if t.new_table %} referencing new table as {{ t.new_table }} {%- endif %}
  {%- if t.old_table %} referencing old table as {{ t.old_table }} {%- endif %}
  for each {{ t.each }} {% if t.condition -%} when ({{ t.condition }}) {% endif -%}
  execute function {{ t.function }}({{ t.arguments }});
{%- endfor %}

{%- include 'out/_index.sql' %}

{%- if clustered_index %}

alter table {{ full_name }} cluster on {{ clustered_index }};
{%- endif %}

{%- if columns|selectattr('statistics')|first() %}
{% for c in columns if c.statistics %}
alter table only {{ full_name }} alter column {{ c.name }} set statistics {{ c.statistics }};
{%- endfor %}
{%- endif %}

