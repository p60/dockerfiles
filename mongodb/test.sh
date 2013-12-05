#!/usr/bin/env sh

EXPECTED=$(openssl rand -hex 16)
JS_COMMAND="db.foo.insert({bar: \"$EXPECTED\"}); db.foo.findOne({bar: \"$EXPECTED\"}).bar"
DB_NAME=$(openssl rand -hex 16)

{
#docker build -t peer60/mongodb .
mkdir -p store -m 750
sudo chown 27017 store
ID=$(docker run -name $DB_NAME -d -v `pwd`/store:/var/lib/mongodb peer60/mongodb )
sleep 1
RESULT=$(docker run -link $DB_NAME:db peer60/mongodb /bin/sh -c "/usr/bin/mongo \$DB_PORT_27017_TCP_ADDR --quiet --eval '$JS_COMMAND'")
[ "$EXPECTED" = "$RESULT" ] || echo "Expecting:\n$EXPECTED\nFound:\n$RESULT"
}

docker kill $DB_NAME > /dev/null 2>&1
docker rm $DB_NAME > /dev/null 2>&1
