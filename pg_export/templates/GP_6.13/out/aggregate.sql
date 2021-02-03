create aggregate {{ full_name }}({% include 'GP_6.13/out/_argument.sql' %}) (
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
{%- if minitcond %},
  minitcond = {{ minitcond }}
{%- endif %}
{%- if sortop %},
  sortop = {{ sortop }}
{%- endif %}
{%- if kind == 'h' %},
  hypothetical
{%- endif %}
);
{%- if acl %}

{{ acl|acl_to_grants('function', signature) }}
{%- endif %}

{%- if comment %}

comment on aggregate {{ signature }} is {{ comment }};
{%- endif %}

