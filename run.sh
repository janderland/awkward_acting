#!/usr/bin/env bash
set -euo pipefail

# Change directory to repo root.
cd "${0%/*}/."

LOG_FILE=""
PROG_FILE=""
INPUT_FILE=""
BUFFER_DIR=""

while [[ $# -gt 0 ]]; do
  if [[ $# -lt 2 ]]; then
    echo "even number of flags required"
    exit 1
  fi
  case "$1" in
    --log-file)   LOG_FILE="$2"   ;;
    --prog-file)  PROG_FILE="$2"  ;;
    --input-file) INPUT_FILE="$2" ;;
    --buffer-dir) BUFFER_DIR="$2" ;;
  esac
  shift 2
done

if [[ -z "$PROG_FILE" ]]; then
  echo "--prog-file flag is required"
  exit 1
fi

if [[ -z "$INPUT_FILE" ]]; then
  echo "--input-file flag is required"
  exit 1
fi

# Setups buffer paths and initialize the first buffer using the
# input file. If a buffer directory was not provided, a random
# temporary directory will be used.
BUFFER_DIR=${BUFFER_DIR:-$(mktemp -d)}
mkdir -p $BUFFER_DIR
BUFFERS=( "${BUFFER_DIR}/a.txt" "${BUFFER_DIR}/b.txt" )
awk '$0 = "input " $0' "$INPUT_FILE" > "${BUFFERS[1]}"

# Run the cycles until the output is empty, which means there
# are no more messages to process.
CYCLE=0
while [[ -s "${BUFFERS[1]}" ]]; do
  BUFFERS=( "${BUFFERS[1]}" "${BUFFERS[0]}" )

  CYCLE=$((CYCLE + 1))
  echo "CYCLE $CYCLE"

  gawk -f "$PROG_FILE" "${BUFFERS[0]}" > "${BUFFERS[1]}" || {
    exit $?
  }

  if [[ -n "$LOG_FILE" ]]; then
    cat "${BUFFERS[0]}" >> "$LOG_FILE"
  fi
done
