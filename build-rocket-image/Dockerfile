FROM google/golang

ENTRYPOINT /bin/bash

WORKDIR /tmp

RUN apt-get update && apt-get install -y cpio squashfs-tools realpath

RUN mkdir -p /dist

RUN go get github.com/jteeuwen/go-bindata/... && go get github.com/appc/spec/...

RUN git clone https://github.com/coreos/rocket.git rocket && \
  cd rocket && \
  ./build && \
  cp bin/* /dist

RUN cd $GOPATH && \
  mkdir -p github.com/appc/ && \
  git clone https://github.com/appc/spec github.com/appc/spec && \
  cd $GOPATH/github.com/appc/spec && \
  ./build && \
  cp bin/* /dist

RUN cd /dist && tar -cvzf /tools.tgz *

