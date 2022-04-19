#!/bin/sh
set -e

POOL_SIZE=2 mix ecto.setup
mix deps.compile certifi
echo "Run: mix phx.swagger.generate to generate swagger docs"
NODE=$(mix phx.gen.secret) mix phx.server