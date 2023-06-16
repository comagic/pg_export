create domain year as integer
  constraint year_check check (VALUE >= 1901 AND VALUE <= 2155);
