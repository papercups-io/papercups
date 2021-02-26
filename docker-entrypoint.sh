#!/bin/sh
set -e

if [[ "$1" = 'run' ]]; then
    exec /app/bin/papercups start

elif [[ "$1" = 'db' ]]; then
    exec /app/"$2".sh
else
    exec "$@"

fi

exec "$@"
