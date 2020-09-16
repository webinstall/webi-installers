""""""""""""""""""""""""""""""
"  Golang-specific defaults  "
" from webinstall.dev/vim-go "
""""""""""""""""""""""""""""""

" tell syntastic that go, golint, and errcheck are installed
let g:syntastic_go_checkers = ['go', 'golint', 'errcheck']

" tell vim-go that goimports is installed
let g:go_fmt_command = "goreturns"

" tell vim-go to highlight
let g:go_highlight_functions = 1
let g:go_highlight_methods = 1
let g:go_highlight_structs = 1
let g:go_highlight_operators = 1
let g:go_highlight_build_constraints = 1
