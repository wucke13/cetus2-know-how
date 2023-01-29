#!/usr/bin/env bash

# cd to the script source
cd $(dirname -- "$( readlink -f -- "$0")")

cp -r ~/.config/SuperSlicer/{filament,print,printer} superslicer-config/