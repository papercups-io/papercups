#!/bin/bash

set -ex
echo "Make sure you have wireguard set or migrations will fail"

ENV=prod DATABASE_URL=postgres://papercups_5pzo28kv5e63e01n:1a581361b1733319230c9f34c3b201c0@papercups-db.local:5432/papercups?sslmode=disable mix ecto.migrate
fly deploy
