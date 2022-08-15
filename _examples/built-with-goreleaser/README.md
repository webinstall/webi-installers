# Building with GoReleaser?

And publishing with Git Releases?

If so, you can copy one of the given examples, do a little find-and-replace, and
viola, you've got your Webi installer!

Each example has four files that need to be modified, just slightly:

- install.sh
- install.ps1
- releases.js
- README.md

## Releases with .tag.gz and .zip

See [./keypairs/](/keypairs/) as an example.

```sh
rsync -av ./keypairs/ ./my-project/
```

Keypairs is packaged for Mac and Linux as `.tar.gz`, and as `.zip` for Windows.

## Bare Releases (no compression)

See [./arc/](/arc/) as an example.

```sh
rsync -av ./arc/ ./my-project/
```

Arc is an unarchive tool and, therefore, makes sense that it is released
unpackaged, without compression.

Note: `arc` is the installed command name, while `archiver` is the package name.
When you find-and-replace, you'll probably replace both with your command name,
because your command and package probably have the same name.
