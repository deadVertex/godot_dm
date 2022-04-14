#!/bin/bash -xe

# Enable recursive directory globbing
shopt -s globstar

root=$(realpath "$(dirname $0)/../")

exit_code=0
for file in "$root"/**/*.gd; do
    if ! gdformat "$file" --check --diff --line-length=80 ; then
        exit_code=1
    fi
done

exit $exit_code
