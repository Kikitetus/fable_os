# Goal sentinel (BUILD 5 — start when you have real goals)

Detection only; fixes go through the normal pipeline.

```markdown
/loop 1d Run ./verify-goals.sh. If non-zero: for each violated goal, read its last-pass date and list what merged since (git log --oneline --since=<date>). Report goal, suspects, on-violation policy. Do not fix anything.
```
