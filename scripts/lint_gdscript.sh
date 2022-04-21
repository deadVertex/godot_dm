#!/bin/bash -xe

# Enable recursive globbing
shopt -s globstar

root=$(realpath "$(dirname $0)/../")

exit_code=0
for file in "$root"/{scenes,tests}/**/*.gd; do
    if ! gdlint "$file"; then
        exit_code=1
    fi
done

exit $exit_code
