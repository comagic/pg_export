create operator {{ full_name }} (
  function = {{ func }}
  {%- if left_type != '-' %},
  leftarg = {{ left_type }}
  {%- endif%}
  {%- if right_type != '-' %},
  rightarg = {{ right_type }}
  {%- endif%}
  {%- if commutator %},
  commutator = {{ commutator }}
  {%- endif%}
  {%- if negator %},
  negator = {{ negator }}
  {%- endif%}
  {%- if restrict_func != '-' %},
  restrict = {{ restrict_func }}
  {%- endif%}
  {%- if join_func != '-' %},
  join = {{ join_func }}
  {%- endif%}
  {%- if hashes %},
  hashes
  {%- endif%}
  {%- if merges %},
  merges
  {%- endif%}
);

