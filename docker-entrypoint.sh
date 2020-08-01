#!/bin/bash
set -euo pipefail

POOL_SIZE=2 mix ecto.setup
mix phx.server