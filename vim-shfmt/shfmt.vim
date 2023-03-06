"""""""""""""""""""""""""""""""""
"    shfmt-specific defaults    "
" from webinstall.dev/vim-shfmt "
"""""""""""""""""""""""""""""""""

" Change Log
"
" 2023-03-06:
"   - remove explicit file extension detection
"     (this now works as expected by default)


" 4 indents, Space between redirects, Indented case statements, Simplified
let g:shfmt_extra_args = '-i 4 -sr -ci -s'
let g:shfmt_fmt_on_save = 1
