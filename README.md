# gingr

Command-line tool for ingesting GeoData (Solr, GeoServer, and file servers).

## Quick start

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
docker compose run --rm app gingr all spec/fixture/zipfile/vector.zip
```

## Watching a directory for new files

Gingr's `watch` command monitors a directory for new `.zip` files and automatically ingest them. It accepts the path to a gingr root directory (which should contain `ready`, `processed`, and `failed` subdirectories) and the same arguments as `gingr all`:

```
gingr watch /path/to/directory [args to gingr all]
```

Gingr will error if the directory doesn't exist or if it doesn't contain the expected subdirectories:

```
./ready
./processed
./failed
```
