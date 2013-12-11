#!/usr/bin/env sh

EXPECTED=$(openssl rand -hex 16)
CONTAINER_NAME=$(openssl rand -hex 16)
DB_NAME="a$(openssl rand -hex 16)"
DB_USER="a$(openssl rand -hex 16)"
DB_PASSWORD=$(openssl rand -hex 16)
TEST_VOLUME=store
MOUNT_PATH=/var/lib/postgresql/9.3/main
IMAGE_REPOSITORY=test/postgresql
PSQL=/usr/lib/postgresql/9.3/bin/psql
TEST_SQL="CREATE TABLE foo(id serial primary key, name varchar not null); INSERT INTO foo(name) VALUES('$EXPECTED');"

{
set -x
docker build -rm -t $IMAGE_REPOSITORY .
mkdir -p $TEST_VOLUME -m 700
sudo chown 5432 $TEST_VOLUME
docker run -v `pwd`/$TEST_VOLUME:$MOUNT_PATH $IMAGE_REPOSITORY /usr/lib/postgresql/9.3/bin/initdb -D $MOUNT_PATH
docker run -v `pwd`/$TEST_VOLUME:$MOUNT_PATH $IMAGE_REPOSITORY /bin/sh -c "echo \"CREATE USER $DB_USER WITH PASSWORD '$DB_PASSWORD';\" | /usr/lib/postgresql/9.3/bin/postgres --single --config-file=/etc/postgresql/9.3/main/postgresql.conf"
docker run -v `pwd`/$TEST_VOLUME:$MOUNT_PATH $IMAGE_REPOSITORY /bin/sh -c "echo \"CREATE DATABASE $DB_NAME OWNER $DB_USER;\" | /usr/lib/postgresql/9.3/bin/postgres --single --config-file=/etc/postgresql/9.3/main/postgresql.conf"
ID=$(docker run -name $CONTAINER_NAME -d -v `pwd`/$TEST_VOLUME:$MOUNT_PATH $IMAGE_REPOSITORY)
sleep 1
docker run -e="PGPASSWORD=$DB_PASSWORD" -link $CONTAINER_NAME:db $IMAGE_REPOSITORY /bin/sh -c "$PSQL -h \$DB_PORT_5432_TCP_ADDR -U $DB_USER -d $DB_NAME -c \"$TEST_SQL\""
RESULT=$(docker run -e="PGPASSWORD=$DB_PASSWORD" -link $CONTAINER_NAME:db $IMAGE_REPOSITORY /bin/sh -c "$PSQL -h \$DB_PORT_5432_TCP_ADDR -U $DB_USER -d $DB_NAME -A -t -c 'SELECT name FROM foo;'")
[ "$EXPECTED" = "$RESULT" ] || echo "Expecting:\n$EXPECTED\nFound:\n$RESULT"
}

docker kill $CONTAINER_NAME > /dev/null 2>&1
docker rm $CONTAINER_NAME > /dev/null 2>&1
docker rmi $IMAGE_REPOSITORY > /dev/null 2>&1
sudo rm -rf $TEST_VOLUME > /dev/null 2>&1
