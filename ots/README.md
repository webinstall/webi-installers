---
title: ots
homepage: https://github.com/emdneto/otsgo
tagline: |
  A simple CLI and API client for One-Time Secret
---

To update or switch versions, run `webi ots@stable` (or `@v2`, `@beta`, etc).

### Files

These are the files / directories that are created and/or modified with this
install:

```text
~/.config/envman/PATH.env
~/.local/bin/ots
~/.local/opt/ots
```

## Cheat Sheet

### Share a generated secret

```sh
ots share -g
```

### Share custom secret with ttl and passphrase

```sh
ots share -s hellosecret -t 300 -p hello
```

### Share secret from file

```sh
cat <<EOF | ots share -f -
secret: hello
seret: secret
EOF
```

```sh
echo "hellosecret" | ots share -f
```

### Burn secrets

```sh
ots burn METADATA_KEY
```

### Get secret value

```sh
ots get secret SECRET_KEY
```

### Get secret metadata

```sh
ots get meta METADATA_KEY
```

### Get recent secrets (requires auth)

```sh
ots get recent
```
