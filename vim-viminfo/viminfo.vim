" Tell vim to remember certain things when we exit
"  '100  :  marks will be remembered for up to 100 previously edited files
"  "20000:  will save up to 20,000 lines for each register
"  :200  :  up to 200 lines of command-line history will be remembered
"  %     :  saves and restores the buffer list
"  n...  :  where to save the viminfo files
set viminfo='100,\"20000,:200,%,n~/.viminfo
