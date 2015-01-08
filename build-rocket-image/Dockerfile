FROM google/golang

USER root

ENTRYPOINT /bin/bash

WORKDIR /tmp

RUN apt-get update && apt-get install -y curl

RUN cd $GOPATH && \
  mkdir -p github.com/appc/ && \
  git clone https://github.com/appc/spec github.com/appc/spec && \
  mkdir -p github.com/coreos/ && \
  git clone https://github.com/coreos/rocket github.com/coreos/rocket && \
  cd $GOPATH/github.com/appc/spec && \
  ./build && \
  cp bin/* /usr/local/bin

ADD . /tmp

RUN actool validate demo

RUN actool build demo rocket-herokuish-nodejs.aci

RUN actool validate rocket-herokuish-nodejs.aci

