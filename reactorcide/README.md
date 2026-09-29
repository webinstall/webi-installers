---
title: reactorcide
homepage: https://github.com/catalystcommunity/reactorcide
tagline: |
  reactorcide: A CI/CD system for ephemeral container and VM jobs.
description:
  A single binary CLI and coordinator for Reactorcide. Use it to run CI jobs in
  a local container, submit jobs to a remote coordinator, and manage tokens,
  secrets, jobs, and workflows.
---

To update or switch versions, run `webi reactorcide@stable` (or `@v0.12.0`,
`@beta`, etc).

### Files

These are the files that are created and/or modified with this installer:

```text
~/.config/envman/PATH.env
~/.local/bin/reactorcide
~/.local/opt/reactorcide-VERSION/bin/reactorcide
```

## Cheat Sheet

> `reactorcide` runs CI/CD jobs in containers or VMs. The same binary is the
> server, the worker, and the CLI you run from your workstation.

### How to run a job on your own machine

Put your job files in `.reactorcide/jobs/`. Run one job file with `run-local`.
Docker must be running:

```sh
reactorcide run-local .reactorcide/jobs/test.yaml
```

`run-local` mounts the current repository at `/job/src` and `/job/ci`. Use
`--source-dir` to mount a different source directory. Use `--ci-dir` to mount a
different trusted CI directory.

To see the commands `run-local` would run, without running them, add
`--dry-run`:

```sh
reactorcide run-local --dry-run .reactorcide/jobs/test.yaml
```

Run as the deployed runner user (uid 1001) instead of your host user with
`--as-runner`. Use this when a job needs `sudo` or the runner's `HOME`:

```sh
reactorcide run-local --as-runner .reactorcide/jobs/test.yaml
```

### How to run a workflow locally

Give `run-local` a workflow file instead of a job file. Reactorcide evaluates
the workflow for one event and runs each job that matches:

```sh
reactorcide run-local \
  --event pull_request_updated \
  --changed-file src/app.py \
  --max-parallel 4 \
  .reactorcide/workflows/pr.yaml
```

Repeat `--changed-file` for each changed path. Reactorcide writes the result to
`reactorcide-workflow-summary.json`. This file lists node states and variable
names. It does not list variable values.

### How to test a different checkout

Use `--code-url` and `--code-ref` to clone a different repository or branch into
the job, instead of mounting your working copy:

```sh
reactorcide run-local \
  --code-url https://github.com/example/app.git \
  --code-ref feature/my-branch \
  .reactorcide/jobs/test.yaml
```

### How to submit a job to a coordinator

Set the coordinator URL and your API token as environment variables. Then submit
the job file:

```sh
export REACTORCIDE_API_URL=https://ci.example.com
export REACTORCIDE_API_TOKEN=your-token-here
reactorcide submit .reactorcide/jobs/deploy.yaml
```

Add `--wait` to block until the job finishes and print its final status. Use
`--poll-interval` to change how often the CLI checks (default 5 seconds):

```sh
reactorcide submit --wait --poll-interval 10 .reactorcide/jobs/deploy.yaml
```

Merge extra values into the job at submit time with `--overlay`. Repeat the flag
to layer more than one file:

```sh
reactorcide submit \
  --overlay ./overlays/staging.yaml \
  .reactorcide/jobs/deploy.yaml
```

### How to list and inspect jobs

List recent jobs in a table, or filter by status:

```sh
reactorcide jobs list
reactorcide jobs list --status failed --limit 20
```

Ask for JSON when you pipe the output to another tool:

```sh
reactorcide jobs list --format json --queue-name default
```

Get one job by ID, then cancel or retry it:

```sh
reactorcide jobs get <job-id>
reactorcide jobs cancel <job-id>
reactorcide jobs retry <job-id>
```

`cancel` waits for cleanup hooks to run. `kill` skips them and needs admin
rights. Use `kill` only when a job is stuck.

### How to read job logs

Fetch the combined stdout and stderr for a job:

```sh
reactorcide logs <job-id>
```

Get only one stream, or save the log to a file:

```sh
reactorcide logs <job-id> --stream stderr
reactorcide logs <job-id> --output ./job.log
```

### How to create and use an API token

An admin creates the first token directly against the database, since no token
exists yet to authenticate through the API:

```sh
reactorcide token create \
  --name ci-bot \
  --db-uri "$REACTORCIDE_DB_URI" \
  --capability submit-job
```

After that, list and delete tokens through the API like any other user:

```sh
reactorcide token list
reactorcide token delete <token-id>
```

Export the token once, so every other command picks it up automatically:

```sh
export REACTORCIDE_API_TOKEN=your-token-here
```

### How to manage secrets

Initialize local secret storage once per machine:

```sh
reactorcide secrets init
```

Set a secret, then read it back for a script:

```sh
reactorcide secrets set myapp/db password --value 'hunter2'
DB_PASSWORD=$(reactorcide secrets get myapp/db password)
```

Pipe a value in instead of typing it, and list the keys under a path without
showing their values:

```sh
printf '%s' "$TOKEN" | reactorcide secrets set myapp/api token --stdin
reactorcide secrets list myapp/db
```

Reference a secret from a job file with `${secret:path:key}`. Never write the
plain value into a job or workflow file:

```yaml
env:
  DB_PASSWORD: ${secret:myapp/db:password}
```

### How to write a minimal job file

```yaml
name: test
image: containers.catalystsquad.com/public/reactorcide/runnerbase:latest
command:
  - python3
  - -m
  - pytest
  - -q
```

### How to write a minimal workflow file

Give every workflow a stable `id`. Reactorcide uses the `id` as its security
identity, not the display `name`:

```yaml
id: pr-checks
name: Pull request checks
on:
  events:
    - pull_request_opened
    - pull_request_updated
  branches:
    - main
jobs:
  test:
    job_file: test.yaml
```

Put workflow files in `.reactorcide/workflows/` and job files in
`.reactorcide/jobs/`. Reactorcide finds them there without extra configuration.
