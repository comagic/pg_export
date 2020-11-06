create cast ({{ source }} as {{ target }})
    {%- if method == 'f' %}
    with function {{ func }}
    {%- endif %}
    {%- if method == 'i' %}
    with inout
    {%- endif %}
    {%- if method == 'b' %}
    without function
    {%- endif %}
    {%- if context == 'a' %}
    as assignment
    {%- endif %}
    {%- if context == 'i' %}
    as implicit
    {%- endif %};


