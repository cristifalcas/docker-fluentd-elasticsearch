FROM ruby:2.5.3-slim-stretch

ARG DEBIAN_FRONTEND=noninteractive

COPY clean-apt /usr/bin
COPY clean-install /usr/bin
COPY Gemfile /Gemfile

# 1. Install & configure dependencies.
# 2. Install fluentd via ruby.
# 3. Remove build dependencies.
# 4. Cleanup leftover caches & files.
RUN BUILD_DEPS="make gcc g++ libc6-dev libffi-dev" \
    && clean-install $BUILD_DEPS \
                     ca-certificates \
                     libjemalloc1 \
                     libffi6 \
    && echo 'gem: --no-document' >> /etc/gemrc \
    && gem install --file Gemfile \
    && apt-get purge -y --auto-remove \
                     -o APT::AutoRemove::RecommendsImportant=false \
                     $BUILD_DEPS \
    && clean-apt \
    # Ensure fluent has enough file descriptors
    && ulimit -n 65536

RUN mkdir -p /etc/fluent/plugin
ADD filter_parse_json_field/lib/*.rb /etc/fluent/plugin/
# Copy the Fluentd configuration file for logging Docker container logs.
COPY fluent.conf /etc/fluent/fluent.conf
COPY run.sh /run.sh

# Expose prometheus metrics.
EXPOSE 80

ENV LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libjemalloc.so.1

# Start Fluentd to pick up our config that watches Docker container logs.
CMD ["/run.sh"]
