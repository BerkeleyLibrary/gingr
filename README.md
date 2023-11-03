# gingr

Command-line tool for ingesting GeoData (Solr, GeoServer, and file servers).

## Quick Start

The app is Dockerized with an image designed to just run the `gingr` executable:

```sh
# Build the image
docker compose build

# Use `docker compose watch` to automatically rebuild on changes. This takes over the terminal
# you run it in, so you'll need to either background it (`screen` works great) or open a different window.
docker compose watch

# Spin up dependencies (solr, geoserver, …). The app itself will also start,
# but since it's a CLI tool we override the CMD so that it just tails /dev/null.
# This means you can exec into it per usual.
docker compose up -d
docker compose exec app bash

# You can also run commands from your host, either via `run` or `exec`:
docker compose exec app gingr help
docker compose run --rm app gingr help
docker compose run --rm app gingr all /opt/app/spec/fixture/zipfile/test_public.zip
```
