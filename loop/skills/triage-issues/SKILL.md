---
name: triage-issues
description: Label and de-duplicate open issues; no code changes.
when: open issues exist without labels, or duplicates are suspected
---

## Steps
1. Read unlabeled open issues (gh issue list).
2. Apply existing labels only (bug/feature/docs/question, priority if defined).
3. Comment "duplicate of #N" where a clear duplicate exists; do not close.

## Never
- Never create new labels.
- Never close an issue.
- Never edit code in this skill.

## done_when
- zero unlabeled open issues remain
- every action taken is listed in IMPLEMENTATION.md with issue numbers
