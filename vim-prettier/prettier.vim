""""""""""""""""""""""""""""""""""""
"    Prettier-specific defaults    "
" from webinstall.dev/vim-prettier "
""""""""""""""""""""""""""""""""""""

" Change Log
"
" 2023-03-06:
"   - add back explicit file extension detection
"     (json and markdown at least are not working by default)
" 2023-03-05:
"   - run when filetype matches javascript
"     (e.g. shebang is #!/usr/bin/env node)
"   - remove explicit file extension detection
"     (this now works as expected by default)

augroup RunPrettierByFiletype

    autocmd BufWritePre .babelrc,.eslintrc,.jshintrc,*.js,*.jsx,*.mjs,*.ts,*.tsx,*.css,*.less,*.scss,*.json,*.graphql,*.md,*.vue,*.yaml,*.html PrettierAsync

    autocmd FileType javascript,typescript autocmd BufWritePre <buffer> PrettierAsync

augroup END
