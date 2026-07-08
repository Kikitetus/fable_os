---
name: fix-lint-debt
description: Reduce existing lint warnings without changing behavior.
when: lint reports warnings on the default branch and no open PR touches the same files
---

## Steps
1. Run the linter and count warnings.
2. Fix the smallest coherent batch, under 50 changed lines.
3. Re-run lint and the full test suite.

## Never
- Never edit lint config to silence a rule.
- Never change runtime behavior; cleanup = verify.sh green before and after.
- Never touch files listed in contract.md "queues for me".

## done_when
- lint warning count is strictly lower than before the change
- guardrails/verify.sh exits 0
