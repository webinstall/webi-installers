---
title: OutageDeck
homepage: https://outagedeck.com/developers/cli
tagline: |
  OutageDeck checks live cloud and SaaS provider status from the terminal.
---

To update or switch versions, run `webi outagedeck@stable` (or `@0.1.3`).

### Files

These are the files that are created and/or modified with this installer:

```text
~/.config/envman/PATH.env
~/.local/bin/outagedeck
~/.local/opt/outagedeck-VERSION/bin/outagedeck
```

## Cheat Sheet

> `outagedeck` checks normalized official status feeds before you spend time
> debugging a build, deployment, or application that depends on an upstream
> service.

### Check a dependency stack

Pass the provider slugs used by your application:

```sh
outagedeck status aws cloudflare github openai
```

The result keeps vendor-reported incidents separate from your own application
health. It is useful context, not a replacement for a direct health check.

### Find a provider slug

```sh
outagedeck search "Claude"
outagedeck search "Google Cloud"
```

### Use OutageDeck in CI

Fail only when a provider reports an outage:

```sh
outagedeck status --fail-on=outage aws cloudflare github
```

For an advisory check that never fails the job:

```sh
outagedeck status --fail-on=never aws cloudflare github
```

`--fail-on` also accepts `degraded` and `major_outage`.

### Read structured output

```sh
outagedeck status --json --fail-on=never github openai |
    jq '.providers[] | {name, status, activeIncidents}'
```

### Turn a stack into alerts

```sh
outagedeck alerts aws cloudflare github openai
```

This prints a prefilled OutageDeck alert setup link for the same providers.
Public status checks are keyless and read-only. The CLI sends no telemetry.

See the
[CLI guide](https://outagedeck.com/developers/cli?utm_source=webi&utm_medium=installer&utm_campaign=cli_distribution)
for exit codes, JSON output, and API quota details.
