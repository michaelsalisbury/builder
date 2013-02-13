#!/bin/builder.sh
skip=( false false false false )
step=3
prefix="setup"
source=http://10.173.119.78/scripts/system-setup/$scriptName

function setup_skel_default(){
	desc Write /etc/vim/vimrc.local
	cat << END-OF-VIMRC > /etc/vim/vimrc.local
" Do not wrap text
:set nowrap!
" Toggle word wrap by pressing F2
:map <F2> :set nowrap! <CR>

if has("autocmd")
  " When editing a file, always jump to the last cursor position
  autocmd BufReadPost *
  \ if line("'\"") > 0 && line ("'\"") <= line("$") |
  \   exe "normal! g'\"" |
  \ endif
  " don't write swapfile on most commonly used directories for NFS mounts or USB sticks
  autocmd BufNewFile,BufReadPre /media/*,/mnt/* set directory=~/tmp,/var/tmp,/tmp
endif
END-OF-VIMRC
}
