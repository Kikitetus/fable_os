# Agentic OS for Fable 5 — ready-to-copy template

Generated from `Agentic_OS_Fable_5_Builders_Guide.md`. Copy this folder's contents
(everything except the guide and this README's setup section) into the root of any
repo with a test command, then follow Setup.

## What was adapted from the guide (and why)

| Change | Reason |
| :--- | :--- |
| `llm` CLI + OpenRouter → `claude -p` with Haiku 4.5 for triage/worker seats | No `llm` install or OpenRouter key needed; runs on your Claude subscription. Override anytime via `CHEAP`/`WORKER`/`VOTER2`/`VOTER3` env vars. |
| `sed -i` → `sed -i ''`, `date -d` → `date -v-7d`, `grep -P` → `awk`, ms timing → seconds, `timeout` → perl-alarm fallback | The guide's scripts use GNU-only syntax; your Mac has BSD tools and bash 3.2. Verbatim, they crash. |
| Triage gate reads the fresh triage output, not all of STATE.md | Guide's `grep STATE.md` would re-trigger forever on old findings. |
| Verifier sees `git diff --cached` after `git add -A` in the worktree | Plain `git diff` misses files the worker newly created. |
| Conductor/verifier calls carry `--fallback-model claude-opus-4-8` and a refusal check | BUILD 0 fact #3: refusals are HTTP 200; official remedy is Opus fallback. Route-tolerance still exits 2 so you never iterate on swapped output. |
| Worker runs with `--permission-mode acceptEdits` and Read/Edit/Write/Glob/Grep only | The guide's `llm` worker could only print text; a real worker needs edit permissions, nothing more. |
| cost-check `--report` printed a doubled `$` | awk printf bug in the guide. |

## Setup (once per repo)

```bash
brew install jq                      # required by loop.sh (conductor JSON parsing)
gh auth login                        # if not already authenticated
cp -R CLAUDE.md Makefile loop /path/to/your-repo/
cd /path/to/your-repo
chmod +x loop/loop.sh loop/quorum.sh loop/verify-goals.sh loop/guardrails/verify.sh loop/scripts/*.sh
$EDITOR CLAUDE.md                    # edit paths, numbers, DISPATCH rows to your reality
$EDITOR loop/guardrails/verify.sh    # edit for your stack; MUST exit 0 on a clean checkout
./loop/guardrails/verify.sh          # CHECK 2: the whole system stands on this script
make tick                            # CHECK 3: run one tick by hand; quiet repo exits 0
```

Costs per tick (defaults): triage ~$0.01, conductor ~$0.35, worker ~$0.10,
verifier ~$0.40. Budget: `DAILY_BUDGET_USD` (default 5). Effort never above high
inside the loop except the conductor's xhigh seat.

## Cron (start Week 2, not before)

```cron
0 7 * * 1-5  cd /path/to/repo/loop && ./loop.sh >> memory/cron.log 2>&1
30 7 * * *   cd /path/to/repo/loop && ./verify-goals.sh >> memory/cron.log 2>&1
```

## Daily driving

```bash
make tick     # one heartbeat by hand
make queue    # what waits for you (review/queued/FAILED/rerouted)
make trust    # the trust ledger, rendered
make audit    # 7-day spend per stage
make goals    # re-verify every standing goal now
make clean-worktrees
```

## The runbook — every alarm and what to do

- **exit 2 (reroute/refusal):** safeguard router swapped models or a classifier
  declined (HTTP 200, `stop_reason: refusal`). Read the checkpoint; re-run the item
  tomorrow; never iterate on swapped output. Recurs on one skill → audit it for
  reasoning-echo or cyber/bio-adjacent phrasing.
- **exit 3 (budget):** `make audit`; find which stage grew; fix the effort map, not the budget.
- **ALERT demoted:** an established skill dropped below 90%. Read its last 3 fails;
  usually the spec pattern, not the worker.
- **goal VIOLATED:** something finished stopped being true. The sentinel gives
  suspects; the fix goes through the normal pipeline.
- **maker/checker standoff x2:** you decide, or run a third fresh reviewer that
  judges evidence and may not split the difference.
- **verify-goals timeout:** that IS a violation; cheapen the predicate.

## The 30-day trust schedule (do not skip graduations)

| Week | Level | You do | Graduate when |
| :--- | :--- | :--- | :--- |
| 1 | L1 report | `make tick` by hand daily; read everything | 3 consecutive runs route exactly as you would have |
| 2 | L2 draft | cron on; `make queue` with coffee | 2 skills cross 20 logged runs |
| 3 | L3 ship | `make audit` vs the cost formula; best skill unattended | 1 week, zero interventions |
| 4 | L4 grow | compost sign-offs; approve 1 proposed skill; run the delete pass | you removed something and nothing broke |

Optional loops live in `loop/optional/` — each file states its install condition.
Installing them speculatively is how systems bloat.
