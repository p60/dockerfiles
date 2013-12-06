#!/usr/bin/env sh

EXPECTED=$(openssl rand -hex 16)
JS_COMMAND="db.foo.insert({bar: \"$EXPECTED\"}); db.foo.findOne({bar: \"$EXPECTED\"}).bar"
CONTAINER_NAME=$(openssl rand -hex 16)
DB_NAME=$(openssl rand -hex 16)
DB_USER=$(openssl rand -hex 16)
DB_PASSWORD=$(openssl rand -hex 16)
TEST_VOLUME=test/store

{
set -x
docker build -rm -t test/mongodb .
mkdir -p $TEST_VOLUME -m 750
sudo chown 27017 $TEST_VOLUME
ID=$(docker run -name $CONTAINER_NAME -d -v `pwd`/$TEST_VOLUME:/var/lib/mongodb test/mongodb)
sleep 1
sudo lxc-attach --name $ID -- /usr/bin/mongo $DB_NAME --eval "db.addUser('$DB_USER','$DB_PASSWORD')"
RESULT=$(docker run -link $CONTAINER_NAME:db test/mongodb /bin/sh -c "/usr/bin/mongo -u $DB_USER -p $DB_PASSWORD \$DB_PORT_27017_TCP_ADDR/$DB_NAME --quiet --eval '$JS_COMMAND'")
[ "$EXPECTED" = "$RESULT" ] || echo "Expecting:\n$EXPECTED\nFound:\n$RESULT"
}

docker kill $CONTAINER_NAME > /dev/null 2>&1
docker rm $CONTAINER_NAME > /dev/null 2>&1
docker rmi test/mongodb
sudo rm -rf $TEST_VOLUME
