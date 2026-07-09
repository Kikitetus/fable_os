#!/usr/bin/env bash
# OPTIONAL (BUILD 7). Install condition: dispatch shows Fable wake-ups that produced action: stop.
# Three independent cheap votes; the conductor wakes only on 2 of 3.
# Voters never see each other's answers. Adapted: guide used 3 OpenRouter models via `llm`;
# here 3 independent samples of $CHEAP (set VOTER2/VOTER3 to diversify models later).
set -euo pipefail
cd "$(dirname "$0")"
CHEAP="${CHEAP:-claude-sonnet-5}"
VOTER2="${VOTER2:-$CHEAP}"
VOTER3="${VOTER3:-$CHEAP}"
NL=$'\n'
SIGNALS=$({ git log --oneline -20; gh issue list --limit 20 2>/dev/null || true; gh run list --limit 10 2>/dev/null || true; })
V=0
for m in "$CHEAP" "$VOTER2" "$VOTER3"; do
  claude -p "$(cat triage.md)${NL}${NL}INPUT:${NL}${SIGNALS}" --model "$m" \
    | grep -q "status: actionable" && V=$((V+1))
done
[ "$V" -ge 2 ] && exec ./loop.sh || echo "quorum: quiet ($V/3)"
