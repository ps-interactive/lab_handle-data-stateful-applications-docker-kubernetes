ARG ALPINE_VERSION="3.15"    
FROM alpine:$ALPINE_VERSION

RUN apk add --no-cache jq openssl
RUN apk add --no-cache --repository http://dl-cdn.alpinelinux.org/alpine/edge/testing kubectl

COPY start.sh /
RUN chmod +x /start.sh

ENV USER_NAME="user@domain.tld" \
    GROUP="group" \
    SET_CONTEXT="" \
    PRINT_CERTS=""

WORKDIR /certs
CMD /start.sh

COPY csr.yaml .
