""""""""""""""""""""""""""""""""
"    Rust-specific defaults    "
" from webinstall.dev/vim-rust "
""""""""""""""""""""""""""""""""

" run rustfmt on save
let g:rustfmt_autosave = 1

" run cargo check for linting
let g:ale_rust_cargo_use_check = 1
let g:ale_rust_cargo_check_tests = 1
let g:ale_rust_cargo_check_examples = 1
