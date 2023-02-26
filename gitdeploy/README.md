---
title: gitdeploy
homepage: https://github.com/therootcompany/gitdeploy
tagline: |
  gitdeploy receives git webhooks and runs build and deploy scripts.
---

To update or switch versions, run `webi gitdeploy@stable`.

## Cheat Sheet

> gitdeploy makes it easy to build and deploy static sites (or anything else)
> from git webhooks.

Works with

- GitHub
- Gitea
- Bitbucket
- and more ...

To get set up, you'll want to copy the example scripts and dotenv:

```sh
# The example scripts are a good starting point
rsync -av examples/ scripts/

# Edit this (or delete it)
mv scripts/dotenv .env
```

```sh
gitdeploy run --listen :4483 --github-secret xxxxx --exec scripts/
```

When gitdeploy receives a webhook it runs `scripts/deploy.sh` with the following
environment variables set:

```sh
GIT_REPO_ID=github.com/my-org/my-project

GIT_CLONE_URL=https://github.com/my-org/my-project.git

GIT_REPO_OWNER=my-org
GIT_REPO_NAME=my-project
GIT_REF_TYPE=branch
GIT_REF_NAME=master

GIT_DEPLOY_JOB_ID=xxxxxx
```

The example `deploy.sh` looks for `deploy.sh` in the directory matching your
repository's URL, like this:

- ./scripts/github.com/example/project/deploy.sh

### How to create a build & deploy script

The deploy scripts should exist in your `scripts/` directory, named after the
repo's name.

```text
scripts/github.com/YOUR_ORG/YOUR_PROJECT/deploy.sh
```

1. Create a directory that matches the `GIT_REPO_ID`:
   ```sh
   mkdir -p scripts/github.com/YOUR_ORG/YOUR_PROJECT
   ```
2. Create a `deploy.sh` that builds and deploys your project:

   ```sh
   #!/bin/bash

   # Put bash in strict mode or bad things will happen.
   set -u
   set -e

   # maybe you do different things with different branches
   # in this case we just ignore all branches except for master
   if [[ "${GIT_REF_NAME}" != "master" ]]
   then
       echo "Nothing to do for ${GIT_REPO_ID}#${GIT_REF_NAME}"
       exit 0
   fi

   # make a temporary directory for the build
   my_tmp="$(mktemp -d -t "tmp.XXXXXXXXXX")"
   git clone --depth=1 "${GIT_CLONE_URL}" -b "${GIT_REF_NAME}" "${my_tmp}/${GIT_REPO_NAME}"

   pushd "${my_tmp}/${GIT_REPO_NAME}/"
       echo "Deploying ${GIT_REPO_ID}#${GIT_REF_NAME} ..."

       # run an example build process
       npm ci
       npm run build

       # deploy to an example staging site
       rsync -av ./ ~/srv/staging.example.com/public/
   popd

   # clean up after the build
   rm -rf "${my_tmp}/${GIT_REPO_NAME}/"
   ```

### How to set up a webhook

1. Generate a 128-bit random string:
   ```sh
   xxd -l16 -ps /dev/urandom
   ```
2. Create a new Web Hook on your git platform:
   - Github: `https://github.com/YOUR_ORG/YOUR_REPO/settings/hooks/new`
   - Gitea: `https://GIT_DOMAIN/YOUR_ORG/YOUR_REPO/settings/hooks/gitea/new`
     - Webhook: `https://YOUR_DOMAIN/api/webhooks/gitea`
   - BitBucket:
     `https://bitbucket.org/YOUR_ORG/YOUR_REPO/admin/addon/admin/bitbucket-webhooks/bb-webhooks-repo-admin`
3. Set the content type to JSON.
4. Add the Webhook URL:

   ```sh
   # Github
   https://YOUR_DOMAIN/api/webhooks/github

   # Gitea
   https://YOUR_DOMAIN/api/webhooks/gitea

   # Bitbucket
   https://YOUR_DOMAIN/api/webhooks/bitbucket?access_token=YOUR_SECRET
   ```

### How to use ENVs (and .env)

Most of the flags, such as `--port` and `--github-secret` can also be set as
ENVs. You can create a `.env` like this, for example:

```sh
PORT=4483

GITHUB_SECRET=xxxxxxxxxxx
```

See the
[examples/dotenv](https://git.rootprojects.org/root/gitdeploy/src/branch/master/examples/dotenv)
for more info.

### How to use Deploy Keys & Personal Access Tokens

See the
[Git Credentials Cheat Sheet](https://coolaj86.com/articles/vanilla-devops-git-credentials-cheatsheet/)
at <https://coolaj86.com/articles/vanilla-devops-git-credentials-cheatsheet/>.

### How to reverse Proxy with HTTPS (Let's Encrypt)

See the [Caddy (Web Server) Cheat Sheet](https://webinstall.dev/caddy).
