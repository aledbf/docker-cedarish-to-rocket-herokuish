# use some version of deis/slugbuilder
FROM #replace with deis/slugbuilder#

USER root

ENTRYPOINT /bin/bash

RUN curl -sSL https://github.com/gliderlabs/herokuish/releases/download/v0.1.0/herokuish_0.1.0_linux_x86_64.tgz | tar -xzC /usr/local/bin && chmod 755 /usr/local/bin/herokuish

RUN herokuish buildpack install

RUN git clone https://github.com/aledbf/example-nodejs-express /app

RUN herokuish buildpack build

RUN herokuish slug generate

RUN ls /tmp
