#!/usr/bin/env bash

set -euo pipefail

function print_iterations() {
  echo ""
  echo "$1 runs"
}

trap 'print_iterations $count' EXIT

count=1
while "$@"; do
  echo ""
  echo "Finished Run #$count"
  echo ""
  ((count++))
done
