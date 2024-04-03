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
{%- if partition_by %}
partition by {%- if partition_by.strategy == 'r' %} range
             {%- elif partition_by.strategy == 'l' %} list
             {%- elif partition_by.strategy == 'h' %} hash
             {%- endif %} ({{ partition_by.columns|join(', ') }})
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
  primary key {% with idx_columns=primary_key.idx_columns %} {%- include 'out/_index_columns.sql' %} {%- endwith %}
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
  unique {% if u.nulls_not_distinct -%}nulls not distinct {% endif %}
  {%- with idx_columns=u.idx_columns %} {%- include 'out/_index_columns.sql' %} {%- endwith %}
  {%- if u.deferrable %} deferrable {%- endif %}
  {%- if u.deferred %} initially deferred {%- endif %};
{%- endfor %}

{%- for e in exclusions %}

alter table {{ full_name }} add constraint {{ e.name }}
  exclude using {{ e.access_method }} {% with idx_columns=e.idx_columns %} {%- include 'out/_index_columns.sql' %} {%- endwith %}
  {%- if e.predicate %} where ({{ e.predicate }}) {%- endif %}
  {%- if e.deferrable %} deferrable {%- endif %}
  {%- if e.deferred %} initially deferred {%- endif %};
{%- endfor %}

{%- for c in checks %}

alter table {{ full_name }} add constraint {{ c.name }}
  check ({{ c.src }})
  {%- if c.not_valid %} not valid {%- endif %};
{%- endfor %}

{%- include 'out/_rule.sql' %}

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

{%- if replica_identity != 'd' and kind != 'f' %}

alter table {{ full_name }} replica identity
  {%- if replica_identity == 'f' %} full {%- endif %}
  {%- if replica_identity == 'n' %} nothing {%- endif %}
  {%- if replica_identity == 'i' %} using index {{ replica_identity_index }} {%- endif %};
{%- endif %}

{%- if columns|selectattr('statistics')|first() %}
{% for c in columns if c.statistics %}
alter table only {{ full_name }} alter column {{ c.name }} set statistics {{ c.statistics }};
{%- endfor %}
{%- endif %}

