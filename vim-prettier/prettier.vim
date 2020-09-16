""""""""""""""""""""""""""""""""""""
"    Prettier-specific defaults    "
" from webinstall.dev/vim-prettier "
""""""""""""""""""""""""""""""""""""

" format as-you-type is quite annoying, so we turn it off
let g:prettier#autoformat = 0

" list all of the extensions for which prettier should run
autocmd BufWritePre .babelrc,.eslintrc,.jshintrc,*.js,*.jsx,*.mjs,*.ts,*.tsx,*.css,*.less,*.scss,*.json,*.graphql,*.md,*.vue,*.yaml,*.html PrettierAsync
