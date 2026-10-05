---
title: gha-doctor
homepage: https://github.com/linnea-bakshi/gha-doctor
tagline: |
  gha-doctor: Diagnose your GitHub Actions — flaky jobs, wasted minutes, slow
  steps, cache misses, and workflow anti-patterns, in one command.
---

To update or switch versions, run `webi gha-doctor@stable` (or `@v0.66`,
`@beta`, etc).

### Files

These are the files that are created and/or modified with this installer:

```text
~/.config/envman/PATH.env
~/.local/bin/gha-doctor
~/.local/opt/gha-doctor-VERSION/bin/gha-doctor
```

## Cheat Sheet

> `gha-doctor` reads your repo's workflow files and recent run history (via your
> existing `gh` auth) and reports what's actually wrong with your CI: which jobs
> are flaky (and the exact failing tests), where billable minutes are being
> wasted, which steps are slow, whether your caches hit, and which scheduled
> workflows are zombies — plus a lint pass with auto-fixes for common workflow
> anti-patterns.

It authenticates with the [gh](https://webinstall.dev/gh) CLI's token (or
`GITHUB_TOKEN`), so log in once first:

```sh
webi gh
gh auth login
```

### How to check a repository's CI health

Run it from inside a clone (or point it anywhere with `--repo`):

```sh
gha-doctor
gha-doctor --repo cli/cli
```

You get a health score plus sections for flaky jobs (with the failing test names
pulled from logs and test-report artifacts), wasted minutes and their dollar
cost, slow steps, cache checkup, zombie crons, and lint findings.

### How to find out why a PR is red

```sh
gha-doctor --pr 1234
```

Shows the PR's head-commit runs, time-to-first-red, and digs into the latest
failed run to name the failing tests. For a specific run instead:

```sh
gha-doctor --run 9876543210
```

### How to auto-fix workflow anti-patterns

Preview first, then apply:

```sh
gha-doctor --diff    # unified diff of what --fix would change
gha-doctor --fix     # rewrites .github/workflows/*.yml in place
```

### How to gate CI on Actions health

Fail the build on lint warnings or a low score:

```sh
gha-doctor --fail-on warning
gha-doctor --min-score 80
```

Machine-readable output for scripting and dashboards: `--json`, `--sarif`,
`--md`, `--html`, or `--prom`.

### How to triage a whole org

```sh
gha-doctor --org my-org
```

Gives per-repo run stats — fail rate, p50/p95 run times, and minutes over the
last 30 days — so you can see which repos burn the most CI and drill into them
with `--repo`.
