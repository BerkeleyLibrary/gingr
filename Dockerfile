FROM ruby:3.2.2

RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends \
        bash \
        curl \
        libpq-dev \
        libvips42

WORKDIR /opt/app
COPY  .ruby-version Gemfile* ./
RUN bundle install
COPY  . .

ENV PATH="/opt/app/bin:$PATH"
CMD ["gingr", "help"]
