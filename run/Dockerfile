FROM ubuntu:trusty

WORKDIR /tmp

ADD tools.tgz /usr/local/bin

#RUN rkt --debug run http://192.168.59.104:8080/aledbf/rocket-herokuish-nodejs.aci

RUN echo "url http://192.168.59.104:8080/aledbf/rocket-herokuish-nodejs.aci"

ENTRYPOINT /bin/bash

