FROM alpine:latest
RUN apk add --no-cache pdnsd
ENTRYPOINT ["pdnsd"]
COPY pdnsd.conf /etc/
