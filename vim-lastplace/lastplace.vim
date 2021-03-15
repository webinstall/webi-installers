" For more configuration details read the source at
" https://github.com/farmergreg/vim-lastplace/blob/master/plugin/vim-lastplace.vim

" configure what file types to ignore
let g:lastplace_ignore = "gitcommit,gitrebase,svn,hgcommit"

" configure buffer types to ignore
let g:lastplace_ignore_buftype = "quickfix,nofile,help"

" automatically open folds when jumping to the last edit position
let g:lastplace_open_folds = 0
