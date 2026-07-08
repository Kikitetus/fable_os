# Sparring (BUILD 7, optional)

Install condition: you ship code daily. Builder and breaker, opposed; neither
touches the other's output; disputes go to you.

Two loops to run:

```markdown
/loop 1d [breaker] Read yesterday's merged diffs. Write ONE failing test exposing a real weakness. Commit under tests/sparring/ tagged @sparring. Fix nothing. Solid code = say so, write nothing.

/loop 1d [builder] If any @sparring test fails, fix the CODE until it passes. Never edit, weaken, or delete a sparring test; disputes queue for me.
```
