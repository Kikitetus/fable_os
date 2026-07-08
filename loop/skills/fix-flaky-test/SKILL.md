---
name: fix-flaky-test
description: Make an intermittently failing test deterministic by fixing the cause.
when: a test failed then passed on retry (CI history shows both) within the last week
---

## Steps
1. Reproduce: run the suspect test 10 times; record pass/fail counts.
2. Find the nondeterminism source (timing, shared state, ordering, network).
3. Fix the CODE or the test's setup/teardown, not the assertion.
4. Re-run the test 10 times; all 10 must pass.

## Never
- Never delete, skip, or weaken the test. That is a fail, always.
- Never add retries or sleeps as the fix.

## done_when
- the target test passes 10 consecutive runs
- guardrails/verify.sh exits 0
