#!/bin/sh
set -e

if [ -f tmp/pids/server.pid ]; then
  rm tmp/pids/server.pid
fi

bundle check || bundle install --binstubs="$BUNDLE_BIN"

bundle exec rake assets:precompile --trace

exec bundle exec "$@"
