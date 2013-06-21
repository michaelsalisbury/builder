#!/bin/builder.sh
skip=( false false false false )
step=3
prefix="setup"
source="https://raw.github.com/michaelsalisbury/builder/master/defaults/${scriptName}"
#source=http://10.173.119.78/scripts/system-setup/$scriptName

#function includes(){
#	functions.*.sh
#	../functions/functions.*.sh
#}

# GLOBAL VARIABLES
#function global_variables(){
#	echo
#}

function setup_Create_Systemwide_Defaults(){
	desc Write /etc/vim/vimrc.local
	touch     /etc/skel/.viminfo
	chmod 600 /etc/skel/.viminfo
	cat <<-END-OF-VIMRC > /etc/vim/vimrc.local
		" Change comment highlighting from dark blue to dark green
		highlight Comment ctermfg=DarkGreen
		" enable highlight searching
		:set hlsearch
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
