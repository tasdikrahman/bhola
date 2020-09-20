FROM ruby:2.5.3-alpine

ENV BUNDLE_PATH=/bundle \
    BUNDLE_BIN=/bundle/bin \
    GEM_HOME=/bundle \
    BUNDLER_VERSION=2.1.4
ENV PATH="${BUNDLE_BIN}:${PATH}"

RUN apk update \
    && apk upgrade \
    && apk add --update --no-cache \
    build-base curl-dev git postgresql-dev \
    yaml-dev zlib-dev nodejs yarn npm

ADD . /usr/src/app
WORKDIR /usr/src/app
COPY ./docker-entrypoint.sh /
RUN chmod +x /docker-entrypoint.sh

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["rails", "s", "-p", "8080", "-b", "0.0.0.0"]
