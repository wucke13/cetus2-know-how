#!/usr/bin/env bash

set -ex

SCRIPT_ROOT=$(dirname "$0")
INPUT_FILE="$1"

MAGIC_STRING="; file already post-processed using $(basename "$0")"

grep --fixed-strings --line-regexp --quiet -- "$MAGIC_STRING" "$INPUT_FILE" && {
  echo "file was already processed"
  exit 1
}

WORK_FILE=$(mktemp)
awk -f "$SCRIPT_ROOT/fix-gcode.awk" -- "$INPUT_FILE" > "$WORK_FILE"

echo "$MAGIC_STRING" >> "$WORK_FILE"
mv -- "$WORK_FILE" "$INPUT_FILE"
