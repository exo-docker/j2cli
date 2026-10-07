# syntax=docker/dockerfile:1
FROM python:3.14-alpine

# jinjanator is the maintained fork of j2cli (https://github.com/kpfleming/jinjanator)
ARG JINJANATOR_VERSION=25.3.1

LABEL org.opencontainers.image.title="j2cli" \
      org.opencontainers.image.description="Jinja2 command line renderer (jinjanator)" \
      org.opencontainers.image.source="https://github.com/exo-docker/j2cli" \
      org.opencontainers.image.licenses="AGPL-3.0-only" \
      org.opencontainers.image.vendor="eXo Platform"

RUN pip install --no-cache-dir "jinjanator==${JINJANATOR_VERSION}"

WORKDIR /root

# --quiet: no version banner on stderr
# the environment variables are the template context, e.g.:
#   docker run --rm --env-file my.env -v "$PWD":"$PWD":ro exoplatform/j2cli --undefined "$PWD/template.j2"
ENTRYPOINT ["jinjanate", "--quiet"]
