create aggregate {{ full_name }}({% include 'out/_argument.sql' %}) (
  sfunc = {{ sfunc }},
  stype = {{ stype }}
{%- if sspace %},
  sspace = {{ sspace }}
{%- endif %}
{%- if finalfunc != '-' %},
  finalfunc = {{ finalfunc }}
{%- endif %}
{%- if finalfunc_extra %},
  finalfunc_extra
{%- endif %}
{%- if finalfunc != '-' and finalfunc_modify %},
  finalfunc_modify = {%- if finalfunc_modify == 'r' %} read_only
                     {%- elif finalfunc_modify == 'r' %} shareable
                     {%- elif finalfunc_modify == 'w' %} read_write
                     {%- endif %}
{%- endif %}
{%- if combinefunc != '-' %},
  combinefunc = {{ combinefunc }}
{%- endif %}
{%- if serialfunc != '-' %},
  serialfunc = {{ serialfunc }}
{%- endif %}
{%- if deserialfunc != '-' %},
  deserialfunc = {{ deserialfunc }}
{%- endif %}
{%- if initcond %},
  initcond = {{ initcond }}
{%- endif %}
{%- if msfunc != '-' %},
  msfunc = {{ msfunc }}
{%- endif %}
{%- if minvfunc != '-' %},
  minvfunc = {{ minvfunc }}
{%- endif %}
{%- if mstype != '-' %},
  mstype = {{ mstype }}
{%- endif %}
{%- if msspace %},
  msspace = {{ msspace }}
{%- endif %}
{%- if mfinalfunc != '-' %},
  mfinalfunc = {{ mfinalfunc }}
{%- endif %}
{%- if mfinalfunc_extra %},
  mfinalfunc_extra = {{ mfinalfunc_extra }}
{%- endif %}
{%- if mfinalfunc != '-' and mfinalfunc_modify %},
  mfinalfunc_modify = {%- if mfinalfunc_modify == 'r' %} read_only
                      {%- elif mfinalfunc_modify == 'r' %} shareable
                      {%- elif mfinalfunc_modify == 'w' %} read_write
                      {%- endif %}
{%- endif %}
{%- if minitcond %},
  minitcond = {{ minitcond }}
{%- endif %}
{%- if sortop %},
  sortop = {{ sortop }}
{%- endif %}
{%- if kind == 'h' %},
  hypothetical
{%- endif %}
{%- if parallel == 'r' %},
  parallel = restricted
{%- endif %}
{%- if parallel == 's' %},
  parallel = safe
{%- endif %}
);

{%- if grants %}

{{ grants }}
{%- endif %}

{%- if comment %}

comment on aggregate {{ signature }} is {{ comment }};
{%- endif %}

