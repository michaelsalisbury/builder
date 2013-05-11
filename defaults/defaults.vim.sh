#!/bin/builder.sh

# IMPORTANT: Includes must be placed before global variables like "skip" & "step"
#while read import; do
#        source <(sed '1,/^function/{/^function/p;d}' "${import}")
#done < <(ls -1              "${scriptPath}"/functions.*.sh 2> /dev/null
#	 ls -1 "${scriptPath}"/../functions/functions.*.sh 2> /dev/null)

# GLOBAL VARIABLES
skip=( false false false false )
step=3
prefix="setup"
source=http://10.173.119.78/scripts/system-setup/$scriptName

function setup_Create_Systemwide_Defaults(){
	desc Write /etc/vim/vimrc.local
	touch     /etc/skel/.viminfo
	chmod 600 /etc/skel/.viminfo
	cat << END-OF-VIMRC > /etc/vim/vimrc.local
" Change comment highlighting from dark blue to dark green
highlight Comment ctermfg=DarkGreen

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
