FROM alpine:latest
RUN apk add --no-cache iproute2

ENV KUBE_DNS_SERVER 10.96.0.10

CMD "/install.sh"

COPY install.sh /
