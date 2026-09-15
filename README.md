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

## Using PHP to build your configuration file

Manticore Search executes its configuration file whenever that file starts with a shebang,
and reads whatever it writes on standard output as the real configuration — that is exactly
how the `manticore.conf` shipped by this add-on works, with its `#!/bin/sh` and its heredoc.
The same mechanism lets you build the configuration with PHP, which is convenient for long
charset tables, shared definitions, or values computed at startup.

The layout below is known to work. It keeps four files in `.ddev/manticoresearch/`, and none
of them needs the executable bit.

### 1. Add PHP to the image

`.ddev/manticoresearch/Dockerfile`:

```dockerfile
ARG BASE_IMAGE
FROM $BASE_IMAGE
ARG DEBIAN_FRONTEND=noninteractive
RUN apt update && apt -y install php
```

### 2. Build that image instead of pulling the stock one

In `.ddev/docker-compose.manticoresearch.yaml`, replace

```yaml
    image: ${MANTICORESEARCH_DOCKER_IMAGE:-manticoresearch/manticore:29.9.0}
```

with

```yaml
    image: ddev-${DDEV_SITENAME}-manticoresearch-php
    build:
      args:
        BASE_IMAGE: ${MANTICORESEARCH_DOCKER_IMAGE:-manticoresearch/manticore:29.9.0}
      context: .
      dockerfile: ./manticoresearch/Dockerfile
```

and add the two files of the next steps to the existing `volumes:` list:

```yaml
      - ./manticoresearch/manticore.php:/etc/manticoresearch/manticore.php
      - ./manticoresearch/myproject.conf:/etc/manticoresearch/myproject.conf
```

Keeping `${MANTICORESEARCH_DOCKER_IMAGE}` as the `BASE_IMAGE` is what makes version pinning
keep working in this mode.

### 3. Turn `manticore.conf` into a launcher

Rather than putting a PHP shebang in `manticore.conf` itself, keep it as a two-line shell
script that hands over to PHP. The file Manticore reads stays a plain shell script, and your
real configuration lives under its own name.

`.ddev/manticoresearch/manticore.conf`:

```sh
#!/bin/bash
DIR=$(dirname "$0")
/usr/bin/env php $DIR/manticore.php
```

`$DIR` resolves to `/etc/manticoresearch`, where the files below are mounted next to it.

> **Remove the `#ddev-generated` line from `manticore.conf` while you are at it.** DDEV
> replaces files that still carry that marker on the next `ddev add-on get`, even if you have
> modified them, and leaves the others alone. The same applies to
> `docker-compose.manticoresearch.yaml` — either drop its marker too, or leave it untouched
> and put the `image` / `build` / `volumes` overrides of step 2 in a separate
> `.ddev/docker-compose.manticoresearch_extra.yaml`. DDEV merges every `docker-compose.*.yaml`
> of the project, and `.ddev/.env.manticoresearch` is applied to all of them.

### 4. Write the configuration in PHP

`.ddev/manticoresearch/manticore.php` is a thin loader:

```php
#!/usr/bin/env php
<?php

include __DIR__ . '/myproject.conf';
```

`.ddev/manticoresearch/myproject.conf` holds the real thing, as a PHP template mixing plain
configuration text and PHP blocks:

```php
<?php
$charset_table = implode(', ', [
    '0..9, A..Z->a..z, a..z',
    'U+00C0->a, U+00C1->a, U+00C2->a',
    // …
]);
?>

table myindex {
    type = rt
    path = /var/lib/manticore/myindex

    rt_field       = title
    rt_attr_string = title

    morphology = stem_en, libstemmer_fr
    charset_table = <?= $charset_table ?>
}

searchd {
    listen = 9306:mysql
    listen = /var/run/mysqld/mysqld.sock:mysql
    listen = 9308:http
    <?php $ip = trim(`hostname -i|rev|cut -d\  -f 1|rev`); ?>
    listen = <?= $ip ?>:9312
    listen = <?= $ip ?>:9315-9325:replication

    pid_file = /var/run/manticore/searchd.pid
    log      = /var/log/manticore/searchd.log
}
```

Splitting the loader from the configuration keeps `include`-able fragments possible: shared
charset tables or index definitions can live in their own files and be pulled in from here.

### 5. Build and start

```sh
ddev debug rebuild -s manticoresearch
ddev restart
```

`ddev debug rebuild -s manticoresearch` is also what you need after changing the pinned
version, since the image is built rather than pulled.

_Maintained by [bricebou](https://github.com/bricebou/)._
