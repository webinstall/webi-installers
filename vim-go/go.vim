""""""""""""""""""""""""""""""
"  Golang-specific defaults  "
" from webinstall.dev/vim-go "
""""""""""""""""""""""""""""""

" tell syntastic that go, golint, and errcheck are installed
let g:syntastic_go_checkers = ['go', 'golint', 'errcheck']

" tell vim-go that goimports is installed
let g:go_fmt_command = "goimports"

" Show type info as you type
let g:go_auto_type_info = 1

" golangci-lint on save
let g:go_metalinter_autosave=1

" tell vim-go to highlight
let g:go_highlight_functions = 1
let g:go_highlight_methods = 1
let g:go_highlight_structs = 1
let g:go_highlight_operators = 1
let g:go_highlight_build_constraints = 1

" and lots of extra highligting
let g:go_highlight_extra_types = 1
let g:go_highlight_operators = 1
let g:go_highlight_function_calls = 1
let g:go_highlight_fields = 1
let g:go_highlight_build_constraints = 1
let g:go_highlight_generate_tags = 1
let g:go_highlight_format_strings = 1
let g:go_highlight_variable_declarations = 1
let g:go_highlight_variable_assignments = 1

" and error highlighting
let g:go_highlight_array_whitespace_error = 1
let g:go_highlight_chan_whitespace_error = 1
let g:go_highlight_space_tab_error = 1
let g:go_highlight_trailing_whitespace_error = 1

" highlighting that doesn't seem to help
" let g:go_highlight_string_spellcheck = 1
" let g:go_highlight_function_parameters = 1
" let g:go_highlight_types = 1
