#!/usr/bin/env bash
set -e
# Deterministic gate: THIS SCRIPT HAS THE FINAL VOTE. Edit for your stack.
# Exit 0 = ship-able. If it fails on a clean checkout, fix that first.
if [ -f package.json ]; then
  npm run typecheck --if-present
  npm run test --if-present
  npm run lint --if-present
fi
