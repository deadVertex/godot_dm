#!/bin/bash -xe

root=$(realpath "$(dirname $0)/../")

godot_headless="$root/tools/Godot_v3.4.4-stable_linux_server.64"
$godot_headless -s addons/gut/gut_cmdln.gd -gdir="res://tests/" -gexit
