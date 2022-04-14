#!/bin/bash -xe

root=$(realpath "$(dirname $0)/../")

# Godot 3.4.4-stable from GitHub
godot_zip_url="https://github.com/godotengine/godot/releases/download/3.4.4-stable/Godot_v3.4.4-stable_x11.64.zip"
godot_zip_file="$root/tools/Godot_v3.4.4-stable_x11.64.zip"
godot_binary="$root/tools/Godot_v3.4.4-stable_x11.64"

# Create tools directory if it does not already exist
mkdir -p "$root/tools"

# Download 
if [ ! -f "$godot_zip_file" ]; then
    wget "$godot_zip_url" -O "$godot_zip_file"
fi

# Extract
unzip "$godot_zip_file" -d "$root/tools"

# Test
"$godot_binary" --version
