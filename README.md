## pg-export - pg to git converter

Export structure of database to object files for control version system

## structure of result directories
```
casts:
  ...
data:
  schema1:
    table1.sql
  schema2:
    ...
extensions:
  ...
publications:
  ...
schemas:
  schema1:
    aggregate:
      ...
    domains:
      ...
    functions:
      ...
    operators:
      ...
    sequences:
      ...
    tables:
      ...
    triggers:
      ...
    types:
      ...
    views:
      ...
  schema2
    ...
```

## installation

```
pip install pg-export
```

## usage

```
usage: pg_export [--help] [--version] [--clean] [--ignore-version] [--echo-queries] [-h HOST] [-p PORT] [-U USER] [-W PASSWORD] [-j JOBS] [-z TIMEZONE] [-n SCHEMA] [-N EXCLUDE_SCHEMA] database out_dir

Export structure of database to object files for control version system

positional arguments:
  database              source database name
  out_dir               directory for object files

options:
  --help                show this help message and exit
  --version             show program's version number and exit
  --clean               clean out_dir if not empty (env variable PG_EXPORT_AUTOCLEAN=true)
  --ignore-version      try exporting an unsupported server version
  --echo-queries        echo commands sent to server
  -h HOST, --host HOST  host for connect db (env variable PG_HOST=<host>)
  -p PORT, --port PORT  port for connect db (env variable PG_PORT=<port>)
  -U USER, --user USER  user for connect db (env variable PG_USER=<user>)
  -W PASSWORD, --password PASSWORD
                        password for connect db (env variable PG_PASSWORD=<password>)
  -j JOBS, --jobs JOBS  number of connections
  -z TIMEZONE, --timezone TIMEZONE
                        timezone for constraints, partitions etc.
  -n SCHEMA, --schema SCHEMA
                        dump the specified schema(s) only
  -N EXCLUDE_SCHEMA, --exclude-schema EXCLUDE_SCHEMA
                        do NOT dump the specified schema(s)
```

## examples

```
pg_export -h 127.0.0.1 -p 5432 -U postgres -j 4 my_database /tmp/my_database_structure/
```
