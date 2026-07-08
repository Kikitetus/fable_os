# Ratchet (BUILD 7, optional)

Install condition: one number matters. Monotonic improvement or self-revert; the
metric may not be gamed; the finished floor becomes a standing goal.

Prompt to run (edit the metric):

```markdown
/goal Reduce `npm run lint 2>&1 | grep -c warning` to 0.
Permissions: edit src/; commit per fix; re-measure after every change.
Walls: the number NEVER goes up; revert any change that raises it or breaks a test; never edit lint config to lower it.
Timebox: stop after 3 attempts with no movement; report survivors.
```
