# Part 1 — public triage

Read `AGENTS.md` and collect facts only. Begin with the single harness command
in `SKILL.md`:

```sh
sh skills/review-webi-installer/scripts/review.sh start \
  https://github.com/webinstall/webi-installers/pull/<number> \
  ./agents/reviews/<date>-<pkg>-part-1.md
```

`review.sh start` runs `part1-report.sh` for you and creates the initial report.
Do not run `part1-report.sh` separately. The report script may inspect
PR/repository metadata, check runs, author metadata, and changed-file lists. It
must not fetch arbitrary README, source, release-note, or linked content.

Check the report and record:

- PR title, author, source fork, changed files, and checks;
- checks and their current status;
- repository age, activity, ownership, and release dates;
- PR author age, followers, public repository count, and top repositories by stars and recent activity;
- when the upstream tool owner differs from the PR author, the tool owner account or organization age, followers, public repository count, and top repositories by stars and recent activity;
- changed files and whether scope matches the PR;
- package or alias conflicts;
- author, committer, upstream owner, and homepage identity consistency.

Record a recommendation for the human: continue, pause, or stop. If identity,
scope, or behavior looks suspicious, stop before executing anything untrusted.

Before stopping, run the harness gate, then use the `read` tool on the
report path to display its complete Markdown contents; do not reconstruct the
report from memory. The assistant response MUST include that complete report
text and a short summary with
**Findings**, **Identity/scope result**, and **Recommendation**. Do not give
only the recommendation. The gate prints the next command:

```sh
sh skills/review-webi-installer/scripts/review.sh show 1 <part-1-report> --confirm
```
