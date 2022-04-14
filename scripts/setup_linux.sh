#!/bin/bash -xe

root=$(realpath "$(dirname $0)/../")

# Godot 3.4.4-stable from GitHub
godot_x11_zip_url="https://github.com/godotengine/godot/releases/download/3.4.4-stable/Godot_v3.4.4-stable_x11.64.zip"
godot_x11_zip_file="$root/tools/Godot_v3.4.4-stable_x11.64.zip"
godot_x11_binary="$root/tools/Godot_v3.4.4-stable_x11.64"

godot_server_zip_url="https://github.com/godotengine/godot/releases/download/3.4.4-stable/Godot_v3.4.4-stable_linux_server.64.zip"
godot_server_zip_file="$root/tools/Godot_v3.4.4-stable_linux_server.64.zip"
godot_server_binary="$root/tools/Godot_v3.4.4-stable_linux_server.64"

# Create tools directory if it does not already exist
mkdir -p "$root/tools"

# Download 
echo "============== DOWNLOAD ================="
if [ ! -f "$godot_x11_zip_file" ]; then
    wget "$godot_x11_zip_url" -O "$godot_x11_zip_file"
fi

if [ ! -f "$godot_server_zip_file" ]; then
    wget "$godot_server_zip_url" -O "$godot_server_zip_file"
fi

# Extract
echo "============== EXTRACT ================="
unzip "$godot_x11_zip_file" -d "$root/tools"
unzip "$godot_server_zip_file" -d "$root/tools"

# Test
echo "============== TEST ================="
"$godot_x11_binary" --version
"$godot_server_binary" --version
