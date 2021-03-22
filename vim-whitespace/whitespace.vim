" The default tab width is 8 spaces, which is redonkulous.
" We'll set it to 4 instead, which is reasonable.
" (feel free to change to 2, but 3 is right out).
"
" Also, I'm not actually sure what the individual options do,
" but it's something like 'always use spaces' and
" 'use the same width when typing, tabbing, deleting, moving, etc'
set tabstop=4
set shiftwidth=4
set smarttab
set expandtab
set softtabstop=4

" remove trailing whitespace on save
autocmd BufWritePre * :%s/\s\+$//e
