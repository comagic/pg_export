set -e

export PGHOST=localhost
export PGUSER=postgres
export PGPASSWORD=postgres1723
export VERSION=$1
export PGPORT=1723

echo
docker ps -q --filter "name=pg_export_test_$VERSION" | grep -q . && docker stop pg_export_test_$VERSION
docker ps -qa --filter "name=pg_export_test_$VERSION" | grep -q . && docker rm pg_export_test_$VERSION
docker run --name pg_export_test_$VERSION -p $PGPORT:5432 -e POSTGRES_PASSWORD=$PGPASSWORD -d postgres:$VERSION
sleep 2

psql -c "create database pg_export_test" postgres
psql -f source.sql pg_export_test > /dev/null
pg_export --clean pg_export_test /tmp/pg_export_test
diff -qr schemas /tmp/pg_export_test/schemas

docker stop pg_export_test_$VERSION
docker rm pg_export_test_$VERSION
