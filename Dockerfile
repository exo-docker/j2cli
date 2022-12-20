
FROM alpine:3.17

RUN apk --no-cache add \
      python3 \
      py3-pip && \
    pip3 install j2cli[yaml]

WORKDIR /root

ENTRYPOINT ["j2"]