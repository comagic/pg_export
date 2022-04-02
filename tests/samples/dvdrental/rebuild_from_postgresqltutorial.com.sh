set -e

export PGHOST=localhost
export PGUSER=postgres
export PGPASSWORD=postgres1723
export VERSION=$1
export PGPORT=2723

rm -rf dvd_tmp dvdrental.zip dvdrental.tar

wget https://www.postgresqltutorial.com/wp-content/uploads/2019/05/dvdrental.zip
unzip dvdrental.zip
mkdir dvd_tmp
tar -xf dvdrental.tar -C dvd_tmp/

echo
echo restart docker postgres:$VERSION
docker ps -q --filter "name=dvdrental_$VERSION" | grep -q . && docker stop dvdrental_$VERSION
docker ps -qa --filter "name=dvdrental_$VERSION" | grep -q . && docker rm dvdrental_$VERSION
docker run --name dvdrental_$VERSION -p $PGPORT:5432 -e POSTGRES_PASSWORD=$PGPASSWORD -d postgres:$VERSION
sleep 2

psql -c "create database dvdrental" postgres
pg_restore -d dvdrental dvd_tmp
pg_export --clean dvdrental dvdrental_sample
rm -r schemas
mv dvdrental_sample/schemas ./
rm -rf dvdrental_sample

rm -rf dvd_tmp dvdrental.zip dvdrental.tar
docker stop dvdrental_$VERSION
docker rm dvdrental_$VERSION
