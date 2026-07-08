# Standing goals (BUILD 5)

One file per finished thing. A goal you only verify once is an assumption with a
timestamp; these are re-verified daily by `../verify-goals.sh`, forever.

Predicate rules: a shell command; exit 0 = invariant holds; cheap, deterministic,
read-only. Adjectives are banned; if a shell script can't check it, the checker
can't either. Non-code predicates work the same:
`find invoices/overdue -mtime +45 | wc -l | grep -qx 0`, or
`test -s reports/$(date +%Y-%m)-review.md`.

Flaky predicate: quarantine (`status: retired`, note "needs a better predicate"),
never delete. Retirement is a human decision, logged.

Template — copy to `<name>.md`:

```markdown
predicate: cd $REPO && npm test -- tests/auth 2>&1 | tail -1 | grep -q passing
born: 2026-07-08
source: /goal session 2026-07-08 (fix auth flake)
status: satisfied
last-pass: 2026-07-08
on-violation: wake me. Do not auto-fix.
retire-when: auth module deleted. Retirement is a human decision, logged.
```

Ledger queries you will actually use:

```bash
# flakiest goals
awk -F'\t' '$3=="FAIL"{n[$2]++} END{for(g in n) print n[g],g}' ../memory/goal-ledger.tsv | sort -rn | head -5
# when a goal first broke
grep <goal> ../memory/goal-ledger.tsv | awk -F'\t' '$3=="FAIL"' | head -1
```
