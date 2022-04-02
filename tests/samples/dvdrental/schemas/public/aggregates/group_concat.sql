create aggregate group_concat(text) (
  sfunc = _group_concat,
  stype = text
);
