FROM alpine:3.22
RUN apk --no-cache add dnsmasq && mkdir -p /tftp
ENTRYPOINT ["dnsmasq","-k"]
