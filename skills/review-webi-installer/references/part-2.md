# Part 2 — adversarial PR review

Review only the submitted files, especially README, releases.conf,
install.sh, install.ps1, and test changes.

Search every changed file for unexpected commands, downloads, uploads,
redirects, encoded content, persistence, secrets, unsafe extraction, and
unrelated behavior. Check README progressive disclosure, Files-before-Cheat
Sheet order, paths, claims, examples, and footguns.

Review release source, filters, asset names, version behavior, package paths,
archive globs, `WEBI_SINGLE`, and version parsing. Read
`skills/create-webi-installer-and-pr/SKILL.md` for Webi conventions.

Run the repeatable checks against the reviewed commit:

```sh
sh skills/review-webi-installer/scripts/part2-checks.sh \
  <commit> <pkg> <upstream-owner/repo>
```

This runs installer checks, `git diff --check`, a changed-file command scan,
release metadata inspection, and the changed-file summary. The checker uses the
project format command without mutation:

```sh
shfmt -d -i 4 -sr -ci -s <changed-shell-file>
```

Record each file's result, current upstream release version, evidence, and one
recommendation. Do not proceed to executable or downloaded-package tests if
this part finds suspicious behavior or an unresolved high-risk issue.

After writing the report, use the `read` tool on its path to display the
complete Markdown contents; do not reconstruct the report from memory. The
assistant response MUST include that complete report text and a short summary
with
**Blockers**, **Warnings**, **Passes**, and **Recommendation**. Do not give
only the recommendation.

Then show it through the harness:

```sh
sh skills/review-webi-installer/scripts/review.sh show 2 <part-2-report> --confirm
```
