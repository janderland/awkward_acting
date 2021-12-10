#!/usr/bin/env bash
set -euo pipefail

# Change directory to repo root.

cd "${0%/*}"


# This required arg specifies a file for initializing
# the initial messages. Each line of text from this
# file is sent as an "input" message.

INPUT_FILE=""


# If this arg is provided, all messages will
# be copied into this file.

LOG_FILE=""


# Internal state specifying where the message
# buffers are stored.

BUFFER_DIR="$(mktemp -d)"


# Internal state specifying the current cycle.

CYCLE=0


# Returns the path to the current set of input messages.

function current_messages {
  echo "${BUFFER_DIR}/$((CYCLE % 2)).txt"
}


# Returns the path to the input messages for the next cycle.

function next_messages {
  echo "${BUFFER_DIR}/$(((CYCLE + 1) % 2)).txt"
}


# Parse command-line arguments.

while [[ $# -gt 0 ]]; do
  if [[ $# -lt 2 ]]; then
    echo "even number of flags required"
    exit 1
  fi
  case "$1" in
    --input-file) INPUT_FILE="$2" ;;
    --log-file)   LOG_FILE="$2"   ;;
  esac
  shift 2
done

if [[ -z "$INPUT_FILE" ]]; then
  echo "--input-file flag is required"
  exit 1
fi


# Create the buffer dir and initialize the first buffer using the
# input file. 

awk '$0 = "input " $0' "$INPUT_FILE" > "$(next_messages)"


# Run the cycles until the next set of messages is empty, which
# means there are no more messages to process.

while [[ -s "$(next_messages)" ]]; do
  CYCLE=$((CYCLE + 1))

  gawk -f prog.awk "$(current_messages)" > "$(next_messages)" || {
    exit $?
  }

  if [[ -n "$LOG_FILE" ]]; then
    cat "$(current_messages)" >> "$LOG_FILE"
  fi
done
