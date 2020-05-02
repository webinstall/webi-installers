# title: Ripgrep
# homepage: https://github.com/BurntSushi/ripgrep
# tagline: a modern drop-in grep replacement
# alias: rg
# description: |
#   'rg' is a drop-in replacement for 'grep', that respects '.gitignore' and '.ignore', has all of the sensible default options you want (colors, numbers, etc) turned on by default, is written in Rust, and simply outperforms grep in every imaginable way. R.I.P. grep.
# examples: |
#
#   ```bash
#   rg <search-term> # searches recursively, ignoing .git, node_modules, etc
#   ```
#
#   ```bash
#   rg 'function doStuff'
#   ```
#
#   ```bash
#   rg 'doStuff\(.*\)'
#   ```

set -e
set -u
set -o pipefail

# Use the script's first argument or the supplied WEBI_VERSION or ''
WEBI_VERSION=${1:-${WEBI_VERSION:-}}

# Set a temporary directory, if not already set
WEBI_TMP=${WEBI_TMP:-"$(mktemp -d -t webinstall-ripgrep.XXXXXXXX)"}

###################
#  Get WEBI vars  #
###################

# The WEBI bootstrap will define these
# but each script should be testable in its own right

if [ -z "${WEBI_PKG_URL}" ]; then
  release_tab="${WEBI_HOST}/api/releases/ripgrep@${WEBI_VERSION:-}.csv?os=$(uname -s)&arch=$(uname -m)&ext=tar&limit=1"
  WEBI_CSV=$(curl -fsSL "$release_tab" -H "User-Agent: $(uname -a)")
  WEBI_CHANNEL=$(echo $WEBI_TAB | cut -d ',' -f 3)
  if [ "error" == "$WEBI_CHANNEL" ]; then
     echo "could not find release for ripgrep v${WEBI_VERSION}"
     exit 1
  fi
  WEBI_VERSION=$(echo $WEBI_TAB | cut -d ',' -f 1)
  WEBI_PKG_URL=$(echo $WEBI_TAB | cut -d ',' -f 9)
  WEBI_PKG_FILE="$WEBI_TMP/$(echo $WEBI_PKG_URL | sed s:.*/::)"
fi

###################
# Install ripgrep #
###################

new_rg="${HOME}/.local/bin/rg"

# Test for existing version 
set +e
cur_rg="$(command -v rg)"
set -e
if [ -n "$cur_rg" ]; then
  cur_ver=$(rg --version | head -n 1 | cut -d ' ' -f 2)
  if [ "$cur_ver" == "$WEBI_VERSION" ]; then
    echo "ripgrep v$WEBI_VERSION already installed at $cur_rg"
    exit 0
  elif [ "$cur_rg" != "$new_rg" ]; then
    echo "WARN: possible conflict with ripgrep v$WEBI_VERSION at $cur_rg"
  fi
fi

# TODO move download to the webi bootstrap
echo Downloading ripgrep v"${WEBI_VERSION}" from "${WEBI_PKG_URL}"
curl -fsSL "${WEBI_PKG_URL}" -o "${WEBI_PKG_FILE}"
pushd "${WEBI_TMP}" 2>&1 >/dev/null
        echo Installing ripgrep v${WEBI_VERSION} as "$new_rg" 
	tar xf "${WEBI_PKG_FILE}"
        rm "${WEBI_PKG_FILE}"
        mv ./ripgrep-*/rg "${HOME}/.local/bin/"
popd 2>&1 >/dev/null

###################
#   Update PATH   #
###################

# TODO get better output from pathman / output the path to add as return to webi bootstrap
pathman add "$HOME/.local/bin/"

echo "Installed 'rg'"
echo ""
