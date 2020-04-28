#!/bin/bash

# title: vim-sensible
# homepage: https://github.com/tpope/vim-sensible
# tagline: sensible defaults for vim
# description: |
#   Think of sensible.vim as one step above 'nocompatible' mode: a universal set of defaults that (hopefully) everyone can agree on.
# examples: |
#   N/A

mkdir -p $HOME/.vim/pack/plugins/start
git clone --depth=1 https://tpope.io/vim/sensible.git $HOME/.vim/pack/plugins/start/sensible
