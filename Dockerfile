
FROM ruby:3.2.2
RUN mkdir -p /opt/app 
RUN apt-get update -qq 

RUN apt-get install -y --no-install-recommends \
    bash \
    curl \
    libpq-dev \
    libvips42 

WORKDIR /opt/app
ENV PATH "/opt/app/bin:$PATH"
CMD ["tail", "-f", "/dev/null"]
COPY  .ruby-version Gemfile* ./
COPY  . .
RUN bundle install
