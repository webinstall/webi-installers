# Part 4 — assets and installers before beta

Do not run upstream binaries on the host. Download raw archives and inspect
them in disposable containers. Use the reusable asset flow:

```sh
sh skills/review-webi-installer/scripts/part4-assets.sh \
  <pkg> <owner/repo> <current-version> [prior-version ...]
```

The script lists tarballs in Ubuntu 24.04 and zip files in Alpine, then runs
`part4-evaluate.sh` in those containers. The evaluator deterministically marks
simple root-binary layouts (`idealist`) and nested binary layouts (`prestige`);
`unknown-agent-review` requires focused agent judgment. Confirm:

- OS, architecture, libc, and extension classification;
- competing CPU/GPU/profile/debug/framework-dependent/installer assets;
- checksum, source, and non-installer assets;
- archive layout and every installer extraction/move glob;
- POSIX shell structure and required package functions;
- PowerShell paths, download, extraction, and copy behavior;
- installed command and binary names;
- current upstream release version.

Run the installer checker from Part 2. Identify the category:
`waif`, `idealist`, `prestige`, `pseudos`, `caravan`, `completionist`,
`heretic`, `legion`, or `pantheon`. Confirm the deterministic result when it
covers the layout; use agent judgment for `unknown-agent-review`, especially
`heretic`. Report `⭐` for idealist/completionist, `⚠️` for waif/heretic, and
`👍` otherwise.

For simple new projects with bad filenames, suggest standard OS/architecture/
libc names. For established APIs or specialized assets, prefer a Webi
classifier or package-specific tagger.

Write the pre-beta report. Use the `read` tool on its path to display the complete
Markdown contents; do not reconstruct it from memory. The assistant
response MUST include that complete report text and a short summary with
**Blockers**,
**Warnings**, **Passes**, **Category**, and **Recommendation**. Do not give
only the recommendation. Then show it through the harness and stop:

```sh
sh skills/review-webi-installer/scripts/review.sh show 4 <part-4-report> --confirm
```

Do not deploy beta from this stage.
