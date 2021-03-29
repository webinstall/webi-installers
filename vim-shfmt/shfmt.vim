" 4 indents, Space between redirects, Indented case statements, Simplified
let g:shfmt_extra_args = '-i 4 -sr -ci -s'
let g:shfmt_fmt_on_save = 1

augroup LocalShell
    autocmd!

    autocmd BufWritePre *.sh,*.bash Shfmt
augroup END
