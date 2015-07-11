FROM ubuntu-debootstrap:15.04

RUN apt-get update && apt-get install -y curl iptables

WORKDIR /

ADD . /

CMD /run.sh
