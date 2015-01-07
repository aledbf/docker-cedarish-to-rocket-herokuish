FROM ubuntu:trusty

USER root

ENTRYPOINT /bin/bash

WORKDIR /tmp

RUN apt-get update && apt-get install -y curl

RUN curl -sSL https://github.com/coreos/rocket/releases/download/v0.1.1/rocket-v0.1.1.tar.gz | tar -xzC /usr/local/bin

RUN curl -sSL https://github.com/appc/spec/releases/download/v0.1.1/appc-spec-v0.1.1.tar.gz | tar -xzC /usr/local/bin && ln -s /usr/local/bin/appc-spec-v0.1.1/actool /usr/local/bin

ADD . /tmp/build

RUN actool validate demo

RUN actool build demo.aci

RUN actool validate demo

