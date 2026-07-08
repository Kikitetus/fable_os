# How to Build An Agentic OS using Fable 5 (Builder's Guide)
This is a complete A–Z breakdown of Claude Fable 5 what it is and how to use it like a 100x engineer
This will change everything about how you work with Claude
Bookmark these 8 builds before you forget 

## Introduction
You have the most capable model ever made generally available, and you are still typing prompts at it one at a time. This guide fixes that.

Used inside a system, it is the closest thing to an employee you can rent for three dollars a day.

This guide builds that system. Not a philosophy of it: the actual files, in order, with a checkpoint after each so you know it works before you stack the next piece on top.

## What you will have at the end:
* A CLAUDE.md the model cannot negotiate with (BUILD 1)
* A daily loop where Fable 5 makes every decision but writes almost no tokens, cheap models do the work, an independent verifier grades it, and a bash script holds the final vote (BUILDs 2-3)
* A trust ledger that grants and revokes autonomy per skill, automatically, based on measured pass rates (BUILD 4)
* A goals directory where everything you ever finish keeps getting re-verified daily, forever, so nothing rots silently (BUILD 5)
* A budget that enforces itself instead of surprising you (BUILD 6)
* Four optional loops (quorum, ratchet, sparring, compost) each with the condition that tells you when to install it (BUILD 7)
* A cron schedule, a runbook for every alarm the system can raise, and a 30-day trust schedule that takes it from supervised to self-extending.

## Who this is for & How to read it
* **Who this is for:** Anyone with a repo, a terminal, and a Claude Code subscription or API key. The examples are code-flavored because loops grew up around codebases, but the goal system and half the loops work on invoices, reports, and reading lists just as well; the predicates are just shell commands.
* **How to read it:** In order, doing the checks. BUILD 0 is the official Anthropic settings and prompt language; everything after it is the system built on top. Each build is 10 to 20 minutes. The 30 days at the end are not reading time; they are the graduated-trust schedule during which the system earns the right to run without you. Total hands-on time: about 2 hours.

### The three principles underneath everything, so you can predict any design decision before you read it:
1. **Laws, not tips.** Every rule has a number, a never, or a command that checks it. Anything softer gets optimized away.
2. **Nothing grades its own homework.** The planner, the worker, the verifier, and the gate are four different parties, and the last one is deterministic.
3. **Nothing that passed once goes unwatched.** Finished work graduates into a re-verified invariant. A goal you only verify once is an assumption with a timestamp.

No essays from here on. Eight builds, each with files, commands, and a checkpoint.

---

## Prerequisites
* bash
* claude CLI (Claude Code) with Fable 5 access # usage credits enabled, /usage-credits cap set
* llm CLI + OpenRouter key # llm install llm-openrouter
* jq, gh, git, make, cron
* a repo with a test command

## What you are building
```markdown
your-repo/
  CLAUDE.md                    # BUILD 1: the constitution
  loop/
    loop.sh                    # BUILD 3: the heartbeat
    conductor.md               # BUILD 3: routing prompt
    triage.md                  # BUILD 3: cheap reader prompt
    contract.md                # BUILD 2: the three lists
    workers/implement.md       # BUILD 3
    workers/verify.md          # BUILD 3
    guardrails/verify.sh       # BUILD 2: deterministic gate
    scripts/trust-log.sh       # BUILD 4
    scripts/log-cost.sh        # BUILD 6
    scripts/cost-check.sh      # BUILD 6
    quorum.sh                  # BUILD 7 (optional)
    verify-goals.sh            # BUILD 5
    goals/                     # BUILD 5: standing goals
    skills/                    # BUILD 4: one file per employee
    memory/
      STATE.md  trust.tsv  goal-ledger.tsv  dispatch.tsv  usage.log
  Makefile                     # BUILD 8: tick / queue / trust / audit / dream
```

---

## BUILD 0: Configure the Engine (from the official Fable 5 docs)
Everything in this build comes from Anthropic's own documentation. Set these before writing any file of your own.

### The spec sheet:
| Setting | Value | Source |
| :--- | :--- | :--- |
| **Model string** | `claude-fable-5` | models overview |
| **Context / output** | 1M tokens / up to 128k output per request | intro docs |
| **Price** | \$10/M in, \$50/M out | intro docs |
| **Thinking** | adaptive, always on; `thinking: {type:"disabled"}` is REJECTED; thinking output is summarized-only | intro + effort docs |
| **Effort** | low medium high xhigh max; high = default = omitting the parameter | effort docs |
| **API shape** | `output_config: {"effort": "..."}` on the Messages API | effort docs |

### Five official facts that change how you build:
1. `max_tokens` is a hard cap on thinking PLUS response text. At high and xhigh, set it large (start at 64k) or Fable runs out of room mid-thought. Applies to every `claude -p` call in this guide.
2. `xhigh` is officially for "long-running agentic tasks (over 30 minutes) with token budgets in the millions." That is the conductor seat and nothing else in this system. The docs also say lower effort on Fable 5 "often exceeds xhigh performance on prior models," so resist upgrading workers.
3. Refusals are HTTP 200. Fable 5 runs safety classifiers (offensive cyber, biology/life-sciences, reasoning-extraction). A declined request returns `stop_reason: "refusal"` as a SUCCESS response. Your scripts must check the stop reason, not the exit code. Official remedy: configure server-side fallbacks or SDK middleware to re-route to Opus 4.8.
4. Never ask Fable to echo its reasoning. Prompts or skills that say "show your thinking" or "explain your reasoning in the response" trigger the `reasoning_extraction` refusal category and elevate fallbacks. Audit every old skill for this when migrating. Read the structured thinking blocks instead.
5. Turns are long by design. Hard tasks run many minutes per request at higher effort; autonomous runs extend for hours. Adjust client timeouts and check on runs asynchronously (scheduled jobs, not blocking waits). This is why the heartbeat is cron, not a blocking loop.

### The official prompt pack
Anthropic ships tested prompt language for Fable 5's known behaviors. These go into your prompts verbatim; do not paraphrase them thinner:

#### 1. Anti-overplanning (for the conductor and any interactive session):
```markdown
When you have enough information to act, act. Do not re-derive facts already established in the conversation, re-litigate a decision the user has already made, or narrate options you will not pursue. If you are weighing a choice, give a recommendation, not an exhaustive survey.
```

#### 2. Anti-gold-plating (for every worker prompt; this is the official fence around over-delivery):
```markdown
Don't add features, refactor, or introduce abstractions beyond what the task requires. A bug fix doesn't need surrounding cleanup. Don't design for hypothetical future requirements: do the simplest thing that works well. Don't add error handling or validation for scenarios that cannot happen. Only validate at system boundaries.
```

#### 3. Grounded progress claims (for any long run; in Anthropic's testing this nearly eliminated fabricated status reports):
```markdown
Before reporting progress, audit each claim against a tool result from this session. Only report work you can point to evidence for; if something is not yet verified, say so explicitly. If tests fail, say so with the output; if a step was skipped, say that.
```

#### 4. Autonomous-pipeline reminder (for every cron-driven prompt; kills the "I'll now run X" early stop):
```markdown
You are operating autonomously. The user is not watching and cannot answer questions mid-task. For reversible actions that follow from the original request, proceed without asking. Before ending your turn, check your last paragraph: if it is a plan, a question, or a promise about work you have not done, do that work now with tool calls. End only when the task is complete or you are blocked on input only the user can provide.
```

#### 5. Official memory format (for the dreamer and memory/learnings/):
```markdown
Store one lesson per file with a one-line summary at the top. Record corrections and confirmed approaches alike, including why they mattered. Don't save what the repo already records; update existing notes rather than duplicating; delete notes that turn out to be wrong.
```

#### 6. Official verifier instruction (the docs state it directly: "separate, fresh-context verifier subagents tend to outperform self-critique"):
```markdown
Establish a method for checking your own work at an interval of [X] as you build. Run this every [X interval], verifying your work with subagents against the specification.
```

Two scaffolding orders from the docs worth obeying: start at the top of your difficulty range (testing Fable only on simple workloads undersells it; give it the hardest unsolved problem and let it scope), and refactor old skills (instructions written for prior models are often too prescriptive for Fable 5 and DEGRADE output; if default performance is better without an instruction, delete the instruction).

**CHECK 0:** Every `claude -p` call in your scripts has an explicit large `max_tokens` where supported; your scripts check for `stop_reason: "refusal"`; no prompt or skill anywhere says "show your thinking."

---

## BUILD 1: The Constitution (CLAUDE.md)
Why, in one line: Fable follows laws and optimizes around tips, so every line needs a number, a never, or a command that checks it.
Rules for the file: four blocks, under 150 lines, no "think step by step" (reasoning is always on; those are paid tokens), no predefined agent personas (Fable designs better teams than you can predefine), mostly stop signs.

Create `CLAUDE.md`:
```markdown
# CLAUDE.md

## NEVER (laws; exceptions require asking first)
- Never exceed 200 changed lines in one commit without asking.
- Never touch src/auth/, src/billing/, migrations/, or prod config unattended.
- Never report work as done from your own assessment. Done = the check passed.
- Never invent a secret, an endpoint, or a convention. Stop and ask.
- Never add a dependency. Propose it in STATE.md and stop.
- Never exceed effort high inside any loop. xhigh is for one-shot reviews only.
- Never edit or delete a test to make it pass. That is a fail, always.- Never echo, transcribe, or explain your internal reasoning in response text. (Official: triggers reasoning_extraction refusals on Fable 5.)
- When a /goal condition passes, write goals/<name>.md with the condition as its predicate before reporting success.

## DISPATCH (route every task; first match wins; log to memory/dispatch.tsv)
| model | marginal | appetite | intelligence | taste |
| :--- | :--- | :--- | :--- | :--- |
| claude-fable-5 | 2 (credits) | 3 | 10 | 10 |
| claude-opus-4-8 | 7 (sub) | 6 | 8 | 9 |
| claude-sonnet-5 | 9 (sub) | 8 | 7 | 7 |
| codex (2nd sub) | 9 | 10 | 9 | 5 |

1. Decision (plan/review/route/standoff) -> fable-5, effort high, read-only.
2. Reads >50k tokens (logs/PDFs/screenshots) -> codex. Never fable.
3. Ships to users (UI/API/copy) -> taste >= 8 gets final pass.
4. Spec complete -> sonnet-5, effort medium.
5. Else sonnet-5; escalate one rung on a miss without asking.

## WORDS
- "intelligence" = hardest problem handled unsupervised
- "taste" = UI/UX, code quality, API design, copy
- "done" = the predicate passes; nothing else
- "small" = under 50 changed lines; "quick" = under 10 minutes of your time
- "cleanup" = behavior identical, verify.sh green before and after

## DONE
- Every task has a machine-checkable done_when before work starts.
- A fresh-context agent that saw neither plan nor draft verifies against it.
- guardrails/verify.sh has the final vote.
- Deviations: conservative option, log to IMPLEMENTATION.md, continue.
- Maker and checker disagree twice -> stop, queue for a human.
```
Edit the numbers and paths to yours. Workflow-specific material (PR procedure, release checklist) goes in `skills/`, not here.

**CHECK 1:** For every line ask: could the model comply 80% and claim success? If yes, rewrite it with a number or a never. `wc -l CLAUDE.md` under 150.

---

## BUILD 2: Walls and Gate
Why: blast radius must be declared before the first tick, and a bash script must hold the final vote.

Create `loop/contract.md`:
```markdown
## acts alone
draft PRs on branches; fix lint/test debt; update STATE.md; label issues

## queues for me
auth, payments, migrations; any skill below "auto" tier; any diff > 400 lines

## wakes me up
verify fails twice on the same item
safeguard router swapped models mid-run
daily budget breached
anything requests a secret
a standing goal is VIOLATED
```

Create `loop/guardrails/verify.sh` (edit for your stack):
```bash
#!/usr/bin/env bash
set -e
npm run typecheck --if-present
npm test --if-present
npm run lint --if-present
```

**CHECK 2:** `./loop/guardrails/verify.sh` runs and exits 0 on your current repo. If it fails now, fix that first; the whole system stands on this script.

---

## BUILD 3: The Heartbeat
Why, in three lines: Fable as worker is a four-figure bill (500k-1M token sessions at \$50/M out); Fable as conductor emits 10-20% of tokens while making 100% of decisions. A \$0.01 model reads the quiet ticks. Agents hand off through a JSON schema so any model fits any seat.

Create `loop/triage.md`:
```markdown
You receive recent commits, open issues, and CI runs. Output ONLY findings:
- finding: <one line>
  evidence: <commit/issue/run id>
  status: actionable | informational

No fixes, no opinions. Nothing to report = output exactly "status: quiet".
Anything touching auth, payments, migrations, secrets = always actionable, noted "contract-sensitive".
```

Create `loop/conductor.md`:
```markdown
You are the conductor. You do not write code. You do not edit files.
1. Read STATE, TRUST LEDGER, CONTRACT below. Do not trust memory of them.
2. Pick the ONE highest-value actionable item.
   contract-sensitive, ambiguous, or likely >400-line diff -> action: queue
   nothing worth doing -> action: stop
3. Else action: execute, with a spec a mediocre model can follow.

Output ONLY this JSON:
{ "action": "execute|queue|stop", "item": "...", "skill": "<kebab-case,stable across runs>", "spec": "...", "done_when": ["<verifiable>", ...] }

You are expensive. Be brief. Your output is a decision, not an essay.
```

Create `loop/workers/implement.md`:
```markdown
You receive a work order (JSON). Execute the spec exactly.
Do the ONE next step toward done_when. Small diffs win.
Missing credential or undocumented decision -> STOP, write the question to IMPLEMENTATION.md. Never invent secrets or conventions.
Record what you did and why in IMPLEMENTATION.md (3 lines max).
```

Create `loop/workers/verify.md`:
```markdown
You receive a SPEC and a DIFF, nothing else. Judge only what is in front of you.
1. Does the diff satisfy every done_when? Cite lines.
2. Anything outside the spec's scope? Instant fail. Deleted/skipped tests? Instant fail.

Output exactly one line: "PASS: <reason>" or "FAIL: <reason>".
The maker was confident. That is not evidence.
```

Create `loop/loop.sh`:
```shell
#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

MAX_ITERS="${MAX_ITERS:-10}"
DAILY_BUDGET_USD="${DAILY_BUDGET_USD:-5}"
CHEAP="${CHEAP:-openrouter/deepseek/deepseek-v4-flash}"
WORKER="${WORKER:-openrouter/moonshotai/kimi-k2.6}"

./scripts/cost-check.sh --budget "$DAILY_BUDGET_USD" || exit 3

for ((i=1; i<=MAX_ITERS; i++)); do
  # 1 TRIAGE: quiet-tick gate, ~$0.01
  { git log --oneline -20; gh issue list --limit 20 2>/dev/null || true;     gh run list --limit 10 2>/dev/null || true; }     | llm -m "$CHEAP" -s "$(cat triage.md)" >> memory/STATE.md
  ./scripts/log-cost.sh triage 0.01
  grep -q "status: actionable" memory/STATE.md || { echo quiet; exit 0; }

  # 2 CONDUCT: Fable, xhigh, fresh context, read-only, JSON out
  claude -p "$(cat conductor.md)STATE: $(cat memory/STATE.md)TRUST: $(./scripts/trust-log.sh --render)CONTRACT: $(cat contract.md)"     --model claude-fable-5 --effort xhigh --allowedTools "Read"     --output-format json > /tmp/c.json
  ./scripts/log-cost.sh conductor 0.35

  # 2a ROUTE-TOLERANCE: never iterate on a model you didn't choose
  SERVED=$(jq -r '.modelUsage | keys[0] // "claude-fable-5"' /tmp/c.json)
  [[ "$SERVED" != *fable* ]] && { echo "rerouted" >> memory/STATE.md; exit 2; }
  jq -r '.result' /tmp/c.json > work-order.json
  SKILL=$(jq -r .skill work-order.json); ACTION=$(jq -r .action work-order.json)
  [[ "$ACTION" == stop  ]] && exit 0
  [[ "$ACTION" == queue ]] && { echo "queued: $SKILL" >> memory/STATE.md; continue; }

  # 3 EXECUTE: cheap worker, isolated worktree
  WT="../wt-$i"; git worktree add "$WT" -b "loop/$SKILL-$i" >/dev/null
  ( cd "$WT" && llm -m "$WORKER" -s "$(cat "$OLDPWD/workers/implement.md")"       "$(cat "$OLDPWD/work-order.json")" > IMPLEMENTATION.md )
  ./scripts/log-cost.sh worker 0.10

  # 4 VERIFY: fresh Fable, no tools, sees only spec + diff
  V=$(claude -p "$(cat workers/verify.md)SPEC: $(jq -r .spec work-order.json)DIFF: $(cd "$WT" && git diff)"     --model claude-fable-5 --effort high --allowedTools ""     --output-format json | jq -r .result)
  ./scripts/log-cost.sh verifier 0.40

  # 5 GATE: deterministic; then ledger; ship only at auto tier
  if [[ "$V" == PASS* ]] && ( cd "$WT" && "$OLDPWD/guardrails/verify.sh" ); then
    ./scripts/trust-log.sh "$SKILL" pass
    if [[ "$(./scripts/trust-log.sh --tier "$SKILL")" == auto ]]; then
      ( cd "$WT" && git add -A && git commit -qm "loop: $SKILL" && gh pr create --fill || true )
      echo "- shipped: $SKILL" >> memory/STATE.md
    else
      echo "- review: $SKILL in $WT" >> memory/STATE.md
    fi
  else
    ./scripts/trust-log.sh "$SKILL" fail
    echo "- FAILED: $SKILL in $WT" >> memory/STATE.md
  fi
  ./scripts/cost-check.sh --budget "$DAILY_BUDGET_USD" || exit 3
done
exit 1   # iteration cap without stop: check STATE.md
```
Exit map: 0 quiet/done, 1 cap, 2 reroute, 3 budget. All labeled, on purpose.

**CHECK 3:** `chmod +x loop.sh guardrails/verify.sh` then run `./loop.sh` once by hand. Confirm: a quiet repo exits 0 for about a penny; an actionable repo produces `work-order.json` with all five fields and a verdict line in `STATE.md`.

---

## BUILD 4: The Trust Ledger
Why: "turn up autonomy as trust grows" is not a mechanism; a TSV with tier rules is. Autonomy is per skill, not per loop.

Create `loop/scripts/trust-log.sh`:
```shell
#!/usr/bin/env bash
# usage: trust-log.sh <skill> <pass|fail> | --render | --tier <skill>
set -euo pipefail
F="$(dirname "$0")/../memory/trust.tsv"; touch "$F"
tier_of() { awk -v r="$1" -v p="$2" 'BEGIN{
  rate=(r>0)?p/r:0
  if (r>=20 && rate>=0.95) print "auto"
  else if (r<10 || rate<0.90) print "watch"
  else print "queue"
}'; }
case "${1:-}" in
  --render)
    printf "%-20s %5s %5s %6s %s
" skill runs pass rate tier
    while IFS=$'	' read -r s r p; do [ -z "$s" ] && continue
      printf "%-20s %5s %5s %5s%% %s
" "$s" "$r" "$p"         "$(awk -v r="$r" -v p="$p" 'BEGIN{printf "%.0f",(r>0)?p/r*100:0}')"         "$(tier_of "$r" "$p")"; done < "$F";;
  --tier)
    line=$(grep -P "^${2}	" "$F" || echo -e "${2}	0	0")
    tier_of "$(cut -f2 <<<"$line")" "$(cut -f3 <<<"$line")";;
  *)
    awk -v s="$1" -v r="$2" -F'	' 'BEGIN{OFS="	"; f=0}
      $1==s {f=1; print s,$2+1,$3+(r=="pass"); next} {print}
      END{if(!f) print s,1,(r=="pass")?1:0}' "$F" > "$F.t" && mv "$F.t" "$F"
    if [ "$2" = fail ]; then
      runs=$(grep -P "^${1}	" "$F" | cut -f2)
      [ "$("$0" --tier "$1")" = watch ] && [ "$runs" -ge 10 ]         && echo "ALERT: $1 demoted to watch after $runs runs" >&2 || true
    fi;;
esac
```
Tier rules: auto = 20+ runs AND 95%+ pass, ships unattended. queue = verified drafts wait for you. watch = under 10 runs or under 90%, draft-only. Demotion is automatic and prints to stderr, which cron mails to you.

Seed the roster: create `loop/skills/<name>/SKILL.md` for each recurring chore (`fix-lint-debt`, `fix-flaky-test`, `bump-deps`, `triage-issues` are the standard four). Each file: frontmatter (name, description, when), steps, a "never" list, a verifiable done-when. Every skill starts at watch.

**CHECK 4:** Run `./scripts/trust-log.sh demo pass` 21 times, then `--tier demo` prints auto. Log a fail on a 10+ run skill and see the ALERT on stderr. Reset: `> memory/trust.tsv`.

---

## BUILD 5: Standing Goals + the Goal Ledger
Why, in one line: a goal you only verify once is an assumption with a timestamp, so finished goals graduate into invariants that are re-verified daily and logged.

Create one file per finished thing, `goals/<name>.md`:
```markdown
predicate: cd $REPO && npm test -- tests/auth 2>&1 | tail -1 | grep -q passing
born: 2026-07-06
source: /goal session 2026-07-06 (fix auth flake)
status: satisfied
last-pass: 2026-07-06
on-violation: wake me. Do not auto-fix.
retire-when: auth module deleted. Retirement is a human decision, logged.
```
Predicate rules: a command; exit 0 = invariant holds; cheap, deterministic, read-only. Adjectives are banned; if a shell script can't check it, the checker can't either. Non-code predicates work the same: `find invoices/overdue -mtime +45 | wc -l` prints 0, `test -s reports/$(date +%Y-%m)-review.md`.

Create `loop/verify-goals.sh`:
```shell
#!/usr/bin/env bash
set -uo pipefail
LEDGER="memory/goal-ledger.tsv"; VIOLATIONS=0
for g in goals/*.md; do
  [ -e "$g" ] || continue
  grep -q '^status: retired' "$g" && continue
  pred=$(grep '^predicate:' "$g" | cut -d' ' -f2-); name=$(basename "$g" .md)
  start=$(date +%s%3N)
  if timeout 60 bash -c "$pred" >/dev/null 2>&1; then r=pass
    sed -i "s/^status:.*/status: satisfied/; s/^last-pass:.*/last-pass: $(date +%F)/" "$g"
  else r=FAIL; VIOLATIONS=$((VIOLATIONS+1)); sed -i "s/^status:.*/status: VIOLATED/" "$g"; fi
  echo -e "$(date -Is)	$name	$r	$(( $(date +%s%3N) - start ))" >> "$LEDGER"
done
[ "$VIOLATIONS" -gt 0 ] && { grep -l '^status: VIOLATED' goals/*.md; exit 1; }
echo "all standing goals hold"
```

Start the sentinel (detection only; fixes go through the normal pipeline):
```markdown
/loop 1d Run ./verify-goals.sh. If non-zero: for each violated goal, read its last-pass date and list what merged since (git log --oneline --since=<date>). Report goal, suspects, on-violation policy. Do not fix anything.
```
The graduation law is already in `CLAUDE.md` (BUILD 1): every passed `/goal` writes its own standing goal. Finishing IS the enrollment.

Ledger queries you will actually use:
```bash
awk -F'	' '$3=="FAIL"{n[$2]++} END{for(g in n) print n[g],g}' memory/goal-ledger.tsv | sort -rn | head -5   # flakiest
grep <goal> memory/goal-ledger.tsv | awk -F'	' '$3=="FAIL"' | head -1                                      # when it broke
```
Flaky predicate: quarantine (`status: retired`, note "needs a better predicate"), never delete.

**CHECK 5:** Add a goal with `predicate: true` and one with `predicate: false`. `./verify-goals.sh` exits 1, flips the second to VIOLATED, and both appear in the ledger. Delete the dummies.

---

## BUILD 6: The Budget
Why: daily cost = ticks × triage + hits × (conductor + worker + verifier). At real prices (triage \$0.01, conductor \$0.35, worker \$0.10, verifier \$0.40): a daily janitor is ~\$2.56/day; a 15-minute babysitter with Fable in the triage seat is \$34/day for the identical outcome. The model that reads the quiet ticks decides the bill.

Create `loop/scripts/log-cost.sh`:
```shell
#!/usr/bin/env bash
echo -e "$(date -Is)	$1	$2" >> "$(dirname "$0")/../memory/usage.log"
```

Create `loop/scripts/cost-check.sh`:
```bash
#!/usr/bin/env bash
set -euo pipefail
F="$(dirname "$0")/../memory/usage.log"; touch "$F"; TODAY=$(date +%F)
case "${1:-}" in
  --budget)
    spent=$(awk -F'	' -v d="$TODAY" '$1 ~ d {s+=$3} END{printf "%.2f",s}' "$F")
    awk -v s="$spent" -v b="$2" 'BEGIN{exit (s>=b)?1:0}'       || { echo "spent \$$spent of \$$2" >&2; exit 1; };;
  --report)
    awk -F'	' -v since="$(date -d '7 days ago' +%F)"       '$1>=since{s[$2]+=$3;t+=$3} END{for(k in s) printf "  %-10s \$$%.2f\n",k,s[k]; printf "  TOTAL      \$$%.2f\n",t}' "$F";;
esac
```
Rules that keep it flat: cadence is a cost decision (halving the interval doubles the floor); the quiet tick must cost cents; effort never above high in loops (xhigh is for one-shot reviews; effort is per step, not per run).

**CHECK 6:** After a week of ticks, `./scripts/cost-check.sh --report` matches the formula within noise. Set `DAILY_BUDGET_USD` to a number you would not mind wasting.

---

## BUILD 7: The Optional Loops (install when their condition appears)

### Quorum (install when dispatch shows Fable wake-ups that produced action: stop)
Three cheap models vote; Fable wakes on 2 of 3. Voters never see each other's answers.
```bash
V=0
for m in deepseek/deepseek-v4-flash qwen/qwen-3.6 moonshotai/kimi-k2.6; do
  llm -m "openrouter/$m" -s "$(cat triage.md)" < /tmp/signals.txt     | grep -q "status: actionable" && V=$((V+1))
done
[ "$V" -ge 2 ] && exec ./conduct.sh || echo "quorum: quiet ($V/3)"
```

### Ratchet (install when one number matters)
Monotonic improvement or self-revert; the metric may not be gamed; the finished floor becomes a standing goal.
```markdown
/goal Reduce `npm run lint 2>&1 | grep -c warning` to 0.
Permissions: edit src/; commit per fix; re-measure after every change.
Walls: the number NEVER goes up; revert any change that raises it or breaks a test; never edit lint config to lower it.
Timebox: stop after 3 attempts with no movement; report survivors.
```

### Sparring (install when you ship code daily)
Builder and breaker, opposed; neither touches the other's output; disputes go to you.
```markdown
/loop 1d [breaker] Read yesterday's merged diffs. Write ONE failing test exposing a real weakness. Commit under tests/sparring/ tagged @sparring. Fix nothing. Solid code = say so, write nothing.

/loop 1d [builder] If any @sparring test fails, fix the CODE until it passes. Never edit, weaken, or delete a sparring test; disputes queue for me.
```

### Compost (install always, weekly)
Failures become laws; three proposals max; human signature required.
```markdown
/loop 7d Read this week's exhaust: FAILED in STATE.md, fails in trust.tsv, FAILs in goal-ledger.tsv, PRs closed unmerged. Extract AT MOST 3 proposals: a new CLAUDE.md law (quote incidents), a skill fix (same failure repeating), or a standing goal we lacked. Propose only. Clean week = say so.
```

**CHECK 7:** Each optional loop has its install condition written next to it in your notes. Installing them speculatively is how systems bloat.

---

## BUILD 8: Ops

Create `Makefile`:
```makefile
tick:            ; ./loop/loop.sh
queue:           ; @grep -E "review:|queued:|FAILED:|rerouted" loop/memory/STATE.md || echo empty
trust:           ; @./loop/scripts/trust-log.sh --render
audit:           ; @./loop/scripts/cost-check.sh --report
goals:           ; @./loop/verify-goals.sh
clean-worktrees: ; @git worktree list | awk '/wt-/{print $$1}' | xargs -rn1 git worktree remove --force
```

Cron, when Week 2 starts:
```markdown
0 7 * * 1-5  cd /path/to/repo/loop && ./loop.sh >> memory/cron.log 2>&1
30 7 * * *   cd /path/to/repo/loop && ./verify-goals.sh >> memory/cron.log 2>&1
```

---

## The 30-day trust schedule
Do not skip graduations; each unlocks the next.

| Week | Level | You do | Graduate when |
| :--- | :--- | :--- | :--- |
| **1** | L1 report | Builds 1-6; make tick by hand daily; read everything | 3 consecutive runs route exactly as you would have |
| **2** | L2 draft | cron on; make queue with coffee; reviews feed the ledger | 2 skills cross 20 logged runs |
| **3** | L3 ship | make audit vs the formula; best skill goes unattended | 1 week, zero interventions |
| **4** | L4 grow | compost signs-offs; approve 1 proposed skill; run the delete pass | you removed something and nothing broke |

### The runbook. What each alarm means and what to do:
* **exit 2 (reroute):** safeguard router swapped models mid-run. Action: read the checkpoint; re-run item tomorrow; never iterate on the swapped output.
* **stop_reason: refusal:** safety classifier declined (HTTP 200, not an error). Action: official path: fallback to Opus 4.8 via fallbacks or middleware; if it recurs on one skill, audit that skill for reasoning-echo or cyber/bio-adjacent phrasing.
* **exit 3 (budget):** daily spend hit the line. Action: make audit; find which stage grew; fix the effort map, not the budget.
* **ALERT demoted:** an established skill dropped below 90%. Action: read its last 3 fails; usually the spec pattern, not the worker.
* **goal VIOLATED:** something finished stopped being true. Action: sentinel gives suspects; fix goes through the normal pipeline.
* **maker/checker standoff x2:** neither is presumed right. Action: you decide, or run the standoff-breaker (third fresh reviewer, judges evidence, may not split the difference).
* **verify-goals timeout:** predicate too expensive. Action: that is a violation; cheapen the predicate.

---

## The Rules (print this)
* Laws, not tips: a number, a never, or a command that checks it.
* The conductor plans, workers execute, neither verifies. `--allowedTools` enforces it.
* Agents talk in work orders. `done_when` = spec + stop condition + future invariant.
* Spend effort where the loop branches. Never above high in a loop.
* The quiet tick costs a penny or the loop costs a grand.
* If a shell script couldn't check it, don't write it as a goal.
* Goals graduate; they do not close. `verify-goals.sh` runs daily, forever.
* Autonomy per skill: 20 runs, 95%, auto. Demotion automatic and loud.
* Two ledgers: trust (workers) and goals (work). Read both with coffee.
* Compute the metabolism before you cron.
* Contract in the repo: acts-alone / queues / wakes-me.
* Never iterate on output from a model you didn't choose.
* The sentinel detects; the pipeline fixes.
* Quorum before waking Fable. Ratchet then weld. Spar daily. Compost weekly.
* One graduation criterion at a time. Every month, delete something.
* From the official docs: `max_tokens` caps thinking plus text, refusals are HTTP 200, never ask for echoed reasoning, old skills degrade Fable, and fresh-context verifiers beat self-critique. Anthropic says so; the system enforces it.
