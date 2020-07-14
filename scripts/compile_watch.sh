#!/bin/bash

if ! command -v fswatch &> /dev/null
then
    echo "fswatch could not be found make sure you install it https://github.com/emcrisostomo/fswatch"
    exit
fi

# fs watch only watch .ex files
fswatch . | xargs -n1 -I{} mix compile; echo '--------------'
