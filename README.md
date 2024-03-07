# DDEV Manticore Search

## What is Manticore Search?

> [Manticore Search](https://manticoresearch.com/) is an open-source database that was created in 2017 as a continuation of the Sphinx Search engine.

## Installation

Like any other DDEV add-on, you juste have to run :

```
ddev get bricebou/ddev-manticoresearch && ddev restart
```

This add-on for DDEV installs the following files :
- `.ddev/docker-compose.manticoresearch.yaml` wich is responsible for launching the service;
- a `.ddev/manticoresearch/manticore.conf`

## Using PHP for your configuration file

If you want to use PHP language inside your configuration file, you'll have to follow these steps:
- edit the `.ddev/docker-compose.manticoresearch.yaml` file, replacing the line
```
    image: manticoresearch/manticore
```
with
```
    build:
      args:
        BASE_IMAGE: manticoresearch/manticore
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