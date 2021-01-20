#!/bin/bash

{
    curl -L https://github.com/pyenv/pyenv-installer/raw/master/bin/pyenv-installer | bash
    pathman add ~/.pyenv
    pathman add ~/.pyenv/shim    
}
