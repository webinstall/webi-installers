# Releasing xz-compressed?

And publishing with Git Releases?

If so, you can copy one of the given examples, do a little find-and-replace, and
viola, you've got your Webi installer!

Each example has four files that need to be modified, just slightly:

- install.sh
- install.ps1
- releases.js
- README.md

## Bare Releases (with compression) as `.xz`

See [./gitea/](/gitea/) as an example.

```sh
rsync -av ./keypairs/ ./my-project/
```

Gitea is compressed for Mac and Linux as `.xz`, and either bare `.exe` or
`.exe.xz` for Windows.
