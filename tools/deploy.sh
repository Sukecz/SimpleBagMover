#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
bash tests/run.sh
mkdir -p build
stage=$(mktemp -d)
trap 'rm -rf "$stage"' EXIT
mkdir "$stage/SimpleBagMover"
cp Core.lua SimpleBagMover_Camelot.toc "$stage/SimpleBagMover/"
mkdir "$stage/SimpleBagMover/assets"
cp assets/addon-icon.tga "$stage/SimpleBagMover/assets/"
tar -czf build/SimpleBagMover.tar.gz -C "$stage" SimpleBagMover
host="${WOW_DEPLOY_HOST:-192.168.1.199}"
user="${WOW_DEPLOY_USER:-Marti}"
key=/home/msminipc/.ssh/id_ed25519_wowpc_deploy
options=(-i "$key" -o BatchMode=yes -o ConnectTimeout=8 -o StrictHostKeyChecking=yes)
remote=C:/Users/$user/Desktop/wow_simplebagmover_deploy
ssh "${options[@]}" "$user@$host" powershell.exe -NoProfile -Command "New-Item -ItemType Directory -Force '$remote' ^| Out-Null"
scp "${options[@]}" build/SimpleBagMover.tar.gz tools/windows/Deploy-SimpleBagMover.ps1 "$user@$host:$remote/"
ssh "${options[@]}" "$user@$host" powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$remote/Deploy-SimpleBagMover.ps1"
