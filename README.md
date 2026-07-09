# Agentic OS for Fable 5 — ready-to-copy template

Adapted from [@Av1dlive](https://x.com/Av1dlive)'s article *How to Build an Agentic OS
using Fable 5 (Builder's Guide)* — https://x.com/Av1dlive/status/2074169173178212621 —
with the shell scripts ported to macOS (BSD) tools and the model seats rewired to the
`claude` CLI (see "What was adapted from the guide" below). Copy this folder's contents
into the root of any repo with a test command, then follow Setup.

---

# Plain-English guide (start here if you're new)

*No technical background needed. Read this section top to bottom once.*

## What is this, really?

Think of it as **a tiny team of AI assistants that quietly maintain one of your
projects for you.** Once a day (or whenever you run one command), the team:

1. Looks at what's new in your project — recent code changes, open issues, failed tests.
2. Decides whether there's **one small, safe chore** worth doing (e.g. "clean up
   these warnings," "fix this flaky test," "update this dependency").
3. Does the chore **in a private copy of your project**, so your real code is never
   touched until the work is checked.
4. **Checks its own work twice** — once with an AI reviewer, once by running your
   project's actual tests — before it ever shows you anything.
5. Only lets a chore go through *automatically* after that type of chore has proven
   itself over many runs. Until then, it just leaves you a draft to approve.

Nothing happens without a safety gate. Nothing ships until it's been verified. That
is the whole idea.

## The team — who does what

The system splits the work across four "seats." Each seat is filled by an AI model
chosen for cost vs. brains. Here's the plain-English version:

| Seat | Job (like a...) | Which AI, and why |
| :--- | :--- | :--- |
| **Triage** | Receptionist — glances at what's new, says "worth doing" or "nothing here" | Sonnet — runs every time (was Haiku; you switched it for smarter glances) |
| **Conductor** | Manager — picks the ONE thing to do and writes clear instructions | **Opus** by default; **Fable** if you have access (smartest) |
| **Worker** | Employee — actually does the work, in a private copy | **Sonnet** — does the hands-on labor |
| **Verifier** | Inspector — checks the finished work against the instructions | **Opus** by default; **Fable** if you have access |

The default ships with **Opus** doing the thinking — it works for anyone with Claude
Code, no special access needed. If you have **Fable** access, one setting swaps it in
as the (smarter) thinker. Either way, **Sonnet does the hands-on work.** See
"Choosing the thinking model" below.

## The two "homes" — where files live

Claude Code reads files from two different places, and this matters a lot:

- **The global home:** `~/.claude/` — settings that apply to *every* project on your
  computer. (The `~` means your Mac home folder, e.g. `/Users/you`.)
- **The project home:** the folder of whatever project you're working on, e.g.
  `~/projects/my-app/`.

**Almost all of this system lives in the project home**, because it works on *that
project's* specific code, tests, and history. Only one thing belongs in the global
home: the short table that says which model does the thinking vs. the hands-on work — so
that even your normal chats route the same way. (You already have that table in this
folder's `CLAUDE.md`.)

> **Simple rule:** the whole `loop/` folder + `CLAUDE.md` + `Makefile` get copied
> into **each project** you want maintained. The model-routing table *also* gets
> pasted into `~/.claude/CLAUDE.md` once, so it applies everywhere.

## Every file and folder — where it goes and what it does

You copy `CLAUDE.md`, `Makefile`, and the entire `loop/` folder into your project's
top folder. Inside `loop/`, everything is already in the right place. Here's what
each piece is, in plain English:

**Top level of your project:**

| File / folder | What it is |
| :--- | :--- |
| `CLAUDE.md` | The **rulebook**. Lists what the AI must never do, and which AI to use for which job. Read by every assistant, every time. |
| `Makefile` | A **menu of shortcuts**. Lets you type short commands like `make tick` instead of long ones. |
| `loop/` | The **engine room** — everything below lives inside here. |

**Inside `loop/` — the engine:**

| File | What it does |
| :--- | :--- |
| `loop/loop.sh` | The **heartbeat**. Running it does one full cycle: look → decide → do → check. This is the main program. |
| `loop/triage.md` | The receptionist's instructions: "here's what's new; is anything worth doing?" |
| `loop/conductor.md` | The manager's instructions: "pick the single best chore and write clear steps." |
| `loop/contract.md` | The **house rules for decisions** — what the AI may do alone, what it must ask you about (auth, payments, big changes), and what must wake you up. |
| `loop/workers/implement.md` | The employee's instructions: "do exactly this one step, keep it small, don't invent things." |
| `loop/workers/verify.md` | The inspector's instructions: "does this work match the request? Pass or fail, one line." |
| `loop/guardrails/verify.sh` | The **final automated gate** — actually runs your project's tests/linter. If this fails, nothing ships. *You edit this one to match your project.* |

**Inside `loop/` — the memory (the system's notebook, tracks itself over time):**

| File | What it does |
| :--- | :--- |
| `loop/memory/STATE.md` | The **running diary** — what happened each cycle, what's waiting for you. |
| `loop/memory/trust.tsv` | The **report card** — how often each chore-type succeeded. A chore only earns the right to ship automatically after 20+ runs at 95%+ success. |
| `loop/memory/usage.log` | The **spending log** — how much each step cost, so it can stop at your daily budget. |
| `loop/memory/dispatch.tsv` | A record of which AI was chosen for which task. |
| `loop/memory/goal-ledger.tsv` | A log of the daily "is this still fixed?" checks (explained next). |

**Inside `loop/` — standing goals (things that must stay fixed):**

| File | What it does |
| :--- | :--- |
| `loop/goals/` | One file per "thing I fixed and want to *stay* fixed." Each has a tiny test the system re-runs **every day, forever**. If something breaks it later, you get alerted. |
| `loop/verify-goals.sh` | The program that runs all those daily "still fixed?" checks. |
| `loop/goals/README.md` | Instructions and a template for writing a new goal. (Not a goal itself.) |

**Inside `loop/` — reusable chore recipes and extras:**

| File | What it does |
| :--- | :--- |
| `loop/skills/` | The **recipe book** — one folder per chore the team knows how to do (fix lint, bump dependencies, triage issues, fix a flaky test). Each recipe says its steps, its "never do this" list, and how to know it's done. |
| `loop/scripts/` | Small helper programs the engine uses for bookkeeping (updating the report card, logging cost, checking the budget). You don't run these directly. |
| `loop/quorum.sh` | An *optional* stricter check: ask three cheap AIs and only proceed if at least two agree there's work. Turn on later, if ever. |
| `loop/optional/` | *Optional* add-on behaviors, each turned off by default. Each file says when to switch it on. **Ignore these at the start** — adding them early just adds clutter. |

## Choosing the thinking model (Opus by default, Fable opt-in)

You do **not** edit code to switch models — you set them as one-time options in front
of the command. **Opus is the shipped default**, so `make tick` works out of the box
for anyone with Claude Code.

```bash
# Default — Opus does the thinking:
make tick

# If you have Fable access — swap it in as the (smarter) thinker:
CONDUCTOR_MODEL=claude-fable-5 make tick
```

- `CONDUCTOR_MODEL` = who does the **thinking** (manager + inspector seats). Default `claude-opus-4-8`.
- `WORKER` = who does the **hands-on work**. Default `claude-sonnet-5`.
- `CHEAP` = who does the quick first glance. Default `claude-sonnet-5`; set to `claude-haiku-4-5-20251001` to make ticks cheaper.

**A built-in safety, not a gotcha:** the loop only ever continues on output from the
model *you* chose. If a safeguard router silently serves a **different** model than you
asked for, the run stops on purpose (`exit 2`) so you never iterate on swapped-in
output. Whichever model you set as `CONDUCTOR_MODEL` is accepted as your deliberate
choice — the guard fires only on an unexpected substitution.

## What to expect after you set it up

Once the files are in a project and you've run the setup checks:

- **Run `make tick` and one of two things happens.** Either it says `quiet` (nothing
  worth doing — totally normal and good), or it quietly does one small chore in a
  private copy, checks it, and leaves you the result.
- **Nothing risky happens on its own.** Anything touching logins, payments, database
  changes, or big edits is *always* set aside for you to approve, by design.
- **You review with one command:** `make queue` shows everything waiting for you —
  drafts to approve, things that failed, anything that needs a human.
- **Trust grows slowly and on purpose.** For the first weeks, the system only drafts;
  you approve everything. A chore-type only "graduates" to shipping on its own after
  it proves itself. The 30-day schedule near the bottom of this README walks you
  through it — don't rush it.
- **It won't overspend.** It tracks cost per run and stops at your daily budget
  (default $5). `make audit` shows where the money went.
- **Things you fixed stay fixed.** Each morning it re-checks your standing goals; if
  something regresses, you're told which recent change is the likely cause.

**How this improves your work:** the small, boring, easy-to-forget maintenance
(warnings, flaky tests, stale dependencies, un-triaged issues) gets handled quietly
and *safely* in the background, while anything important or risky is always routed to
you. You get the upside of an always-on assistant without the fear of it breaking
something behind your back — because every change is checked twice and gated on your
real tests before it's allowed through.

---

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

## Prerequisites

- **macOS.** The scripts use BSD tools (`sed -i ''`, `date -v-7d`) and bash 3.2.
  **Linux is not supported yet** (GNU coreutils differ) — a known limitation, contributions welcome.
- **[`jq`](https://jqlang.github.io/jq/)** — `brew install jq` (the loop parses the conductor's JSON with it).
- **[GitHub CLI `gh`](https://cli.github.com/), authenticated** — `gh auth login` (reads issues/CI runs, opens PRs).
- **[Claude Code](https://claude.com/claude-code) (the `claude` CLI) + a Claude subscription** —
  every seat is a `claude -p` call, so this runs on your own Claude usage/credits.
- **`perl`** — ships with macOS; used only as a `timeout` fallback.

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

Costs per tick (defaults, triage/worker now on Sonnet): triage ~$0.04,
conductor ~$0.35, worker ~$0.30, verifier ~$0.40. Budget: `DAILY_BUDGET_USD`
(default 5). Effort never above high inside the loop except the conductor's xhigh
seat. (To go back to the cheaper Haiku seats: `CHEAP=claude-haiku-4-5-20251001
WORKER=claude-haiku-4-5-20251001 make tick`.)

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
