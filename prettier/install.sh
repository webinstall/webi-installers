# title: Prettier
# homepage: https://prettier.io/
# tagline: |
#   Prettier is an opinionated code formatter.
# description: |
#   The core value of Prettier is not in what it gives, but in what it takes away: countless hours of bikeshedding over code style choices. Also, it makes git merges much nicer.
# examples: |
#   Prettify all web files in a project, recursively:
#   
#   ```bash
#   prettier --write '**/*{.md,.js,.html,.css}' --ignore ./dist
#   ```
#   
#   Tell Prettier which files to ignore every time
#   
#   ```bash
#   echo "./dist" >> .prettierignore
#   ```
#   
#   Tell Prettier which settings to use - do NOT use `package.json` when it's not necessary!
#   
#   **`.prettierrc`**:
#   
#   ```bash
#   {
#     "trailingComma": "none",
#     "tabWidth": 2,
#     "singleQuote": true,
#     "proseWrap": "always"
#   }
#   ```
#

if [ -z "$(npm --version 2>/dev/null)" ]; then
    webi node
    export PATH="$HOME/.local/opt/node/bin:$PATH"
fi
npm install -g prettier@latest
