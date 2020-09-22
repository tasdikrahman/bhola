FROM ruby:2.5.3-alpine

ENV BUNDLE_PATH=/bundle \
    BUNDLE_BIN=/bundle/bin \
    GEM_HOME=/bundle
ENV PATH="${BUNDLE_BIN}:${PATH}"

ADD . /usr/src/app
WORKDIR /usr/src/app
COPY ./docker-entrypoint.sh /
RUN chmod +x /docker-entrypoint.sh

RUN apk update \
    && apk upgrade \
    && apk add --update --no-cache \
    build-base curl-dev git postgresql-dev tzdata \
    yaml-dev zlib-dev nodejs yarn npm \
    && gem uninstall bundler \
    && gem install bundler -v 2.1.4 \
    && yarn install --check-files \
    && bundle check || bundle install -j3 \
    && bundle exec rake assets:precompile --trace \
    && cp config/application.sample.yaml config/application.yaml

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["rails", "s", "-p", "8080", "-b", "0.0.0.0"]
