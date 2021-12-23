---
title: ots
homepage: https://github.com/emdneto/otsgo
tagline: |
  A simple CLI and API client for One-Time Secret
---

To update or switch versions, run `webi ots@stable` (or `@v2`, `@beta`,
etc).

### Files

These are the files / directories that are created and/or modified with this
install:

```txt
~/.config/envman/PATH.env
~/.local/bin/ots
~/.local/opt/ots
```

## Cheat Sheet

### Share a generated secret

```bash
ots share -g
```

### Share custom secret with ttl and passphrase

```bash
ots share -s hellosecret -t 300 -p hello
```

### Share secret from file
```bash
cat <<EOF | ots share -f -
secret: hello
seret: secret
EOF
```

```bash
echo "hellosecret" | ots share -f
```

### Burn secrets
```bash
ots burn METADATA_KEY
```

### Get secret value
```bash
ots get secret SECRET_KEY
```
### Get secret metadata
```bash
ots get meta METADATA_KEY
```
### Get recent secrets (requires auth)
```bash
ots get recent
```