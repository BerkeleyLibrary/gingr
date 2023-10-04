
FROM ruby:3.2.2
ENV SOLR_URL http://solr:8983/solr/geodata-test
ENV GEOSERVER_SECURE_URL http://admin:geoserver@localhost:8080/geoserver/rest/
ENV GEOSERVER_URL http://admin:geoserver@localhost:8080/geoserver/rest/
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
