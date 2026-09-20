# Final aggregate

After Part 4 and any authorized beta matrix, show all reports together:

Use the `read` tool on each of these paths so the reviewer harness displays
all four reports as Markdown:

```text
./agents/reviews/<date>-<pkg>-part-1.md
./agents/reviews/<date>-<pkg>-part-2.md
./agents/reviews/<date>-<pkg>-part-3.md
./agents/reviews/<date>-<pkg>-part-4.md
```

Use the `read` tool on all four report paths to display their complete
Markdown contents; do not reconstruct or summarize them from memory. The
assistant response MUST include the complete
contents of all four reports, not only a summary. Then give a short respectful
summary with:

- **Blockers:** issues that stop listing;
- **Warnings:** risks or platform limits;
- **Passes:** completed checks;
- **Category:** category plus `⭐`, `👍`, or `⚠️`;
- **Recommendation:** approve, request changes, or stop.

The human maintainer decides. State observed behavior, quote only useful
evidence, and do not ask maintainers to fix Webi-side problems that belong in
a shared classifier.
