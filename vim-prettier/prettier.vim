""""""""""""""""""""""""""""""""""""
"    Prettier-specific defaults    "
" from webinstall.dev/vim-prettier "
""""""""""""""""""""""""""""""""""""

" Change Log
"
" 2023-03-06:
"   - run when filetype matches javascript
"     (e.g. shebang is #!/usr/bin/env node)
"   - remove explicit file extension detection
"     (this now works as expected by default)

augroup RunPrettierByFiletype
    " run Prettier not just by file extension, but also if the filetype is detected as javascript or typescript
    autocmd FileType javascript,typescript autocmd BufWritePre <buffer> PrettierAsync
augroup END
