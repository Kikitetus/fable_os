#!/usr/bin/env bash
# The heartbeat (BUILD 3). Run via cron or `make tick`.
# Exit map: 0 quiet/done, 1 iteration cap, 2 reroute/refusal, 3 budget. All labeled, on purpose.
set -euo pipefail
cd "$(dirname "$0")"
LOOPDIR="$PWD"
NL=$'\n'

MAX_ITERS="${MAX_ITERS:-10}"
DAILY_BUDGET_USD="${DAILY_BUDGET_USD:-5}"
CHEAP="${CHEAP:-claude-haiku-4-5-20251001}"
WORKER="${WORKER:-claude-haiku-4-5-20251001}"
CONDUCTOR_MODEL="${CONDUCTOR_MODEL:-claude-fable-5}"
FALLBACK_MODEL="${FALLBACK_MODEL:-claude-opus-4-8}"

./scripts/cost-check.sh --budget "$DAILY_BUDGET_USD" || exit 3

for ((i=1; i<=MAX_ITERS; i++)); do
  # 1 TRIAGE: quiet-tick gate, cheap model. Gate on the FRESH output only,
  # never on STATE.md history (old findings must not re-trigger forever).
  SIGNALS=$({ git log --oneline -20; gh issue list --limit 20 2>/dev/null || true; gh run list --limit 10 2>/dev/null || true; })
  TRIAGE=$(claude -p "$(cat triage.md)${NL}${NL}INPUT:${NL}${SIGNALS}" --model "$CHEAP")
  printf '%s\n' "$TRIAGE" >> memory/STATE.md
  ./scripts/log-cost.sh triage 0.01
  printf '%s' "$TRIAGE" | grep -q "status: actionable" || { echo quiet; exit 0; }

  # 2 CONDUCT: Fable, xhigh, fresh context, read-only, JSON out
  claude -p "$(cat conductor.md)${NL}${NL}STATE:${NL}$(cat memory/STATE.md)${NL}${NL}TRUST:${NL}$(./scripts/trust-log.sh --render)${NL}${NL}CONTRACT:${NL}$(cat contract.md)" \
    --model "$CONDUCTOR_MODEL" --effort xhigh --allowedTools "Read" \
    --fallback-model "$FALLBACK_MODEL" --output-format json > /tmp/c.json
  ./scripts/log-cost.sh conductor 0.35

  # 2a REFUSAL: refusals are HTTP 200 successes; check the stop reason, not the exit code
  if grep -q '"refusal"' /tmp/c.json; then
    echo "- refusal: conductor declined; audit the prompt (runbook)" >> memory/STATE.md
    exit 2
  fi

  # 2b ROUTE-TOLERANCE: never iterate on output from a model you didn't choose
  SERVED=$(jq -r '.modelUsage | keys[0] // "claude-fable-5"' /tmp/c.json)
  [[ "$SERVED" != *fable* ]] && { echo "- rerouted: served by $SERVED" >> memory/STATE.md; exit 2; }
  jq -r '.result' /tmp/c.json | sed 's/^```json$//; s/^```$//' > work-order.json
  SKILL=$(jq -r .skill work-order.json); ACTION=$(jq -r .action work-order.json)
  [[ "$ACTION" == stop  ]] && exit 0
  [[ "$ACTION" == queue ]] && { echo "- queued: $SKILL" >> memory/STATE.md; continue; }

  # 3 EXECUTE: cheap worker, isolated worktree, edit-only permissions
  WT="../wt-$i"
  git worktree add "$WT" -b "loop/$SKILL-$i" >/dev/null
  (
    cd "$WT"
    OUT=$(claude -p "$(cat "$LOOPDIR/workers/implement.md")${NL}${NL}WORK ORDER:${NL}$(cat "$LOOPDIR/work-order.json")" \
      --model "$WORKER" --permission-mode acceptEdits \
      --allowedTools "Read" "Edit" "Write" "Glob" "Grep")
    [ -f IMPLEMENTATION.md ] || printf '%s\n' "$OUT" > IMPLEMENTATION.md
    git add -A
  )
  ./scripts/log-cost.sh worker 0.10

  # 4 VERIFY: fresh Fable, no tools, sees only spec + diff (staged, so new files count)
  V=$(claude -p "$(cat workers/verify.md)${NL}${NL}SPEC:${NL}$(jq -r .spec work-order.json)${NL}${NL}DIFF:${NL}$(cd "$WT" && git diff --cached)" \
    --model "$CONDUCTOR_MODEL" --effort high \
    --fallback-model "$FALLBACK_MODEL" --output-format json | jq -r .result)
  ./scripts/log-cost.sh verifier 0.40

  # 5 GATE: deterministic script has the final vote; then ledger; ship only at auto tier
  if [[ "$V" == PASS* ]] && ( cd "$WT" && "$LOOPDIR/guardrails/verify.sh" ); then
    ./scripts/trust-log.sh "$SKILL" pass
    if [[ "$(./scripts/trust-log.sh --tier "$SKILL")" == auto ]]; then
      ( cd "$WT" && git commit -qm "loop: $SKILL" && gh pr create --fill || true )
      echo "- shipped: $SKILL" >> memory/STATE.md
    else
      echo "- review: $SKILL in $WT" >> memory/STATE.md
    fi
  else
    ./scripts/trust-log.sh "$SKILL" fail
    echo "- FAILED: $SKILL in $WT ($V)" >> memory/STATE.md
  fi
  ./scripts/cost-check.sh --budget "$DAILY_BUDGET_USD" || exit 3
done
exit 1   # iteration cap without stop: check STATE.md
