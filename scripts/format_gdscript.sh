#!/bin/bash -xe

# Enable recursive directory globbing
shopt -s globstar

root=$(realpath "$(dirname $0)/../")

gdformat "$root"/{scenes,tests}/**/*.gd --line-length=80
