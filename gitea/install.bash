# title: Gitea
# homepage: https://github.com/go-gitea/gitea
# tagline: Git with a cup of tea, painless self-hosted git service.
# description: |
# The goal of this project is to make the easiest, fastest, and most painless
# way of setting up a self-hosted Git service.

set -e
set -u

#################
# Install gitea #
#################

new_gitea="${HOME}/.local/bin/gitea"

# Test for existing version
set +e
cur_gitea="$(command -v gitea)"
set -e
if [ -n "$cur_gitea" ]; then
  cur_ver=$(gitea version | head -n 1 | cut -d ' ' -f 2)
  if [ "$cur_ver" == "$WEBI_VERSION" ]; then
    echo "gitea v$WEBI_VERSION already installed at $cur_gitea"
    exit 0
  elif [ "$cur_gitea" != "$new_gitea" ]; then
    echo "WARN: possible conflict with gitea v$WEBI_VERSION at $cur_gitea"
  fi
fi

# Note: this file is `source`d by the true installer and hence will have the webi functions

# because we created releases.js we can use webi_download()
# downloads gitea to ~/Downloads
webi_download

# because this is tar or zip, we can webi_extract()
# extracts to the WEBI_TMP directory, raw (no --strip-prefix)
webi_extract

pushd "$WEBI_TMP" 2>&1 >/dev/null
        echo Installing gitea v${WEBI_VERSION} as "$new_gitea"
        mv ./gitea "$HOME/.local/bin/"
popd 2>&1 >/dev/null

###################
#   Update PATH   #
###################

# TODO get better output from pathman / output the path to add as return to webi bootstrap
webi_path_add "$HOME/.local/bin"

echo "Installed 'gitea'"
echo ""
