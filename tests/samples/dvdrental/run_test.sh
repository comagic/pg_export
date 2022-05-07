set -e

export PGHOST=localhost
export PGUSER=postgres
export PGPASSWORD=postgres1723
export VERSION=$1
export PGPORT=1723

echo run docker container: pg_export_test_$VERSION
docker ps -q --filter "name=pg_export_test_$VERSION" | grep -q . && docker stop pg_export_test_$VERSION
docker ps -qa --filter "name=pg_export_test_$VERSION" | grep -q . && docker rm pg_export_test_$VERSION
docker run --name pg_export_test_$VERSION -p $PGPORT:5432 -e POSTGRES_PASSWORD=$PGPASSWORD -d postgres:$VERSION
sleep 2

echo build sample db
psql -c "create database pg_export_test" postgres > /dev/null
psql -f source.sql pg_export_test > /dev/null
echo export sample db
pg_export --clean pg_export_test /tmp/pg_export_test
echo diff export with sample:
diff -qr schemas /tmp/pg_export_test/schemas && echo test result: PASSED || echo test result: FAILED

echo remove docker container
docker stop pg_export_test_$VERSION > /dev/null
docker rm pg_export_test_$VERSION > /dev/null
