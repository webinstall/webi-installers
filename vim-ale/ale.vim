" turn on the syntax checker
syntax on

" don't check immediately on open (or quit)
let g:ale_lint_on_enter = 0
" check on save
let g:ale_lint_on_save = 1

" these emojis go in the sidebar for errors and warnings
" other considerations: '💥' '☠' '●' '.'
let g:ale_sign_error = '☢️'
let g:ale_sign_warning = '⚡'

" show error count
function! LinterStatus() abort
    let l:counts = ale#statusline#Count(bufnr(''))
    let l:all_errors = l:counts.error + l:counts.style_error
    let l:all_non_errors = l:counts.total - l:all_errors
    return l:counts.total == 0 ? 'OK' : printf(
        \   '%d⨉ %d⚠ ',
        \   all_non_errors,
        \   all_errors
        \)
endfunction
set statusline+=%=
set statusline+=\ %{LinterStatus()}

" how to show error message
let g:ale_echo_msg_error_str = 'E'
let g:ale_echo_msg_warning_str = 'W'
let g:ale_echo_msg_format = '[%linter%] %s [%severity%]'
