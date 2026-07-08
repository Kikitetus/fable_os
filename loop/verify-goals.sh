#!/usr/bin/env bash
# Standing-goal sentinel (BUILD 5). Detection only; fixes go through the normal pipeline.
# Exit 0 = all goals hold. Exit 1 = at least one VIOLATED (paths printed).
set -uo pipefail
cd "$(dirname "$0")"
LEDGER="memory/goal-ledger.tsv"; VIOLATIONS=0
ts() { date +%Y-%m-%dT%H:%M:%S%z; }
run_with_timeout() {  # 60s cap; macOS ships no `timeout`, so fall back to perl alarm
  if command -v timeout >/dev/null 2>&1; then timeout 60 bash -c "$1"
  else perl -e 'alarm 60; exec @ARGV' bash -c "$1"; fi
}
for g in goals/*.md; do
  [ -e "$g" ] || continue
  [ "$(basename "$g")" = "README.md" ] && continue   # docs/templates are not goals
  grep -q '^status: retired' "$g" && continue
  pred=$(grep -m1 '^predicate:' "$g" | cut -d' ' -f2-); name=$(basename "$g" .md)
  [ -n "$pred" ] || continue
  start=$(date +%s)
  if run_with_timeout "$pred" >/dev/null 2>&1; then r=pass
    sed -i '' "s/^status:.*/status: satisfied/; s/^last-pass:.*/last-pass: $(date +%F)/" "$g"
  else r=FAIL; VIOLATIONS=$((VIOLATIONS+1)); sed -i '' "s/^status:.*/status: VIOLATED/" "$g"; fi
  printf '%s\t%s\t%s\t%ss\n' "$(ts)" "$name" "$r" "$(( $(date +%s) - start ))" >> "$LEDGER"
done
[ "$VIOLATIONS" -gt 0 ] && { grep -l '^status: VIOLATED' goals/*.md; exit 1; }
echo "all standing goals hold"
