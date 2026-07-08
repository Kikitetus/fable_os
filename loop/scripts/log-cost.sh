#!/usr/bin/env bash
# usage: log-cost.sh <stage> <usd>
printf '%s\t%s\t%s\n' "$(date +%Y-%m-%dT%H:%M:%S%z)" "$1" "$2" \
  >> "$(dirname "$0")/../memory/usage.log"
