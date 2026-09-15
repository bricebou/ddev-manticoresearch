# DDEV Manticore Search

## What is Manticore Search?

> [Manticore Search](https://manticoresearch.com/) is an open-source database that was created in 2017 as a continuation of the Sphinx Search engine.

## Installation

Requires DDEV v1.23.5 or above:

```sh
ddev add-on get bricebou/ddev-manticoresearch && ddev restart
```

This add-on for DDEV installs the following files:
- `.ddev/docker-compose.manticoresearch.yaml`, which is responsible for launching the service;
- a `.ddev/manticoresearch/manticore.conf`.

## Choosing the Manticore Search version

The add-on ships with a pinned version — `manticoresearch/manticore:29.9.0` — rather than
`latest`, so that a given add-on release always gives every member of your team the same
engine. To run another version, typically the one your production server uses:

```sh
ddev dotenv set .ddev/.env.manticoresearch --manticoresearch-docker-image=manticoresearch/manticore:25.0.0
ddev restart
```

Commit `.ddev/.env.manticoresearch` to version control so your whole team runs the
same version. Available tags are listed on
[Docker Hub](https://hub.docker.com/r/manticoresearch/manticore/tags).

The variable holds a full image reference, not just a tag, so it can also point to a
derived or private image, including `manticoresearch/manticore:latest` if you would
rather track the newest release.

If you installed this add-on before versions were pinned, updating it writes
`manticoresearch/manticore:latest` into `.ddev/.env.manticoresearch` for you, so your
existing data volume is never silently downgraded. Delete that file to fall back to the
version pinned by the add-on.

### Switching from one version to another

Manticore stores its data in the `ddev-<project>-manticoresearch` Docker volume. An index
written by a newer version cannot always be read by an older one, so **downgrading** (and
sometimes jumping several major versions up) requires starting from an empty volume:

```sh
ddev stop
docker volume rm ddev-<your-project-name>-manticoresearch
ddev restart
```

Then re-index your data.

## Using PHP for your configuration file

If you want to use PHP language inside your configuration file, you'll have to follow these steps:
- edit the `.ddev/docker-compose.manticoresearch.yaml` file, replacing the line
```
    image: ${MANTICORESEARCH_DOCKER_IMAGE:-manticoresearch/manticore:29.9.0}
```
with
```
    build:
      args:
        BASE_IMAGE: ${MANTICORESEARCH_DOCKER_IMAGE:-manticoresearch/manticore:29.9.0}
      context: .
      dockerfile: ./manticoresearch/Dockerfile
```
- then, you have to create the `.ddev/manticoresearch/Dockerfile` :
```
ARG BASE_IMAGE
FROM $BASE_IMAGE
ARG DEBIAN_FRONTEND=noninteractive
RUN apt update && apt -y install php
```
- edit the `.ddev/manticoresearch/manticore.conf` according to your need, replacing the actual shebang with `#!/usr/bin/env php` 
- run `ddev restart`


_Maintained by [bricebou](https://github.com/bricebou/)._
