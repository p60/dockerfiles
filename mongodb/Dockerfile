FROM ubuntu:quantal
MAINTAINER Vyrak Bunleang <vbunleang@peer60.com>

RUN apt-get update && apt-get -y --force-yes install wget
RUN wget --quiet -O - http://docs.mongodb.org/10gen-gpg-key.asc | apt-key add -

ADD sources.list /etc/apt/sources.list.d/peer60-mongodb.list

# Disable upstart on mongo install
RUN echo "#!/bin/sh\nexit 101" > /usr/sbin/policy-rc.d; chmod +x /usr/sbin/policy-rc.d

RUN adduser --system --disabled-login --home /var/lib/mongodb --no-create-home \
            --group --gecos "MongoDB" --shell /bin/false \
            --uid 27017 mongodb

RUN apt-get update \
      && DEBIAN_FRONTEND=noninteractive apt-get -y --force-yes install mongodb-10gen=2.4.8 \
      && rm -rf /var/lib/apt/lists/* \
      && apt-get clean

ADD mongodb.conf /etc/mongodb.conf

# Enable upstart on install
RUN rm /usr/sbin/policy-rc.d

USER mongodb

EXPOSE 27017
CMD ["/usr/bin/mongod", "-f", "/etc/mongodb.conf"]
