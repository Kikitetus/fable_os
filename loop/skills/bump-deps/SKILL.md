---
name: bump-deps
description: Apply patch/minor dependency updates that pass the full gate.
when: outdated patch or minor versions exist with no breaking-change notes
---

## Steps
1. List outdated dependencies; select PATCH and MINOR bumps only.
2. Bump ONE dependency (or one tightly coupled group) per run.
3. Install, then run guardrails/verify.sh.

## Never
- Never bump a major version. Queue it with the changelog link instead.
- Never add a new dependency. Propose it in STATE.md and stop.
- Never touch lockfile resolutions by hand.

## done_when
- exactly one dependency (group) bumped in the diff
- guardrails/verify.sh exits 0
